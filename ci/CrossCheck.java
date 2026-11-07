// CrossCheck.java -- independent cross-check of the JavaSingleSeedCracker results.
//
// NOT part of the reference-vector generation. This brute-forces the whole 32-bit
// seed space with a different (straightforward, single-code-path) matcher and
// verifies the count and the extreme matching seeds recorded in
// vectors/reference_vectors.json by ReferenceVectors.java (which uses
// JavaSingleSeedCracker.firstInput + reflection).
//
// Compile (from the repository root):
//   javac -d ci/build ../enchcracker-src/src/enchcracker/SimpleRandom.java ci/CrossCheck.java
//
// Run (from ci/):
//   java -Xmx1G -cp build CrossCheck vectors/reference_vectors.json
//
// Exit code 0 when every observation matches, 1 otherwise.

import enchcracker.SimpleRandom;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

public class CrossCheck {

    static final int THREADS = Math.max(1, Runtime.getRuntime().availableProcessors() - 1);

    /** Three consecutive table levels, exactly like Enchantments.calcEnchantmentTableLevel for slots 0..2. */
    static boolean matches(int seed, int bookshelves, int slot1, int slot2, int slot3, SimpleRandom rng) {
        rng.setSeed(seed);
        int level1 = rng.nextInt(8) + 1 + (bookshelves >> 1) + rng.nextInt(bookshelves + 1);
        if (Math.max(level1 / 3, 1) != slot1) return false;
        int level2 = rng.nextInt(8) + 1 + (bookshelves >> 1) + rng.nextInt(bookshelves + 1);
        if (level2 * 2 / 3 + 1 != slot2) return false;
        int level3 = rng.nextInt(8) + 1 + (bookshelves >> 1) + rng.nextInt(bookshelves + 1);
        if (Math.max(level3, bookshelves * 2) != slot3) return false;
        return true;
    }

    public static void main(String[] args) throws Exception {
        String path = args.length > 0 ? args[0] : "vectors/reference_vectors.json";
        String json = new String(Files.readAllBytes(Paths.get(path)), StandardCharsets.UTF_8);

        // Lightweight extraction of the seedCracker entries (the file is machine generated).
        int idx = json.indexOf("\"seedCracker\"");
        if (idx < 0) throw new IllegalStateException("no seedCracker section in " + path);
        int arrayStart = json.indexOf('[', idx);
        int arrayEnd = json.indexOf("\"seedCracker\"", idx + 1); // not used; parse entries by "bookshelves"
        if (arrayEnd < 0) arrayEnd = json.length();
        String section = json.substring(arrayStart, Math.min(arrayEnd, json.length()));

        List<int[]> observations = new ArrayList<>();
        List<Long> expectedCounts = new ArrayList<>();
        List<String[]> expectedFirst = new ArrayList<>();
        List<String[]> expectedLast = new ArrayList<>();
        int pos = 0;
        while (true) {
            int b = section.indexOf("\"bookshelves\"", pos);
            if (b < 0) break;
            int c = section.indexOf("\"count\"", b);
            int f = section.indexOf("\"first\"", c);
            int l = section.indexOf("\"last\"", f);
            int obsEnd = section.indexOf('}', l);
            if (c < 0 || f < 0 || l < 0 || obsEnd < 0) break;
            int bookshelves = intAfter(section, b);
            int slot1 = intAfter(section, section.indexOf("\"slot1\"", b));
            int slot2 = intAfter(section, section.indexOf("\"slot2\"", b));
            int slot3 = intAfter(section, section.indexOf("\"slot3\"", b));
            long count = Long.parseLong(numberAfter(section, c));
            String[] first = stringsBetween(section, f, section.indexOf(']', f));
            String[] last = stringsBetween(section, l, section.indexOf(']', l));
            observations.add(new int[] {bookshelves, slot1, slot2, slot3});
            expectedCounts.add(count);
            expectedFirst.add(first);
            expectedLast.add(last);
            pos = obsEnd + 1;
        }
        if (observations.isEmpty()) throw new IllegalStateException("no observations parsed");

        int failures = 0;
        for (int i = 0; i < observations.size(); i++) {
            int[] obs = observations.get(i);
            long t0 = System.nanoTime();
            long[] result = scan(obs[0], obs[1], obs[2], obs[3]);
            long count = result[0];
            int[] smallest = new int[5];
            int[] largest = new int[5];
            for (int k = 0; k < 5; k++) {
                smallest[k] = (int) result[1 + k];
                largest[k] = (int) result[6 + k];
            }
            String[] expectedFirstForObs = expectedFirst.get(i);
            String[] expectedLastForObs = expectedLast.get(i);
            int expectedExtremes = (int) Math.min(5, count);
            boolean ok = count == expectedCounts.get(i)
                    && expectedFirstForObs.length == expectedExtremes
                    && expectedLastForObs.length == expectedExtremes;
            String[] first = new String[expectedExtremes];
            String[] last = new String[expectedExtremes];
            for (int k = 0; k < expectedExtremes; k++) {
                first[k] = String.format("0x%08X", smallest[k] & 0xFFFF_FFFFL);
                last[k] = String.format("0x%08X", largest[k] & 0xFFFF_FFFFL);
                if (!first[k].equals(expectedFirstForObs[k])) ok = false;
                if (!last[k].equals(expectedLastForObs[k])) ok = false;
            }
            System.err.printf("obs b=%d s1=%d s2=%d s3=%d count=%d expected=%d first=%s last=%s (%.1fs) %s%n",
                    obs[0], obs[1], obs[2], obs[3], count, expectedCounts.get(i),
                    Arrays.toString(first), Arrays.toString(last),
                    (System.nanoTime() - t0) / 1e9, ok ? "OK" : "MISMATCH");
            if (!ok) failures++;
        }
        System.out.println(failures == 0
                ? "CrossCheck PASS: all " + observations.size() + " observations match ReferenceVectors"
                : "CrossCheck FAIL: " + failures + " observation(s) differ");
        System.exit(failures == 0 ? 0 : 1);
    }

    /**
     * Scans the whole 2^32 seed space and returns
     * {count, smallest0..smallest4, largest0..largest4} (ascending signed order).
     */
    static long[] scan(int bookshelves, int slot1, int slot2, int slot3) {
        final long total = 1L << 32;
        final long chunk = total / THREADS;
        final AtomicLong count = new AtomicLong();
        final AtomicReference<int[]> small = new AtomicReference<>(new int[5]);
        final AtomicReference<int[]> large = new AtomicReference<>(new int[5]);

        Thread[] threads = new Thread[THREADS];
        for (int ti = 0; ti < THREADS; ti++) {
            final int threadIndex = ti;
            final long start = threadIndex * chunk;
            final long end = threadIndex == THREADS - 1 ? total : start + chunk;
            threads[ti] = new Thread(() -> {
                SimpleRandom rng = new SimpleRandom();
                int[] mySmall = new int[5];
                int[] myLarge = new int[5];
                Arrays.fill(mySmall, Integer.MAX_VALUE);
                Arrays.fill(myLarge, Integer.MIN_VALUE);
                long myCount = 0;
                for (long u = start; u < end; u++) {
                    int seed = (int) u; // two's complement bit pattern
                    if (!matches(seed, bookshelves, slot1, slot2, slot3, rng)) continue;
                    myCount++;
                    if (seed < mySmall[4]) {
                        mySmall[4] = seed;
                        Arrays.sort(mySmall);
                    }
                    if (seed > myLarge[0]) {
                        myLarge[0] = seed;
                        Arrays.sort(myLarge);
                    }
                }
                count.addAndGet(myCount);
                synchronized (small) {
                    int[] merged = new int[5];
                    int[] current = small.get();
                    int a = 0, b = 0;
                    for (int k = 0; k < 5; k++) {
                        merged[k] = a < 5 && (b >= 5 || current[a] <= mySmall[b]) ? current[a++] : mySmall[b++];
                    }
                    small.set(merged);
                }
                synchronized (large) {
                    int[] merged = new int[5];
                    int[] current = large.get();
                    int a = 4, b = 4;
                    for (int k = 4; k >= 0; k--) {
                        merged[k] = a >= 0 && (b < 0 || current[a] >= myLarge[b]) ? current[a--] : myLarge[b--];
                    }
                    large.set(merged);
                }
            });
            threads[ti].start();
        }
        for (Thread t : threads) {
            try {
                t.join();
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
        long[] out = new long[11];
        out[0] = count.get();
        int[] s = small.get();
        int[] l = large.get();
        for (int k = 0; k < 5; k++) {
            out[1 + k] = s[k];
            out[6 + k] = l[k];
        }
        return out;
    }

    // --- tiny JSON scraping helpers (machine-generated file) ---

    static int intAfter(String text, int from) {
        int colon = text.indexOf(':', from);
        int end = colon + 1;
        while (end < text.length()) {
            char ch = text.charAt(end);
            if ((ch >= '0' && ch <= '9') || ch == '-') break;
            end++;
        }
        int start = end;
        while (end < text.length() && ((text.charAt(end) >= '0' && text.charAt(end) <= '9') || text.charAt(end) == '-')) {
            end++;
        }
        return Integer.parseInt(text.substring(start, end));
    }

    static String numberAfter(String text, int from) {
        int colon = text.indexOf(':', from);
        int start = colon + 1;
        while (start < text.length() && (text.charAt(start) == ' ' || text.charAt(start) == '\n')) start++;
        int end = start;
        while (end < text.length() && (text.charAt(end) >= '0' && text.charAt(end) <= '9')) end++;
        return text.substring(start, end);
    }

    static String[] stringsBetween(String text, int from, int end) {
        List<String> out = new ArrayList<>();
        int bracket = text.indexOf('[', from);
        int stop = end < 0 ? text.indexOf(']', bracket) : end;
        int i = bracket + 1;
        while (i < stop) {
            int q1 = text.indexOf('"', i);
            if (q1 < 0 || q1 >= stop) break;
            int q2 = text.indexOf('"', q1 + 1);
            if (q2 < 0 || q2 > stop) break;
            out.add(text.substring(q1 + 1, q2));
            i = q2 + 1;
        }
        return out.toArray(new String[0]);
    }
}

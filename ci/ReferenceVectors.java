// ReferenceVectors.java -- generates deterministic reference vectors for the
// iOS (Swift) port of EnchantmentCracker by calling the ORIGINAL Java code.
//
// This file has NO package. Compile it together with the original Java sources:
//
//   javac -d ci/build \
//       ../enchcracker-src/src/enchcracker/{Versions,Materials,Items,Enchantments,SimpleRandom,IntArray,Log}.java \
//       ../enchcracker-src/src/enchcracker/cracker/{AbstractSingleSeedCracker,JavaSingleSeedCracker}.java \
//       ci/ReferenceVectors.java
//
// Run from the ci/ directory (the original Log class writes enchcracker.log to
// the current working directory):
//
//   cd ci
//   java -Xmx3G -cp build ReferenceVectors vectors/reference_vectors.json
//
// Optional flags:
//   --skip-cracker   skip the (slow) 2^32 seed-cracker section
//   --skip-calc      skip the enchantment-calculator search section
//
// The resulting JSON is written with a deterministic key/array order.

import enchcracker.*;
import enchcracker.cracker.*;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;

public class ReferenceVectors {

    // =====================================================================
    // Tiny deterministic JSON tree (no external dependencies)
    // =====================================================================

    interface J {
    }

    static final class JStr implements J {
        final String v;

        JStr(String v) {
            this.v = v;
        }
    }

    static final class JNum implements J {
        final long v;

        JNum(long v) {
            this.v = v;
        }
    }

    static final class JBool implements J {
        final boolean v;

        JBool(boolean v) {
            this.v = v;
        }
    }

    static final class JNull implements J {
    }

    static final class JArr implements J {
        final List<J> l = new ArrayList<>();

        JArr add(J x) {
            l.add(x == null ? NULL : x);
            return this;
        }

        int size() {
            return l.size();
        }
    }

    static final class JObj implements J {
        final LinkedHashMap<String, J> m = new LinkedHashMap<>();

        JObj put(String k, J v) {
            m.put(k, v == null ? NULL : v);
            return this;
        }

        JObj put(String k, String v) {
            return put(k, s(v));
        }

        JObj put(String k, long v) {
            return put(k, n(v));
        }

        JObj put(String k, boolean v) {
            return put(k, b(v));
        }
    }

    static final J NULL = new JNull();

    static JStr s(String v) {
        return new JStr(v);
    }

    static JNum n(long v) {
        return new JNum(v);
    }

    static JBool b(boolean v) {
        return new JBool(v);
    }

    static void dump(StringBuilder sb, J j, int indent) {
        if (j instanceof JStr) {
            sb.append(quote(((JStr) j).v));
        } else if (j instanceof JNum) {
            sb.append(((JNum) j).v);
        } else if (j instanceof JBool) {
            sb.append(((JBool) j).v);
        } else if (j instanceof JNull) {
            sb.append("null");
        } else if (j instanceof JArr) {
            List<J> l = ((JArr) j).l;
            if (l.isEmpty()) {
                sb.append("[]");
                return;
            }
            sb.append("[\n");
            for (int i = 0; i < l.size(); i++) {
                pad(sb, indent + 1);
                dump(sb, l.get(i), indent + 1);
                if (i != l.size() - 1) {
                    sb.append(',');
                }
                sb.append('\n');
            }
            pad(sb, indent);
            sb.append(']');
        } else if (j instanceof JObj) {
            LinkedHashMap<String, J> m = ((JObj) j).m;
            if (m.isEmpty()) {
                sb.append("{}");
                return;
            }
            sb.append("{\n");
            int i = 0;
            for (Map.Entry<String, J> e : m.entrySet()) {
                pad(sb, indent + 1);
                sb.append(quote(e.getKey())).append(": ");
                dump(sb, e.getValue(), indent + 1);
                if (++i != m.size()) {
                    sb.append(',');
                }
                sb.append('\n');
            }
            pad(sb, indent);
            sb.append('}');
        } else {
            throw new IllegalStateException("bad JSON node");
        }
    }

    static void pad(StringBuilder sb, int indent) {
        for (int i = 0; i < indent; i++) {
            sb.append("  ");
        }
    }

    static String quote(String s) {
        StringBuilder sb = new StringBuilder(s.length() + 2);
        sb.append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"':
                    sb.append("\\\"");
                    break;
                case '\\':
                    sb.append("\\\\");
                    break;
                case '\n':
                    sb.append("\\n");
                    break;
                case '\r':
                    sb.append("\\r");
                    break;
                case '\t':
                    sb.append("\\t");
                    break;
                default:
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        sb.append('"');
        return sb.toString();
    }

    static void writeOut(JObj root, Path out) throws Exception {
        StringBuilder sb = new StringBuilder(1 << 20);
        dump(sb, root, 0);
        sb.append('\n');
        Files.write(out, sb.toString().getBytes(StandardCharsets.UTF_8));
        System.err.println("[write] " + out.toAbsolutePath() + " (" + sb.length() + " chars)");
    }

    // =====================================================================
    // Helpers mirroring the Java semantics needed below
    // =====================================================================

    static final long MULT = 0x5DEECE66DL;
    static final long ADD = 0xBL;
    static final long MASK48 = 0x0000_FFFF_FFFF_FFFFL;
    static final long MASK_HIGH32 = 0x0000_FFFF_FFFF_0000L;

    static long lcg(long seed) {
        return (seed * MULT + ADD) & MASK48;
    }

    static String hex8(int v) {
        return String.format("0x%08X", v & 0xFFFF_FFFFL);
    }

    static String hex12(long v) {
        return String.format("0x%012X", v & MASK48);
    }

    /** Items constants, discovered through reflection on public static String fields. */
    static List<String> itemConstants() {
        List<String> out = new ArrayList<>();
        for (Field f : Items.class.getDeclaredFields()) {
            int mod = f.getModifiers();
            if (!Modifier.isStatic(mod) || !Modifier.isPublic(mod)) {
                continue;
            }
            if (f.getType() != String.class) {
                continue;
            }
            try {
                Object v = f.get(null);
                if (v instanceof String) {
                    out.add((String) v);
                }
            } catch (ReflectiveOperationException e) {
                throw new RuntimeException(e);
            }
        }
        // Deterministic order independent of class-file field order.
        java.util.Collections.sort(out);
        return out;
    }

    static List<String> tableEnchantments() {
        return new ArrayList<>(Enchantments.TABLE_ENCHANTMENTS);
    }

    static JArr strArr(List<String> list) {
        JArr a = new JArr();
        for (String x : list) {
            a.add(s(x));
        }
        return a;
    }

    static JArr enchantList(List<Enchantments.EnchantmentInstance> list) {
        JArr a = new JArr();
        for (Enchantments.EnchantmentInstance inst : list) {
            a.add(new JObj().put("id", inst.enchantment).put("level", inst.level));
        }
        return a;
    }

    // =====================================================================
    // Sections
    // =====================================================================

    static JObj metadata() {
        JObj m = new JObj();
        m.put("generatedBy", "EnchantmentCracker-iOS/ci/ReferenceVectors.java");
        m.put("sourceRepo", "enchcracker-src/src (original Java implementation)");
        m.put("javaVersion", System.getProperty("java.version"));
        m.put("note", "All values were produced by calling the ORIGINAL Java implementation directly; "
                + "the Swift port must reproduce every number exactly.");
        m.put("seedFormat", "xpSeed: 0x + 8 hex digits; playerSeed: 0x + 12 hex digits");
        m.put("tableEnchantments", strArr(tableEnchantments()));
        m.put("itemConstants", strArr(itemConstants()));
        JArr versions = new JArr();
        for (Versions v : Versions.values()) {
            versions.add(s(v.name()));
        }
        m.put("versions", versions);
        return m;
    }

    static JArr levelsToXPVectors() {
        JArr a = new JArr();
        List<Integer> starts = new ArrayList<>();
        for (int i = 1; i <= 40; i++) {
            starts.add(i);
        }
        starts.add(100);
        int[] numbers = {0, 1, 2, 5, 30};
        for (int start : starts) {
            for (int numLevels : numbers) {
                a.add(new JObj()
                        .put("startLevel", start)
                        .put("numLevels", numLevels)
                        .put("result", Enchantments.levelsToXP(start, numLevels)));
            }
        }
        return a;
    }

    static JArr getMaxLevelVectors() {
        JArr a = new JArr();
        for (String ench : tableEnchantments()) {
            a.add(new JObj()
                    .put("enchantment", ench)
                    .put("result", Enchantments.getMaxLevel(ench)));
        }
        return a;
    }

    static JArr minMaxEnchantabilityVectors(boolean max) {
        JArr a = new JArr();
        for (String ench : tableEnchantments()) {
            int levelCount = Enchantments.getMaxLevel(ench);
            for (int level = 1; level <= levelCount; level++) {
                int result = max
                        ? Enchantments.getMaxEnchantability(ench, level)
                        : Enchantments.getMinEnchantability(ench, level);
                a.add(new JObj()
                        .put("enchantment", ench)
                        .put("level", level)
                        .put("result", result));
            }
        }
        return a;
    }

    static JArr getWeightVectors() {
        JArr a = new JArr();
        for (String ench : tableEnchantments()) {
            for (Versions ver : Versions.values()) {
                a.add(new JObj()
                        .put("enchantment", ench)
                        .put("version", ver.name())
                        .put("result", Enchantments.getWeight(ench, ver)));
            }
        }
        return a;
    }

    static JArr canApplyVectors() {
        JArr a = new JArr();
        List<String> items = itemConstants();
        for (String ench : tableEnchantments()) {
            for (String item : items) {
                for (boolean primary : new boolean[] {false, true}) {
                    a.add(new JObj()
                            .put("enchantment", ench)
                            .put("item", item)
                            .put("primary", primary)
                            .put("result", Enchantments.canApply(ench, item, primary)));
                }
            }
        }
        return a;
    }

    static JArr getEnchantabilityVectors() {
        JArr a = new JArr();
        for (String item : itemConstants()) {
            a.add(new JObj()
                    .put("item", item)
                    .put("result", Items.getEnchantability(item)));
        }
        return a;
    }

    static JArr getHighestAllowedVectors() {
        JArr a = new JArr();
        int[] levels = {1, 5, 10, 15, 20, 25, 30, 40, 50};
        String[] items = {"diamond_sword", "iron_chestplate", "bow", "book", "fishing_rod",
                "leather_boots", "netherite_sword"};
        Versions[] versions = {Versions.V1_8, Versions.V1_14, Versions.V1_16, Versions.V1_21_11};
        for (int level : levels) {
            for (String item : items) {
                for (Versions ver : versions) {
                    List<Enchantments.EnchantmentInstance> list =
                            Enchantments.getHighestAllowedEnchantments(level, item, ver);
                    a.add(new JObj()
                            .put("level", level)
                            .put("item", item)
                            .put("version", ver.name())
                            .put("result", enchantList(list)));
                }
            }
        }
        return a;
    }

    static JArr getMaxLevelInTableVectors() {
        JArr a = new JArr();
        String[] items = {"diamond_sword", "iron_chestplate", "bow", "book", "trident", "mace",
                "wooden_hoe"};
        for (String ench : tableEnchantments()) {
            for (String item : items) {
                a.add(new JObj()
                        .put("enchantment", ench)
                        .put("item", item)
                        .put("result", Enchantments.getMaxLevelInTable(ench, item)));
            }
        }
        return a;
    }

    static JArr getEnchantmentsInTableVectors() {
        JArr a = new JArr();
        long[] xpSeeds = {0x00000000L, 0x00000001L, 0x12345678L, 0xDEADBEEFL, 0x7FFFFFFFL,
                0x80000000L, 0xFFFFFFFFL};
        String[] items = {"diamond_sword", "iron_chestplate", "book", "bow"};
        Versions[] versions = {Versions.V1_8, Versions.V1_16, Versions.V1_21_11};
        final int bookshelves = 15;
        for (long xpSeedL : xpSeeds) {
            int xpSeed = (int) xpSeedL;
            for (String item : items) {
                for (Versions ver : versions) {
                    // Exactly like EnchCrackerWindow / the enchantment calculator:
                    // a fresh Random seeded with the XP seed, then the three slot
                    // levels are computed in a row (the RNG is *not* reset in
                    // between), then getEnchantmentsInTable is called per slot on
                    // the same Random object (that method re-seeds internally).
                    Random rand = new Random();
                    rand.setSeed(xpSeed);
                    int[] levels = new int[3];
                    for (int slot = 0; slot < 3; slot++) {
                        levels[slot] = Enchantments.calcEnchantmentTableLevel(
                                rand, slot, bookshelves, item);
                    }
                    JArr slots = new JArr();
                    for (int slot = 0; slot < 3; slot++) {
                        List<Enchantments.EnchantmentInstance> list =
                                Enchantments.getEnchantmentsInTable(
                                        rand, xpSeed, item, slot, levels[slot], ver);
                        slots.add(new JObj()
                                .put("slot", slot)
                                .put("level", levels[slot])
                                .put("enchantments", enchantList(list)));
                    }
                    a.add(new JObj()
                            .put("xpSeed", hex8(xpSeed))
                            .put("item", item)
                            .put("version", ver.name())
                            .put("bookshelves", bookshelves)
                            .put("slots", slots));
                }
            }
        }
        return a;
    }

    // ---------------------------------------------------------------
    // Seed cracker (slow: full 2^32 search per observation)
    // ---------------------------------------------------------------

    static JArr seedCrackerVectors(JObj root, Path out) throws Exception {
        int[][] observations = {
                {15, 5, 11, 30},
                {15, 2, 7, 30},
                {10, 3, 5, 20},
                {15, 1, 1, 30},
        };
        JArr a = new JArr();
        root.put("seedCracker", a);
        for (int[] obs : observations) {
            long t0 = System.nanoTime();
            JavaSingleSeedCracker cracker = new JavaSingleSeedCracker();
            cracker.firstInput(obs[0], obs[1], obs[2], obs[3]);
            int count = cracker.getPossibleSeeds();

            // JavaSingleSeedCracker has no public element accessor; reach the
            // IntArray through reflection (same package-less classpath).
            Field field = JavaSingleSeedCracker.class.getDeclaredField("possibleSeeds");
            field.setAccessible(true);
            IntArray seg = (IntArray) field.get(cracker);

            int[] all = new int[count];
            for (int i = 0; i < count; i++) {
                all[i] = seg.get(i);
            }
            Arrays.sort(all);

            JArr first = new JArr();
            JArr last = new JArr();
            for (int i = 0; i < Math.min(5, count); i++) {
                first.add(s(hex8(all[i])));
            }
            for (int i = Math.max(0, count - 5); i < count; i++) {
                last.add(s(hex8(all[i])));
            }

            a.add(new JObj()
                    .put("bookshelves", obs[0])
                    .put("slot1", obs[1])
                    .put("slot2", obs[2])
                    .put("slot3", obs[3])
                    .put("count", (long) count)
                    .put("first", first)
                    .put("last", last));

            double seconds = (System.nanoTime() - t0) / 1e9;
            System.err.printf("[cracker] b=%d s1=%d s2=%d s3=%d -> %d seeds (%.1fs)%n",
                    obs[0], obs[1], obs[2], obs[3], count, seconds);

            // Write incrementally (the slow section may be interrupted).
            writeOut(root, out);

            cracker = null;
            seg = null;
            all = null;
            System.gc();
        }
        return a;
    }

    // ---------------------------------------------------------------
    // Player-seed recovery (same 65536 brute force as EnchCrackerWindow.java)
    // ---------------------------------------------------------------

    /** Returns the recovered 48-bit player seed, or -1 if none found. */
    static long recoverPlayerSeed(int xpSeed1, int xpSeed2) {
        long seed1High = ((long) xpSeed1 << 16) & MASK_HIGH32;
        long seed2High = ((long) xpSeed2 << 16) & MASK_HIGH32;
        for (int seed1Low = 0; seed1Low < 65536; seed1Low++) {
            long candidate = seed1High | seed1Low;
            long next = (candidate * MULT + ADD) & MASK48;
            if ((next & MASK_HIGH32) == seed2High) {
                return next;
            }
        }
        return -1L;
    }

    static JArr playerSeedVectors() {
        // Explicit pairs first (the second value of the second pair is the low
        // 32 bits of the java.util.Random multiplier 0x5DEECE66D).
        List<int[]> pairs = new ArrayList<>();
        pairs.add(new int[] {0x12345678, (int) 0x87654321L});
        pairs.add(new int[] {0x00000000, (int) 0xDEECE66DL});

        // Three "random" pairs derived from fixed 48-bit player seeds, so that
        // recovery is known to succeed; these also exercise the forward LCG.
        long[] derivedFrom = {0x0A1B2C3D4E5FL, 0x000000000001L, 0x0000FFFFFFFFFFFFL};
        for (long p : derivedFrom) {
            pairs.add(new int[] {(int) (p >>> 16), (int) (lcg(p) >>> 16)});
        }

        JArr a = new JArr();
        for (int[] pair : pairs) {
            long recovered = recoverPlayerSeed(pair[0], pair[1]);
            boolean found = recovered >= 0;
            JObj o = new JObj()
                    .put("xpSeed1", hex8(pair[0]))
                    .put("xpSeed2", hex8(pair[1]))
                    .put("found", found);
            if (found) {
                o.put("playerSeed", hex12(recovered));
                o.put("nextPlayerSeed", hex12(lcg(recovered)));
                o.put("nextXpSeed", hex8((int) (lcg(recovered) >>> 16)));
            } else {
                o.put("playerSeed", (J) NULL);
                o.put("nextPlayerSeed", NULL);
                o.put("nextXpSeed", NULL);
            }
            a.add(o);
        }
        return a;
    }

    // ---------------------------------------------------------------
    // Enchantment calculator search (verbatim logic from EnchCrackerWindow.java)
    // ---------------------------------------------------------------

    /**
     * Verbatim port of the search loop in EnchCrackerWindow's
     * findEnchantment action listener. Returns {timesNeeded, bookshelves, slot}
     * where slot is the 0-based internal slot; timesNeeded == -2 means not found.
     */
    static int[] calc(long seed, String item, Versions mcVersion, int maxShelvesVal, int playerLevel,
            List<Enchantments.EnchantmentInstance> wantedEnch,
            List<Enchantments.EnchantmentInstance> unwantedEnch) {
        // -2: not found; -1: no dummy enchantment needed; >= 0: number of times
        // needed to throw out item before dummy enchantment
        int timesNeeded = -2;
        int bookshelvesNeeded = 0;
        int slot = 0;
        int[] enchantLevels = new int[3];

        outerLoop:
        for (int i = -1; i <= 64 * 32; i++) {
            int xpSeed;
            if (i == -1) {
                // XP seed will be the current seed, because there is no dummy enchant
                xpSeed = (int) (seed >>> 16);
            } else {
                // XP seed will be the current seed, advanced by one because of the dummy enchant
                xpSeed = (int) (((seed * 0x5deece66dL + 0xb) & 0x0000_ffff_ffff_ffffL) >>> 16);
            }

            Random rand = new Random();
            for (bookshelvesNeeded = 0; bookshelvesNeeded <= maxShelvesVal; bookshelvesNeeded++) {
                rand.setSeed(xpSeed);
                // Calculate all slot levels
                // Important they're done in a row like this because RNG is not reset in between
                for (slot = 0; slot < 3; slot++) {
                    int level = Enchantments.calcEnchantmentTableLevel(rand, slot, bookshelvesNeeded, item);
                    if (level < slot + 1) {
                        level = 0;
                    }
                    enchantLevels[slot] = level;
                }

                slotLoop:
                for (slot = 0; slot < 3; slot++) {
                    // Get enchantments (changes RNG seed)
                    List<Enchantments.EnchantmentInstance> enchantments = Enchantments
                            .getEnchantmentsInTable(rand, xpSeed, item, slot, enchantLevels[slot], mcVersion);

                    if (enchantLevels[slot] == 0) {
                        continue slotLoop;
                    } else if (i == -1) {
                        if (playerLevel < enchantLevels[slot]) {
                            continue slotLoop;
                        }
                    } else if (playerLevel < (enchantLevels[slot] + 1)) {
                        continue slotLoop;
                    }

                    // Does this list contain all the enchantments we want?
                    for (Enchantments.EnchantmentInstance inst : wantedEnch) {
                        boolean found = false;
                        for (Enchantments.EnchantmentInstance inst2 : enchantments) {
                            if (!inst.enchantment.equals(inst2.enchantment)) {
                                continue;
                            }
                            if (inst.level > inst2.level) {
                                continue slotLoop;
                            }
                            found = true;
                            break;
                        }
                        if (!found) {
                            continue slotLoop;
                        }
                    }

                    // Does this list contain none of the enchantments we don't want?
                    for (Enchantments.EnchantmentInstance inst : unwantedEnch) {
                        for (Enchantments.EnchantmentInstance inst2 : enchantments) {
                            if (!inst.enchantment.equals(inst2.enchantment)) {
                                continue;
                            }
                            continue slotLoop;
                        }
                    }

                    timesNeeded = i;
                    break outerLoop;
                }
            }

            // Simulate an item throw
            if (i != -1) {
                for (int j = 0; j < 4; j++) {
                    seed = (seed * 0x5deece66dL + 0xb) & 0x0000_ffff_ffff_ffffL;
                }
            }
        }
        return new int[] {timesNeeded, bookshelvesNeeded, slot};
    }

    static Enchantments.EnchantmentInstance inst(String enchantment, int level) {
        return new Enchantments.EnchantmentInstance(enchantment, level);
    }

    static JArr instList(List<Enchantments.EnchantmentInstance> list) {
        JArr a = new JArr();
        for (Enchantments.EnchantmentInstance i : list) {
            a.add(new JObj().put("id", i.enchantment).put("level", i.level));
        }
        return a;
    }

    static JArr calculatorVectors() {
        JArr a = new JArr();
        // {playerSeed, item, version, maxShelves, playerLevel, wanted, unwanted}
        List<Object[]> cases = new ArrayList<>();
        cases.add(new Object[] {0x1A2B3C4D5E6FL, "diamond_sword", Versions.V1_16, 15, 30,
                Arrays.asList(inst("sharpness", 4)), Arrays.asList(inst("fire_aspect", 1))});
        cases.add(new Object[] {0x1A2B3C4D5E6FL, "diamond_sword", Versions.V1_16, 15, 999,
                Arrays.asList(inst("sharpness", 4)), new ArrayList<Enchantments.EnchantmentInstance>()});
        cases.add(new Object[] {0x1A2B3C4D5E6FL, "diamond_sword", Versions.V1_8, 15, 30,
                Arrays.asList(inst("sharpness", 4)), Arrays.asList(inst("fire_aspect", 1))});
        cases.add(new Object[] {0x000000000001L, "bow", Versions.V1_14, 15, 30,
                Arrays.asList(inst("infinity", 1)), new ArrayList<Enchantments.EnchantmentInstance>()});
        cases.add(new Object[] {0x0000FFFFFFFFFFFFL, "book", Versions.V1_21_11, 30, 30,
                Arrays.asList(inst("mending", 1)), new ArrayList<Enchantments.EnchantmentInstance>()});
        cases.add(new Object[] {0x1A2B3C4D5E6FL, "leather_boots", Versions.V1_8, 15, 30,
                Arrays.asList(inst("feather_falling", 4)), Arrays.asList(inst("thorns", 3))});
        cases.add(new Object[] {0x1234ABCD5678L, "mace", Versions.V1_21_11, 15, 30,
                Arrays.asList(inst("density", 5)), Arrays.asList(inst("breach", 4))});
        cases.add(new Object[] {0x0BADF00D1234L, "diamond_sword", Versions.V1_16, 15, 3,
                Arrays.asList(inst("sharpness", 3)), new ArrayList<Enchantments.EnchantmentInstance>()});
        cases.add(new Object[] {0x1A2B3C4D5E6FL, "diamond_sword", Versions.V1_16, 15, 30,
                Arrays.asList(inst("silk_touch", 1), inst("fortune", 3)),
                new ArrayList<Enchantments.EnchantmentInstance>()});
        cases.add(new Object[] {0x123456789ABCL, "iron_chestplate", Versions.V1_8, 15, 30,
                Arrays.asList(inst("protection", 4)), new ArrayList<Enchantments.EnchantmentInstance>()});

        for (Object[] c : cases) {
            @SuppressWarnings("unchecked")
            List<Enchantments.EnchantmentInstance> wanted =
                    (List<Enchantments.EnchantmentInstance>) c[5];
            @SuppressWarnings("unchecked")
            List<Enchantments.EnchantmentInstance> unwanted =
                    (List<Enchantments.EnchantmentInstance>) c[6];
            long playerSeed = (Long) c[0];
            String item = (String) c[1];
            Versions ver = (Versions) c[2];
            int maxShelves = (Integer) c[3];
            int playerLevel = (Integer) c[4];

            int[] result = calc(playerSeed, item, ver, maxShelves, playerLevel, wanted, unwanted);
            boolean found = result[0] != -2;
            JObj o = new JObj()
                    .put("playerSeed", hex12(playerSeed))
                    .put("item", item)
                    .put("version", ver.name())
                    .put("maxShelves", maxShelves)
                    .put("playerLevel", playerLevel)
                    .put("wanted", instList(wanted))
                    .put("unwanted", instList(unwanted))
                    .put("found", found)
                    .put("timesNeeded", result[0]);
            if (found) {
                o.put("bookshelves", result[1]);
                o.put("slot", result[2]);
                o.put("slotDisplay", result[2] + 1);
            } else {
                o.put("bookshelves", NULL);
                o.put("slot", NULL);
                o.put("slotDisplay", NULL);
            }
            a.add(o);
        }
        return a;
    }

    // =====================================================================
    // Main
    // =====================================================================

    public static void main(String[] args) throws Exception {
        Path out = Paths.get("vectors", "reference_vectors.json");
        boolean skipCracker = false;
        boolean skipCalc = false;
        for (String arg : args) {
            if (arg.equals("--skip-cracker")) {
                skipCracker = true;
            } else if (arg.equals("--skip-calc")) {
                skipCalc = true;
            } else if (arg.startsWith("--")) {
                System.err.println("Unknown flag: " + arg);
                System.exit(2);
            } else {
                out = Paths.get(arg);
            }
        }
        if (out.toAbsolutePath().getParent() != null) {
            Files.createDirectories(out.toAbsolutePath().getParent());
        }

        JObj root = new JObj();
        root.put("metadata", metadata());

        long t = System.nanoTime();
        root.put("levelsToXP", levelsToXPVectors());
        System.err.printf("[section] levelsToXP (%d)%n", ((JArr) root.m.get("levelsToXP")).size());

        root.put("getMaxLevel", getMaxLevelVectors());
        System.err.printf("[section] getMaxLevel (%d)%n", ((JArr) root.m.get("getMaxLevel")).size());

        root.put("getMinEnchantability", minMaxEnchantabilityVectors(false));
        System.err.printf("[section] getMinEnchantability (%d)%n",
                ((JArr) root.m.get("getMinEnchantability")).size());

        root.put("getMaxEnchantability", minMaxEnchantabilityVectors(true));
        System.err.printf("[section] getMaxEnchantability (%d)%n",
                ((JArr) root.m.get("getMaxEnchantability")).size());

        root.put("getWeight", getWeightVectors());
        System.err.printf("[section] getWeight (%d)%n", ((JArr) root.m.get("getWeight")).size());

        root.put("canApply", canApplyVectors());
        System.err.printf("[section] canApply (%d)%n", ((JArr) root.m.get("canApply")).size());

        root.put("getEnchantability", getEnchantabilityVectors());
        System.err.printf("[section] getEnchantability (%d)%n",
                ((JArr) root.m.get("getEnchantability")).size());

        root.put("getHighestAllowedEnchantments", getHighestAllowedVectors());
        System.err.printf("[section] getHighestAllowedEnchantments (%d)%n",
                ((JArr) root.m.get("getHighestAllowedEnchantments")).size());

        root.put("getMaxLevelInTable", getMaxLevelInTableVectors());
        System.err.printf("[section] getMaxLevelInTable (%d)%n",
                ((JArr) root.m.get("getMaxLevelInTable")).size());

        root.put("getEnchantmentsInTable", getEnchantmentsInTableVectors());
        System.err.printf("[section] getEnchantmentsInTable (%d)%n",
                ((JArr) root.m.get("getEnchantmentsInTable")).size());

        writeOut(root, out);

        root.put("playerSeedRecovery", playerSeedVectors());
        System.err.printf("[section] playerSeedRecovery (%d)%n",
                ((JArr) root.m.get("playerSeedRecovery")).size());
        writeOut(root, out);

        if (skipCalc) {
            System.err.println("[section] enchantmentCalculator SKIPPED (--skip-calc)");
            root.put("enchantmentCalculator", new JArr());
        } else {
            root.put("enchantmentCalculator", calculatorVectors());
            System.err.printf("[section] enchantmentCalculator (%d)%n",
                    ((JArr) root.m.get("enchantmentCalculator")).size());
            writeOut(root, out);
        }

        if (skipCracker) {
            System.err.println("[section] seedCracker SKIPPED (--skip-cracker)");
            root.put("seedCracker", new JArr());
            writeOut(root, out);
        } else {
            long tCracker = System.nanoTime();
            seedCrackerVectors(root, out);
            System.err.printf("[section] seedCracker done in %.1fs%n",
                    (System.nanoTime() - tCracker) / 1e9);
        }

        writeOut(root, out);
        System.err.printf("[done] total %.1fs%n", (System.nanoTime() - t) / 1e9);
    }
}

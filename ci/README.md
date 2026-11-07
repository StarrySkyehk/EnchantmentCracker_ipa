# Java reference vectors

`ReferenceVectors.java` calls the **original Java implementation** (in
`../enchcracker-src`) and emits a deterministic JSON document of test vectors for
the Swift port. `vectors/reference_vectors.json` is the generated reference data.

## How to regenerate

From the **repository root** (the `EnchantmentCracker-iOS` directory):

```bash
# 1. Compile the original Java sources together with the generator.
javac -d ci/build \
    ../enchcracker-src/src/enchcracker/Versions.java \
    ../enchcracker-src/src/enchcracker/Materials.java \
    ../enchcracker-src/src/enchcracker/Items.java \
    ../enchcracker-src/src/enchcracker/Enchantments.java \
    ../enchcracker-src/src/enchcracker/SimpleRandom.java \
    ../enchcracker-src/src/enchcracker/IntArray.java \
    ../enchcracker-src/src/enchcracker/Log.java \
    ../enchcracker-src/src/enchcracker/cracker/AbstractSingleSeedCracker.java \
    ../enchcracker-src/src/enchcracker/cracker/JavaSingleSeedCracker.java \
    ci/ReferenceVectors.java

# 2. Run it. The original Log class writes enchcracker.log into the current
#    directory, so run from ci/ to keep the repository root clean.
cd ci
java -Xmx3G -cp build ReferenceVectors vectors/reference_vectors.json
```

A full run takes roughly **40 s** on an 8-core machine: the seed-cracker section
brute-forces the whole 2^32 XP-seed space once per observation (7 worker threads,
~100M matching seeds for the first observation, hence `-Xmx3G`).

Useful flags:

```bash
java -Xmx3G -cp build ReferenceVectors --skip-cracker vectors/reference_vectors.json
java -Xmx3G -cp build ReferenceVectors --skip-calc    vectors/reference_vectors.json
```

The JSON file is rewritten after every section (and after every seed-cracker
observation), so an interrupted run still leaves a usable partial file.

## What the JSON contains

| key | Java call | count |
| --- | --- | --- |
| `levelsToXP` | `Enchantments.levelsToXP(startLevel, numLevels)` | 205 |
| `getMaxLevel` | `Enchantments.getMaxLevel(ench)` | 36 |
| `getMinEnchantability` | `Enchantments.getMinEnchantability(ench, level)` | 114 |
| `getMaxEnchantability` | `Enchantments.getMaxEnchantability(ench, level)` | 114 |
| `getWeight` | `Enchantments.getWeight(ench, version)` | 396 |
| `canApply` | `Enchantments.canApply(ench, item, primary)` | 6048 |
| `getEnchantability` | `Items.getEnchantability(item)` | 84 |
| `getHighestAllowedEnchantments` | `Enchantments.getHighestAllowedEnchantments(level, item, version)` | 252 |
| `getMaxLevelInTable` | `Enchantments.getMaxLevelInTable(ench, item)` | 252 |
| `getEnchantmentsInTable` | table levels + `Enchantments.getEnchantmentsInTable(...)` | 84 (x3 slots) |
| `seedCracker` | `JavaSingleSeedCracker.firstInput(...)` full 2^32 search | 4 |
| `playerSeedRecovery` | 65536-step brute force from `EnchCrackerWindow` | 5 |
| `enchantmentCalculator` | the `for (int i = -1; i <= 64 * 32; i++)` search | 10 |

Conventions:

* `xpSeed` values are strings: `0x` + 8 hex digits.
* `playerSeed` values are strings: `0x` + 12 hex digits (48-bit).
* Enchantment lists are arrays of `{"id": "<enchantment id>", "level": N}` **in
  the exact order the Java code produced them**.
* `seedCracker.count` is the exact number of matching 32-bit seeds over the whole
  space; `first` / `last` are the first/last five matching seeds in **ascending
  signed-32-bit order** (Java `Arrays.sort(int[])` order), formatted as unsigned
  8-hex strings.
* `enchantmentCalculator.timesNeeded` uses the original convention: `-2` =
  impossible, `-1` = no dummy enchantment needed, `>= 0` = number of items to
  throw. `bookshelves`/`slot` are `null` when impossible (`slot` is 0-based;
  `slotDisplay` is the 1-based value shown in the UI).
* `playerSeedRecovery` derives three of its pairs from fixed 48-bit player seeds
  so that recovery/forward-continuation is exercised for guaranteed-success
  cases; the other two pairs are arbitrary 32-bit XP-seed pairs (which can
  legitimately fail to recover, matching the app's "Fail!" behaviour).

`ci/build/`, `ci/enchcracker.log` and `ci/run.log` are build/run artifacts (not
committed).

## Independent cross-check of the seed-cracker vectors

`ci/CrossCheck.java` re-derives the four `seedCracker` vectors with a **different,
straightforward** brute force (one code path per seed, its own worker threads,
no `JavaSingleSeedCracker`/`IntArray`) and compares the exact match count plus
the first/last five matching seeds against the JSON. It exists so the seed-cracker
reference data does not depend on a single implementation.

```bash
# from the repository root
javac -d ci/build ../enchcracker-src/src/enchcracker/SimpleRandom.java ci/CrossCheck.java

cd ci
java -Xmx1G -cp build CrossCheck vectors/reference_vectors.json
```

It prints one `obs ... OK/MISMATCH` line per observation and exits non-zero on
any difference (a full run takes ~1 minute on 8 cores). Last result: all 4
observations `OK` (counts 100663118 / 1310611 / 23255942 / 0).

# Swift verification runner

`main.swift` is a standalone command-line verifier (no XCTest, no SwiftUI, no
Swift package). It is compiled **together with** the Foundation-only engine
sources and compares the Swift port against the Java reference vectors in
`ci/vectors/reference_vectors.json`.

## Build

Requires a Swift toolchain (`swiftc`) and the engine sources in
`Sources/Core/Engine/` (they import Foundation only).

From the **repository root** (the `EnchantmentCracker-iOS` directory), in a bash
shell (Git Bash / MSYS2 on Windows, Terminal on macOS, any shell on Linux):

```bash
swiftc -O -whole-module-optimization Sources/Core/Engine/*.swift verify/main.swift -o verify/check
```

`-whole-module-optimization` is what CI uses; plain `-O` works too and is only
marginally slower. On Windows this produces `verify/check.exe` (Swift on Windows
appends the `.exe` suffix itself, so `-o verify/check` is fine).

CI (`.github/workflows/verify.yml`) compiles and runs exactly this command on a
`macos-15` runner, so the Swift toolchain on the development machine is not
required for verification. (The Windows Swift 6.4.2 toolchain installed locally
crashes with "Illegal instruction", exit 132, on this machine, even for
`swiftc --version`; CI is authoritative.)

## Run

```bash
./verify/check ci/vectors/reference_vectors.json
```

On Windows:

```bash
./verify/check.exe ci/vectors/reference_vectors.json
```

The vectors path is optional; the default is `ci/vectors/reference_vectors.json`
(with `vectors/reference_vectors.json` as a fallback for running from `ci/`).

Options:

```bash
./verify/check --skip-cracker ci/vectors/reference_vectors.json
```

* `--skip-cracker` skips the seed-cracker section. That section brute-forces the
  whole 2^32 XP-seed space once per observation with the `SeedCracker` engine
  (four scans in total) — use the flag during quick iterations and run the full
  suite before declaring the port verified.

## Measured runtime (GitHub Actions, macos-15, 3 cores)

Recorded on run `42394526027` (commit `047b7bf`, Apple Swift 6.1.2):

| phase | time |
| --- | --- |
| `swiftc -O -whole-module-optimization` compile | 15 s |
| all non-cracker sections (incl. 84 table simulations + calculator search) | 8 s |
| seedCracker scan `(15,5,11,30)` — 100,663,118 matches, sorted | 174 s |
| seedCracker scan `(15,2,7,30)` — 1,310,611 matches | 150 s |
| seedCracker scan `(10,3,5,20)` — 23,255,942 matches | 178 s |
| seedCracker scan `(15,1,1,30)` — 0 matches | 106 s |
| **whole verifier run** | **~10.3 min** |

The single-scan rate on that runner is ~26 M seeds/s (bench job: 166 s for one
full 2^32 scan), so the four scans dominate. Result of that run: `RESULT: PASS —
all 8056 reference vectors matched` (per-section counts: 1 + 205 + 36 + 114 + 114
+ 396 + 6048 + 84 + 252 + 252 + 504 + 14 + 24 + 12).

## Output

For every section the runner prints one `PASS`/`FAIL` line with the number of
checks, and for every mismatch an exact expected-vs-actual `FAIL [section] ...`
line (the first 60 mismatches are printed, the rest only counted). The process
exits with code `0` only when every vector matches, `1` on any mismatch.

Sections checked: `levelsToXP`, `getMaxLevel`, `getMinEnchantability`,
`getMaxEnchantability`, `getWeight`, `canApply`, `getEnchantability`,
`getHighestAllowedEnchantments`, `getMaxLevelInTable`, `getEnchantmentsInTable`
(table levels + resulting enchantment lists, in order), `playerSeedRecovery`,
`enchantmentCalculator`, and `seedCracker` (exact match count + first/last five
seeds in ascending order).

`ci/ReferenceVectors.java` / `ci/README.md` explain how the reference JSON is
generated from the original Java code.

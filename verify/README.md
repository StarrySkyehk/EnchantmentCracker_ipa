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
swiftc -O Sources/Core/Engine/*.swift verify/main.swift -o verify/check
```

On Windows this produces `verify/check.exe` (Swift on Windows appends the
`.exe` suffix itself, so `-o verify/check` is fine).

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
  (four scans in total, ~1-2 minutes) — use the flag during quick iterations and
  run the full suite before declaring the port verified.

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

// verify/main.swift
//
// Standalone verification harness for the Swift port of EnchantmentCracker.
// It loads ci/vectors/reference_vectors.json (produced by the ORIGINAL Java
// implementation), recomputes every vector with the Swift engine in
// Sources/Core/Engine/, compares each value and exits non-zero on any mismatch.
//
// Build (from the repository root):
//   swiftc -O Sources/Core/Engine/*.swift verify/main.swift -o verify/check
//
// Run:
//   ./verify/check ci/vectors/reference_vectors.json
//
// Arguments:
//   [path]          path to reference_vectors.json (default: ci/vectors/reference_vectors.json,
//                   falling back to vectors/reference_vectors.json)
//   --skip-cracker  skip the slow full-2^32 seed-cracker section
//
// Exit code: 0 = every vector matched, 1 = at least one mismatch.

import Foundation
#if os(Windows)
import ucrt
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// =====================================================================
// Harness
// =====================================================================

var totalChecks = 0
var totalFailures = 0
var printedFailures = 0
let maxPrintedFailures = 60

func fail(_ section: String, _ detail: String) {
    totalFailures += 1
    if printedFailures < maxPrintedFailures {
        print("FAIL [\(section)] \(detail)")
    } else if printedFailures == maxPrintedFailures {
        print("FAIL [\(section)] ... further mismatches suppressed (showing first \(maxPrintedFailures)) ...")
    }
    printedFailures += 1
}

func progress(_ text: String) {
    if let data = (text + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func checkInt(_ section: String, _ label: String, _ expected: Int, _ actual: Int) {
    totalChecks += 1
    if expected != actual {
        fail(section, "\(label): expected \(expected), actual \(actual)")
    }
}

func checkString(_ section: String, _ label: String, _ expected: String, _ actual: String) {
    totalChecks += 1
    if expected != actual {
        fail(section, "\(label): expected \(expected), actual \(actual)")
    }
}

func checkBool(_ section: String, _ label: String, _ expected: Bool, _ actual: Bool) {
    totalChecks += 1
    if expected != actual {
        fail(section, "\(label): expected \(expected), actual \(actual)")
    }
}

struct SectionBox {
    let failures: Int
    let checks: Int
}

func sectionBegin(_ name: String) -> SectionBox {
    progress("RUN [\(name)]")
    return SectionBox(failures: totalFailures, checks: totalChecks)
}

func sectionEnd(_ name: String, _ box: SectionBox) {
    let mismatches = totalFailures - box.failures
    let checks = totalChecks - box.checks
    if mismatches == 0 {
        print("PASS [\(name)] \(checks) checks")
    } else {
        print("FAIL [\(name)] \(mismatches) of \(checks) checks mismatched")
    }
}

// =====================================================================
// JSON helpers
// =====================================================================

typealias JSON = [String: Any]

func jsonObject(_ root: JSON, _ key: String) -> JSON {
    guard let value = root[key] as? JSON else {
        fatalError("reference vectors: missing object section '\(key)'")
    }
    return value
}

func jsonObjects(_ root: JSON, _ key: String) -> [JSON] {
    guard let value = root[key] as? [JSON] else {
        fatalError("reference vectors: missing array section '\(key)'")
    }
    return value
}

func jInt(_ object: JSON, _ key: String) -> Int {
    guard let number = object[key] as? NSNumber else {
        fatalError("reference vectors: missing integer '\(key)' in \(object.keys.sorted())")
    }
    return number.intValue
}

func jString(_ object: JSON, _ key: String) -> String {
    guard let value = object[key] as? String else {
        fatalError("reference vectors: missing string '\(key)' in \(object.keys.sorted())")
    }
    return value
}

func jBool(_ object: JSON, _ key: String) -> Bool {
    guard let number = object[key] as? NSNumber else {
        fatalError("reference vectors: missing bool '\(key)' in \(object.keys.sorted())")
    }
    return number.boolValue
}

func jInstances(_ value: Any?) -> [Enchantments.Instance] {
    guard let array = value as? [JSON] else {
        fatalError("reference vectors: enchantment list has unexpected shape")
    }
    return array.map {
        Enchantments.Instance(enchantment: jString($0, "id"), level: jInt($0, "level"))
    }
}

// =====================================================================
// Value conversions
// =====================================================================

func version(_ name: String) -> MCVersion {
    switch name {
    case "V1_8": return .v1_8
    case "V1_9": return .v1_9
    case "V1_11": return .v1_11
    case "V1_11_1": return .v1_11_1
    case "V1_13": return .v1_13
    case "V1_14": return .v1_14
    case "V1_14_3": return .v1_14_3
    case "V1_16": return .v1_16
    case "V1_21": return .v1_21
    case "V1_21_9": return .v1_21_9
    case "V1_21_11": return .v1_21_11
    default: fatalError("reference vectors: unknown MC version '\(name)'")
    }
}

func hexDigits(_ value: UInt64, _ width: Int) -> String {
    var text = String(value, radix: 16, uppercase: true)
    if text.count < width {
        text = String(repeating: "0", count: width - text.count) + text
    }
    return "0x" + text
}

func hex32(_ value: Int32) -> String {
    return hexDigits(UInt64(UInt32(bitPattern: value)), 8)
}

func hex48(_ value: UInt64) -> String {
    return hexDigits(value & 0x0000_FFFF_FFFF_FFFF, 12)
}

func parseHex(_ text: String) -> UInt64 {
    var digits = text
    if digits.hasPrefix("0x") || digits.hasPrefix("0X") {
        digits = String(digits.dropFirst(2))
    }
    guard let value = UInt64(digits, radix: 16) else {
        fatalError("reference vectors: bad hex value '\(text)'")
    }
    return value
}

func describe(_ instances: [Enchantments.Instance]) -> String {
    return "[" + instances.map { "\($0.enchantment) \($0.level)" }.joined(separator: ", ") + "]"
}

func checkInstances(_ section: String, _ label: String,
                    expected: [Enchantments.Instance],
                    actual: [Enchantments.Instance]) {
    totalChecks += 1
    if expected != actual {
        fail(section, "\(label): expected \(describe(expected)), actual \(describe(actual))")
    }
}

// =====================================================================
// Load vectors
// =====================================================================

var skipCracker = false
var vectorsPath = "ci/vectors/reference_vectors.json"
var sawPath = false
for argument in CommandLine.arguments.dropFirst() {
    if argument == "--skip-cracker" {
        skipCracker = true
    } else if argument.hasPrefix("--") {
        fatalError("unknown flag: \(argument)")
    } else {
        vectorsPath = argument
        sawPath = true
    }
}
if !sawPath {
    let fallback = "vectors/reference_vectors.json"
    if !FileManager.default.fileExists(atPath: vectorsPath),
       FileManager.default.fileExists(atPath: fallback) {
        vectorsPath = fallback
    }
}

progress("loading reference vectors from \(vectorsPath)")
let rawData: Data
do {
    rawData = try Data(contentsOf: URL(fileURLWithPath: vectorsPath))
} catch {
    fatalError("cannot read \(vectorsPath): \(error)")
}
let parsed: Any
do {
    parsed = try JSONSerialization.jsonObject(with: rawData, options: [])
} catch {
    fatalError("cannot parse \(vectorsPath): \(error)")
}
guard let root = parsed as? JSON else {
    fatalError("reference vectors root is not a JSON object")
}

let metadata = jsonObject(root, "metadata")
progress("vectors generated by \(jString(metadata, "generatedBy")) (Java \(jString(metadata, "javaVersion")))")

// =====================================================================
// metadata: table enchantment order
// =====================================================================

do {
    let section = "metadata.tableEnchantments"
    let box = sectionBegin(section)
    let expected = (metadata["tableEnchantments"] as? [String]) ?? []
    totalChecks += 1
    if expected != Enchantments.tableEnchantments {
        fail(section,
             "expected \(expected.count) entries \(expected), actual \(Enchantments.tableEnchantments.count) entries \(Enchantments.tableEnchantments)")
    }
    sectionEnd(section, box)
}

// =====================================================================
// a. levelsToXP
// =====================================================================

do {
    let section = "levelsToXP"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let start = jInt(vector, "startLevel")
        let count = jInt(vector, "numLevels")
        checkInt(section, "levelsToXP(\(start), \(count))",
                 jInt(vector, "result"), Enchantments.levelsToXP(start, count))
    }
    sectionEnd(section, box)
}

// =====================================================================
// b. getMaxLevel / getMinEnchantability / getMaxEnchantability
// =====================================================================

do {
    let section = "getMaxLevel"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let enchantment = jString(vector, "enchantment")
        checkInt(section, "maxLevel(\(enchantment))",
                 jInt(vector, "result"), Enchantments.maxLevel(enchantment))
    }
    sectionEnd(section, box)
}

do {
    let section = "getMinEnchantability"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let enchantment = jString(vector, "enchantment")
        let level = jInt(vector, "level")
        checkInt(section, "minEnchantability(\(enchantment), \(level))",
                 jInt(vector, "result"), Enchantments.minEnchantability(enchantment, level))
    }
    sectionEnd(section, box)
}

do {
    let section = "getMaxEnchantability"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let enchantment = jString(vector, "enchantment")
        let level = jInt(vector, "level")
        checkInt(section, "maxEnchantability(\(enchantment), \(level))",
                 jInt(vector, "result"), Enchantments.maxEnchantability(enchantment, level))
    }
    sectionEnd(section, box)
}

// =====================================================================
// c. getWeight
// =====================================================================

do {
    let section = "getWeight"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let enchantment = jString(vector, "enchantment")
        let ver = version(jString(vector, "version"))
        checkInt(section, "weight(\(enchantment), \(ver))",
                 jInt(vector, "result"), Enchantments.weight(enchantment, ver))
    }
    sectionEnd(section, box)
}

// =====================================================================
// d. canApply
// =====================================================================

do {
    let section = "canApply"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let enchantment = jString(vector, "enchantment")
        let item = jString(vector, "item")
        let primary = jBool(vector, "primary")
        checkBool(section, "canApply(\(enchantment), \(item), \(primary))",
                  jBool(vector, "result"), Enchantments.canApply(enchantment, item, primary))
    }
    sectionEnd(section, box)
}

// =====================================================================
// e. getEnchantability
// =====================================================================

do {
    let section = "getEnchantability"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let item = jString(vector, "item")
        checkInt(section, "getEnchantability(\(item))",
                 jInt(vector, "result"), Items.getEnchantability(item))
    }
    sectionEnd(section, box)
}

// =====================================================================
// f. getHighestAllowedEnchantments
// =====================================================================

do {
    let section = "getHighestAllowedEnchantments"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let level = jInt(vector, "level")
        let item = jString(vector, "item")
        let ver = version(jString(vector, "version"))
        let expected = jInstances(vector["result"])
        let actual = Enchantments.highestAllowedEnchantments(level: level, item: item, version: ver)
        checkInstances(section, "highestAllowed(\(level), \(item), \(ver))", expected: expected, actual: actual)
    }
    sectionEnd(section, box)
}

// =====================================================================
// g. getMaxLevelInTable
// =====================================================================

do {
    let section = "getMaxLevelInTable"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let enchantment = jString(vector, "enchantment")
        let item = jString(vector, "item")
        checkInt(section, "maxLevelInTable(\(enchantment), \(item))",
                 jInt(vector, "result"), Enchantments.maxLevelInTable(enchantment, item))
    }
    sectionEnd(section, box)
}

// =====================================================================
// h. getEnchantmentsInTable (with the table levels computed the same way)
// =====================================================================

do {
    let section = "getEnchantmentsInTable"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let xpSeed = Int32(bitPattern: UInt32(truncatingIfNeeded: parseHex(jString(vector, "xpSeed"))))
        let item = jString(vector, "item")
        let ver = version(jString(vector, "version"))
        let bookshelves = jInt(vector, "bookshelves")
        let label = "xpSeed=\(hex32(xpSeed)) item=\(item) \(ver)"

        var rand = SimpleRandom()
        rand.setSeed(xpSeed)
        var levels = [Int](repeating: 0, count: 3)
        for slot in 0..<3 {
            levels[slot] = Enchantments.calcEnchantmentTableLevel(&rand, slot: slot,
                                                                 bookshelves: bookshelves, item: item)
        }

        let slotObjects = (vector["slots"] as? [JSON]) ?? []
        for slotObject in slotObjects {
            let slot = jInt(slotObject, "slot")
            checkInt(section, "\(label) slot=\(slot) level",
                     jInt(slotObject, "level"), levels[slot])
            let expected = jInstances(slotObject["enchantments"])
            let actual = Enchantments.getEnchantmentsInTable(&rand, xpSeed: xpSeed, item: item,
                                                            slot: slot, levels: levels[slot],
                                                            version: ver)
            checkInstances(section, "\(label) slot=\(slot) enchantments", expected: expected, actual: actual)
        }
    }
    sectionEnd(section, box)
}

// =====================================================================
// j. player-seed recovery
// =====================================================================

do {
    let section = "playerSeedRecovery"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let xpSeed1 = Int32(bitPattern: UInt32(truncatingIfNeeded: parseHex(jString(vector, "xpSeed1"))))
        let xpSeed2 = Int32(bitPattern: UInt32(truncatingIfNeeded: parseHex(jString(vector, "xpSeed2"))))
        let label = "\(hex32(xpSeed1)) -> \(hex32(xpSeed2))"
        let expectedFound = jBool(vector, "found")
        let recovered = PlayerSeedCalculator.recover(xpSeed1: xpSeed1, xpSeed2: xpSeed2)
        checkBool(section, "\(label) found", expectedFound, recovered != nil)
        if expectedFound, let seed = recovered {
            checkString(section, "\(label) playerSeed", jString(vector, "playerSeed"), hex48(seed))
            let next = PlayerSeedCalculator.advance(seed)
            checkString(section, "\(label) nextPlayerSeed", jString(vector, "nextPlayerSeed"), hex48(next))
            checkString(section, "\(label) nextXpSeed",
                        jString(vector, "nextXpSeed"), hex32(Int32(bitPattern: UInt32(truncatingIfNeeded: next >> 16))))
        }
    }
    sectionEnd(section, box)
}

// =====================================================================
// k. enchantment-calculator search
// =====================================================================

do {
    let section = "enchantmentCalculator"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let playerSeed = parseHex(jString(vector, "playerSeed")) & 0x0000_FFFF_FFFF_FFFF
        let item = jString(vector, "item")
        let ver = version(jString(vector, "version"))
        let maxShelves = jInt(vector, "maxShelves")
        let playerLevel = jInt(vector, "playerLevel")
        let wanted = jInstances(vector["wanted"])
        let unwanted = jInstances(vector["unwanted"])
        let label = "seed=\(hex48(playerSeed)) item=\(item) \(ver) shelves=\(maxShelves) level=\(playerLevel)"

        let result = EnchantmentCalculator.search(playerSeed: playerSeed, item: item, version: ver,
                                                  maxBookshelves: maxShelves, playerLevel: playerLevel,
                                                  wanted: wanted, unwanted: unwanted)
        checkInt(section, "\(label) timesNeeded", jInt(vector, "timesNeeded"), result.timesNeeded)
        if jBool(vector, "found") {
            checkInt(section, "\(label) bookshelves", jInt(vector, "bookshelves"), result.bookshelves)
            checkInt(section, "\(label) slot", jInt(vector, "slot"), result.slot)
        }
    }
    sectionEnd(section, box)
}

// =====================================================================
// i. seed cracker (slow: one full 2^32 scan per observation)
// =====================================================================

if skipCracker {
    print("SKIP [seedCracker] (--skip-cracker)")
} else {
    let section = "seedCracker"
    let box = sectionBegin(section)
    for vector in jsonObjects(root, section) {
        let bookshelves = jInt(vector, "bookshelves")
        let slot1 = jInt(vector, "slot1")
        let slot2 = jInt(vector, "slot2")
        let slot3 = jInt(vector, "slot3")
        let label = "b=\(bookshelves) s1=\(slot1) s2=\(slot2) s3=\(slot3)"
        progress("RUN [seedCracker] scanning \(label) ...")

        let cracker = SeedCracker()
        let observation = SeedObservation(bookshelves: bookshelves, slot1: slot1,
                                          slot2: slot2, slot3: slot3)
        let result = cracker.add(observation: observation, memoryBudget: Int.max)

        checkInt(section, "\(label) count", jInt(vector, "count"), result.matchingSeeds)
        if let candidates = result.candidates {
            var sorted = candidates
            sorted.sort()
            let expectedFirst = (vector["first"] as? [String]) ?? []
            let expectedLast = (vector["last"] as? [String]) ?? []
            var actualFirst: [String] = []
            var actualLast: [String] = []
            for index in 0..<min(5, sorted.count) {
                actualFirst.append(hex32(sorted[index]))
            }
            for index in max(0, sorted.count - 5)..<sorted.count {
                actualLast.append(hex32(sorted[index]))
            }
            checkString(section, "\(label) first", expectedFirst.joined(separator: ","),
                        actualFirst.joined(separator: ","))
            checkString(section, "\(label) last", expectedLast.joined(separator: ","),
                        actualLast.joined(separator: ","))
        } else {
            fail(section, "\(label) SeedCracker returned no candidate array (memoryBudget too small?)")
        }
    }
    sectionEnd(section, box)
}

// =====================================================================
// Summary
// =====================================================================

print("")
if totalFailures == 0 {
    print("RESULT: PASS - all \(totalChecks) reference vectors matched")
} else {
    print("RESULT: FAIL - \(totalFailures) of \(totalChecks) reference vectors mismatched")
}
exit(totalFailures == 0 ? 0 : 1)

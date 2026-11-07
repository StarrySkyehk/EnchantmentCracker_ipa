import Foundation

// MARK: - Player seed recovery

/// Mirror of the "Calculate Seed" brute force in `EnchCrackerWindow`.
/// Recovers the 48-bit player seed from two consecutive 32-bit XP seeds.
enum PlayerSeedCalculator {

    @inline(__always)
    static func advance(_ seed: UInt64) -> UInt64 {
        return (seed &* 0x5DEECE66D &+ 0xB) & 0x0000_FFFF_FFFF_FFFF
    }

    static func recover(xpSeed1: Int32, xpSeed2: Int32) -> UInt64? {
        let seed1High = (UInt64(UInt32(bitPattern: xpSeed1)) << 16) & 0x0000_FFFF_FFFF_0000
        let seed2High = (UInt64(UInt32(bitPattern: xpSeed2)) << 16) & 0x0000_FFFF_FFFF_0000

        var low: UInt64 = 0
        while low < 65536 {
            let combined = seed1High | low
            let advanced = advance(combined)
            if (advanced & 0x0000_FFFF_FFFF_0000) == seed2High {
                return advanced & 0x0000_FFFF_FFFF_FFFF
            }
            low += 1
        }
        return nil
    }

    /// Formats a 48-bit seed the same way the desktop UI does (`%012X`).
    static func hex48(_ seed: UInt64) -> String {
        return String(format: "%012llX", seed & 0x0000_FFFF_FFFF_FFFF)
    }
}

// MARK: - Enchantment calculator

struct CalcSearchResult {
    /// -2 = impossible, -1 = no dummy enchantment needed, >= 0 = number of items to throw.
    let timesNeeded: Int
    let bookshelves: Int
    let slot: Int
}

/// Mirror of the `for (int i = -1; i <= 64 * 32; i++)` search loop in `EnchCrackerWindow`.
enum EnchantmentCalculator {

    static let maxItemsToThrow = 64 * 32

    static func search(playerSeed: UInt64,
                       item: String,
                       version: MCVersion,
                       maxBookshelves: Int,
                       playerLevel: Int,
                       wanted: [Enchantments.Instance],
                       unwanted: [Enchantments.Instance]) -> CalcSearchResult {

        guard Items.getEnchantability(item) > 0 else {
            return CalcSearchResult(timesNeeded: -2, bookshelves: 0, slot: 0)
        }

        var seed = playerSeed
        var i = -1
        var result = CalcSearchResult(timesNeeded: -2, bookshelves: 0, slot: 0)

        outer: while i <= maxItemsToThrow {
            let xpSeed: Int32
            if i == -1 {
                xpSeed = Int32(truncatingIfNeeded: seed >> 16)
            } else {
                xpSeed = Int32(truncatingIfNeeded: PlayerSeedCalculator.advance(seed) >> 16)
            }

            var rng = SimpleRandom()
            var bookshelves = 0
            while bookshelves <= maxBookshelves {
                rng.setSeed(xpSeed)
                var enchantLevels = [Int](repeating: 0, count: 3)
                var slotIndex = 0
                while slotIndex < 3 {
                    var level = Enchantments.calcEnchantmentTableLevel(&rng, slot: slotIndex,
                                                                      bookshelves: bookshelves, item: item)
                    if level < slotIndex + 1 { level = 0 }
                    enchantLevels[slotIndex] = level
                    slotIndex += 1
                }

                var slot = 0
                slotLoop: while slot < 3 {
                    let enchantments = Enchantments.getEnchantmentsInTable(
                        &rng, xpSeed: xpSeed, item: item, slot: slot,
                        levels: enchantLevels[slot], version: version)

                    if enchantLevels[slot] == 0 {
                        slot += 1
                        continue slotLoop
                    }
                    if i == -1 {
                        if playerLevel < enchantLevels[slot] {
                            slot += 1
                            continue slotLoop
                        }
                    } else if playerLevel < enchantLevels[slot] + 1 {
                        slot += 1
                        continue slotLoop
                    }

                    // every wanted enchantment must be present at >= the wanted level
                    for want in wanted {
                        var found = false
                        for ench in enchantments where ench.enchantment == want.enchantment {
                            if want.level > ench.level {
                                slot += 1
                                continue slotLoop
                            }
                            found = true
                            break
                        }
                        if !found {
                            slot += 1
                            continue slotLoop
                        }
                    }

                    // none of the unwanted enchantments may be present
                    for unwantedEnch in unwanted {
                        for ench in enchantments where ench.enchantment == unwantedEnch.enchantment {
                            slot += 1
                            continue slotLoop
                        }
                    }

                    result = CalcSearchResult(timesNeeded: i, bookshelves: bookshelves, slot: slot)
                    break outer
                }

                bookshelves += 1
            }

            // simulate throwing one item (four LCG steps)
            if i != -1 {
                var j = 0
                while j < 4 {
                    seed = PlayerSeedCalculator.advance(seed)
                    j += 1
                }
            }
            i += 1
        }

        return result
    }
}

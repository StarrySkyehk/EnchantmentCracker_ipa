import Foundation

/// Mirror of `enchcracker.Enchantments` — every version-dependent rule of the vanilla
/// enchanting table, transliterated from the original Java implementation.
enum Enchantments {

    // MARK: Enchantment ids

    static let protection = "protection"
    static let fireProtection = "fire_protection"
    static let featherFalling = "feather_falling"
    static let blastProtection = "blast_protection"
    static let projectileProtection = "projectile_protection"
    static let respiration = "respiration"
    static let aquaAffinity = "aqua_affinity"
    static let thorns = "thorns"
    static let depthStrider = "depth_strider"
    static let sharpness = "sharpness"
    static let smite = "smite"
    static let baneOfArthropods = "bane_of_arthropods"
    static let knockback = "knockback"
    static let fireAspect = "fire_aspect"
    static let looting = "looting"
    static let efficiency = "efficiency"
    static let silkTouch = "silk_touch"
    static let unbreaking = "unbreaking"
    static let fortune = "fortune"
    static let power = "power"
    static let punch = "punch"
    static let flame = "flame"
    static let infinity = "infinity"
    static let luckOfTheSea = "luck_of_the_sea"
    static let lure = "lure"
    static let frostWalker = "frost_walker"
    static let mending = "mending"
    static let bindingCurse = "binding_curse"
    static let vanishingCurse = "vanishing_curse"
    static let sweeping = "sweeping"
    static let loyalty = "loyalty"
    static let impaling = "impaling"
    static let riptide = "riptide"
    static let channeling = "channeling"
    static let multishot = "multishot"
    static let quickCharge = "quick_charge"
    static let piercing = "piercing"
    static let soulSpeed = "soul_speed"
    static let density = "density"
    static let breach = "breach"
    static let windBurst = "wind_burst"
    static let lunge = "lunge"

    /// `TABLE_ENCHANTMENTS`, in vanilla registry order (only these can come from a table).
    static let tableEnchantments: [String] = [
        protection, fireProtection, featherFalling, blastProtection, projectileProtection,
        respiration, aquaAffinity, thorns, depthStrider, sharpness, smite, baneOfArthropods,
        knockback, fireAspect, looting, sweeping, efficiency, silkTouch, unbreaking, fortune,
        power, punch, flame, infinity, luckOfTheSea, lure, loyalty, impaling, riptide,
        channeling, multishot, quickCharge, piercing, density, breach, lunge
    ]

    struct Instance: Hashable {
        let enchantment: String
        let level: Int
    }

    private static let names: [String: String] = [
        protection: "保护",
        fireProtection: "火焰保护",
        featherFalling: "摔落保护",
        blastProtection: "爆炸保护",
        projectileProtection: "投射物保护",
        respiration: "水下呼吸",
        aquaAffinity: "水下速掘",
        thorns: "荆棘",
        depthStrider: "深海探索者",
        sharpness: "锋利",
        smite: "亡灵杀手",
        baneOfArthropods: "节肢杀手",
        knockback: "击退",
        fireAspect: "火焰附加",
        looting: "掠夺",
        efficiency: "效率",
        silkTouch: "精准采集",
        unbreaking: "耐久",
        fortune: "时运",
        power: "力量",
        punch: "冲击",
        flame: "火矢",
        infinity: "无限",
        luckOfTheSea: "海之眷顾",
        lure: "饵钓",
        frostWalker: "冰霜行者",
        mending: "经验修补",
        bindingCurse: "绑定诅咒",
        vanishingCurse: "消失诅咒",
        sweeping: "横扫之刃",
        loyalty: "忠诚",
        impaling: "穿刺",
        riptide: "激流",
        channeling: "引雷",
        multishot: "多重射击",
        quickCharge: "快速装填",
        piercing: "穿透",
        soulSpeed: "灵魂疾行",
        density: "致密",
        breach: "破甲",
        windBurst: "风爆",
        lunge: "突刺",
    ]

    static func name(of id: String) -> String { names[id] ?? id }

    static func romanNumeral(_ level: Int) -> String {
        switch level {
        case 1: return "I"
        case 2: return "II"
        case 3: return "III"
        case 4: return "IV"
        case 5: return "V"
        default: return String(level)
        }
    }

    /// Same formatting as `EnchantmentInstance.toString()`.
    static func displayName(of instance: Instance) -> String {
        if instance.level == 1 && maxLevel(instance.enchantment) == 1 {
            return name(of: instance.enchantment)
        }
        return name(of: instance.enchantment) + " " + romanNumeral(instance.level)
    }

    // MARK: XP maths

    static func levelsToXP(_ startLevel: Int, _ numLevels: Int) -> Int {
        var amount = 0
        let endLevel = startLevel - numLevels
        var level = startLevel
        while level > endLevel {
            if level > 30 {
                amount += (9 * (level - 1)) - 158
            } else if level > 15 {
                amount += (5 * (level - 1)) - 38
            } else {
                amount += (2 * (level - 1)) + 7
            }
            level -= 1
        }
        return amount
    }

    // MARK: Applicability

    static func canApply(_ enchantment: String, _ item: String, _ primary: Bool) -> Bool {
        if item == Items.book { return true }

        switch enchantment {
        case protection, fireProtection, blastProtection, projectileProtection:
            return Items.isArmor(item)
        case thorns:
            return primary ? Items.isChestplate(item) : Items.isArmor(item)
        case featherFalling, depthStrider, frostWalker, soulSpeed:
            return Items.isBoots(item)
        case respiration, aquaAffinity:
            return Items.isHelmet(item)
        case bindingCurse:
            return Items.isArmor(item) || item == Items.pumpkin || item == Items.elytra
                || item == Items.skull
        case sharpness, smite, baneOfArthropods:
            return Items.isSword(item) || Items.isSpear(item)
                || (!primary && (Items.isAxe(item) || item == Items.mace))
        case fireAspect:
            return Items.isSword(item) || Items.isSpear(item) || (!primary && item == Items.mace)
        case knockback, looting:
            return Items.isSword(item) || Items.isSpear(item)
        case sweeping:
            return Items.isSword(item)
        case efficiency:
            return Items.isTool(item) || (!primary && item == Items.shears)
        case silkTouch, fortune:
            return Items.isTool(item)
        case power, punch, flame, infinity:
            return item == Items.bow
        case luckOfTheSea, lure:
            return item == Items.fishingRod
        case unbreaking, mending:
            return Items.hasDurability(item)
        case vanishingCurse:
            return Items.hasDurability(item) || item == Items.pumpkin || item == Items.skull
        case loyalty, impaling, riptide, channeling:
            return item == Items.trident
        case multishot, quickCharge, piercing:
            return item == Items.crossbow
        case density, breach, windBurst:
            return item == Items.mace
        case lunge:
            return Items.isSpear(item)
        default:
            return false
        }
    }

    // MARK: Per-enchantment tables

    static func maxLevel(_ enchantment: String) -> Int {
        switch enchantment {
        case sharpness, smite, baneOfArthropods, efficiency, power, impaling, density:
            return 5
        case protection, fireProtection, blastProtection, projectileProtection,
             featherFalling, piercing, breach:
            return 4
        case thorns, depthStrider, respiration, looting, sweeping, fortune, luckOfTheSea,
             lure, unbreaking, loyalty, riptide, quickCharge, soulSpeed, windBurst, lunge:
            return 3
        case frostWalker, knockback, fireAspect, punch:
            return 2
        case aquaAffinity, bindingCurse, silkTouch, flame, infinity, mending,
             vanishingCurse, channeling, multishot:
            return 1
        default:
            return 0
        }
    }

    static func minEnchantability(_ enchantment: String, _ level: Int) -> Int {
        switch enchantment {
        case protection: return 1 + (level - 1) * 11
        case fireProtection: return 10 + (level - 1) * 8
        case featherFalling: return 5 + (level - 1) * 6
        case blastProtection: return 5 + (level - 1) * 8
        case projectileProtection: return 3 + (level - 1) * 6
        case respiration: return level * 10
        case aquaAffinity: return 1
        case thorns: return 10 + (level - 1) * 20
        case depthStrider: return level * 10
        case frostWalker: return level * 10
        case bindingCurse: return 25
        case sharpness: return 1 + (level - 1) * 11
        case smite: return 5 + (level - 1) * 8
        case baneOfArthropods: return 5 + (level - 1) * 8
        case knockback: return 5 + (level - 1) * 20
        case fireAspect: return 10 + (level - 1) * 20
        case looting: return 15 + (level - 1) * 9
        case sweeping: return 5 + (level - 1) * 9
        case efficiency: return 1 + (level - 1) * 10
        case silkTouch: return 15
        case unbreaking: return 5 + (level - 1) * 8
        case fortune: return 15 + (level - 1) * 9
        case power: return 1 + (level - 1) * 10
        case punch: return 12 + (level - 1) * 20
        case flame: return 20
        case infinity: return 20
        case luckOfTheSea: return 15 + (level - 1) * 9
        case lure: return 15 + (level - 1) * 9
        case mending: return 25
        case vanishingCurse: return 25
        case loyalty: return 5 + level * 7
        case impaling: return 1 + (level - 1) * 8
        case riptide: return 10 + level * 7
        case channeling: return 25
        case multishot: return 20
        case quickCharge: return 12 + (level - 1) * 20
        case piercing: return 1 + (level - 1) * 10
        case soulSpeed: return level * 10
        case density: return 5 + (level - 1) * 8
        case breach: return 15 + (level - 1) * 9
        case windBurst: return 15 + (level - 1) * 9
        case lunge: return 5 + (level - 1) * 8
        default: return 0
        }
    }

    static func maxEnchantability(_ enchantment: String, _ level: Int) -> Int {
        switch enchantment {
        case protection: return 1 + level * 11
        case fireProtection: return 10 + level * 8
        case featherFalling: return 5 + level * 6
        case blastProtection: return 5 + level * 8
        case projectileProtection: return 3 + level * 6
        case respiration: return 30 + level * 10
        case aquaAffinity: return 41
        case thorns: return 40 + level * 20
        case depthStrider: return 15 + level * 10
        case frostWalker: return 15 + level * 10
        case bindingCurse: return 50
        case sharpness: return 21 + (level - 1) * 11
        case smite: return 25 + (level - 1) * 8
        case baneOfArthropods: return 25 + (level - 1) * 8
        case knockback: return 55 + (level - 1) * 20
        case fireAspect: return 40 + level * 20
        case looting: return 65 + (level - 1) * 9
        case sweeping: return 20 + (level - 1) * 9
        case efficiency: return 50 + level * 10
        case silkTouch: return 65
        case unbreaking: return 55 + (level - 1) * 8
        case fortune: return 65 + (level - 1) * 9
        case power: return 16 + (level - 1) * 10
        case punch: return 37 + (level - 1) * 20
        case flame: return 50
        case infinity: return 50
        case luckOfTheSea: return 65 + (level - 1) * 9
        case lure: return 65 + (level - 1) * 9
        case mending: return 75
        case vanishingCurse: return 50
        case loyalty: return 50
        case impaling: return 21 + (level - 1) * 8
        case riptide: return 50
        case channeling: return 50
        case multishot: return 50
        case quickCharge: return 50
        case piercing: return 50
        case soulSpeed: return 15 + level * 10
        case density: return 25 + (level - 1) * 8
        case breach: return 65 + (level - 1) * 9
        case windBurst: return 65 + (level - 1) * 9
        case lunge: return 25 + (level - 1) * 8
        default: return 0
        }
    }

    static func weight(_ enchantment: String, _ version: MCVersion) -> Int {
        switch enchantment {
        case protection, sharpness, efficiency, power, piercing:
            return version == .v1_14 ? 30 : 10
        case fireProtection, featherFalling, projectileProtection, smite, baneOfArthropods,
             knockback, unbreaking, loyalty, quickCharge, density, lunge:
            return version == .v1_14 ? 10 : 5
        case blastProtection, respiration, aquaAffinity, depthStrider, frostWalker, fireAspect,
             looting, sweeping, fortune, punch, flame, luckOfTheSea, lure, mending, impaling,
             riptide, multishot, breach, windBurst:
            return version == .v1_14 ? 3 : 2
        case thorns, bindingCurse, silkTouch, infinity, vanishingCurse, channeling, soulSpeed:
            return 1
        default:
            return 1
        }
    }

    static func introducedVersion(_ enchantment: String) -> MCVersion {
        switch enchantment {
        case frostWalker, mending: return .v1_9
        case bindingCurse, vanishingCurse: return .v1_11
        case sweeping: return .v1_11_1
        case loyalty, impaling, riptide, channeling: return .v1_13
        case multishot, quickCharge, piercing: return .v1_14
        case soulSpeed: return .v1_16
        case density, breach, windBurst: return .v1_21
        case lunge: return .v1_21_11
        default: return .v1_8
        }
    }

    // MARK: Compatibility

    private static let damageEnchantments: Set<String> = [sharpness, smite, baneOfArthropods, density, breach]
    private static let protectionEnchantments: Set<String> = [protection, blastProtection, fireProtection, projectileProtection]

    static func areCompatible(_ enchA: String, _ enchB: String, _ version: MCVersion) -> Bool {
        // every enchantment with itself
        if enchA == enchB { return false }
        // infinity with mending
        if !version.before(.v1_11_1) && enchA == infinity && enchB == mending { return false }
        // damage enchantments
        if damageEnchantments.contains(enchA) && damageEnchantments.contains(enchB) { return false }
        // depth strider with frost walker
        if enchA == depthStrider && enchB == frostWalker { return false }
        // silk touch with looting / fortune / luck of the sea
        if enchA == silkTouch && (enchB == looting || enchB == fortune || enchB == luckOfTheSea) { return false }
        // riptide with loyalty / channeling
        if enchA == riptide && (enchB == loyalty || enchB == channeling) { return false }
        // multishot with piercing
        if enchA == multishot && enchB == piercing { return false }
        // protection enchantments (1.14 allowed all of them together)
        if version != .v1_14 && protectionEnchantments.contains(enchA) && protectionEnchantments.contains(enchB) {
            return false
        }
        return true
    }

    // MARK: Table simulation

    /// Mirror of `Enchantments.getMaxLevelInTable`.
    static func maxLevelInTable(_ enchantment: String, _ item: String) -> Int {
        let enchantability = Items.getEnchantability(item)
        if enchantability == 0 || !tableEnchantments.contains(enchantment)
            || !canApply(enchantment, item, true) {
            return 0
        }
        var level = 30 + 1 + enchantability / 4 + enchantability / 4
        level += javaRound(Float(level) * 0.15)
        var maxLvl = maxLevel(enchantment)
        while maxLvl >= 1 {
            if level >= minEnchantability(enchantment, maxLvl) {
                return maxLvl
            }
            maxLvl -= 1
        }
        return 0
    }

    static func calcEnchantmentTableLevel(_ rand: inout SimpleRandom, slot: Int, bookshelves: Int, item: String) -> Int {
        if Items.getEnchantability(item) == 0 { return 0 }
        let level = rand.nextInt(8) + 1 + (bookshelves >> 1) + rand.nextInt(bookshelves + 1)
        switch slot {
        case 0:
            return max(level / 3, 1)
        case 1:
            return level * 2 / 3 + 1
        case 2:
            return max(level, bookshelves * 2)
        default:
            return 0
        }
    }

    static func highestAllowedEnchantments(level: Int, item: String, version: MCVersion) -> [Instance] {
        var allowed: [Instance] = []
        if version.before(Items.getIntroducedVersion(item)) { return allowed }

        for enchantment in tableEnchantments {
            if version.before(introducedVersion(enchantment)) { continue }
            if canApply(enchantment, item, true) {
                var lvl = maxLevel(enchantment)
                while lvl >= 1 {
                    if level >= minEnchantability(enchantment, lvl)
                        && level <= maxEnchantability(enchantment, lvl) {
                        allowed.append(Instance(enchantment: enchantment, level: lvl))
                        break
                    }
                    lvl -= 1
                }
            }
        }
        return allowed
    }

    private static func weightedRandom(_ rand: inout SimpleRandom, _ list: [Instance],
                                       _ version: MCVersion) -> Instance? {
        var weight = 0
        for instance in list { weight += self.weight(instance.enchantment, version) }
        if weight <= 0 { return nil }
        weight = rand.nextInt(weight)
        for instance in list {
            weight -= self.weight(instance.enchantment, version)
            if weight < 0 { return instance }
        }
        return nil
    }

    static func addRandomEnchantments(_ rand: inout SimpleRandom, item: String, level: Int,
                                      version: MCVersion) -> [Instance] {
        let enchantability = Items.getEnchantability(item)
        var enchantments: [Instance] = []
        guard enchantability > 0 else { return enchantments }

        var enchLevel = level + 1 + rand.nextInt(enchantability / 4 + 1) + rand.nextInt(enchantability / 4 + 1)
        let percentChange = (rand.nextFloat() + rand.nextFloat() - 1) * 0.15
        enchLevel += javaRound(Float(enchLevel) * percentChange)
        if enchLevel < 1 { enchLevel = 1 }

        var allowed = highestAllowedEnchantments(level: enchLevel, item: item, version: version)
        if !allowed.isEmpty {
            if let first = weightedRandom(&rand, allowed, version) {
                enchantments.append(first)
            }

            while rand.nextInt(50) <= enchLevel {
                if version == .v1_14 {
                    enchLevel = enchLevel * 4 / 5 + 1
                    allowed = highestAllowedEnchantments(level: enchLevel, item: item, version: version)
                }

                // Remove enchantments incompatible with anything chosen so far.
                allowed = allowed.filter { candidate in
                    for chosen in enchantments {
                        if !areCompatible(candidate.enchantment, chosen.enchantment, version) { return false }
                    }
                    return true
                }

                if allowed.isEmpty { break }

                if let extra = weightedRandom(&rand, allowed, version) {
                    enchantments.append(extra)
                }

                enchLevel /= 2
            }
        }
        return enchantments
    }

    static func getEnchantmentsInTable(_ rand: inout SimpleRandom, xpSeed: Int32, item: String,
                                       slot: Int, levels: Int, version: MCVersion) -> [Instance] {
        rand.setSeed(xpSeed &+ Int32(slot))
        var list = addRandomEnchantments(&rand, item: item, level: levels, version: version)
        if item == Items.book && list.count > 1 {
            let index = rand.nextInt(list.count)
            list.remove(at: index)
        }
        return list
    }
}

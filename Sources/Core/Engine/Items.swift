import Foundation

// MARK: - Materials (mirror of enchcracker.Materials, plus the "misc" row of the picker)

enum ItemMaterial: Int, CaseIterable, Identifiable, Hashable {
    case netherite = 0
    case diamond
    case gold
    case iron
    case copper
    case chain
    case stone
    case leather
    case misc

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .netherite: return "下界合金"
        case .diamond: return "钻石"
        case .gold: return "金"
        case .iron: return "铁"
        case .copper: return "铜"
        case .chain: return "锁链"
        case .stone: return "石"
        case .leather: return "皮革"
        case .misc: return "其他"
        }
    }

    /// Mirror of `Materials.getIntroducedVersion`.
    var introducedVersion: MCVersion {
        switch self {
        case .copper: return .v1_21_9
        case .netherite: return .v1_16
        default: return .v1_8
        }
    }
}

// MARK: - Items (mirror of enchcracker.Items, which uses plain String ids)

enum Items {
    static let book = "book"
    static let bow = "bow"
    static let crossbow = "crossbow"
    static let trident = "trident"
    static let mace = "mace"
    static let fishingRod = "fishing_rod"
    static let elytra = "elytra"
    static let shield = "shield"
    static let shears = "shears"
    static let flintAndSteel = "flint_and_steel"
    static let carrotOnAStick = "carrot_on_a_stick"
    static let pumpkin = "pumpkin"
    static let skull = "skull"

    private static let armorMaterials: Set<String> = [
        "leather", "iron", "chainmail", "golden", "diamond", "turtle", "netherite", "copper"
    ]

    /// Materials that have tools / swords / spears.
    private static let toolMaterials: Set<String> = [
        "wooden", "stone", "iron", "golden", "diamond", "netherite", "copper"
    ]

    @inline(__always)
    static func prefix(of item: String) -> String {
        guard let idx = item.firstIndex(of: "_") else { return "" }
        return String(item[item.startIndex..<idx])
    }

    static func isArmor(_ item: String) -> Bool {
        let suffixes = ["_helmet", "_chestplate", "_leggings", "_boots"]
        guard suffixes.contains(where: { item.hasSuffix($0) }) else { return false }
        return armorMaterials.contains(prefix(of: item))
    }

    static func isHelmet(_ item: String) -> Bool { isArmor(item) && item.hasSuffix("_helmet") }
    static func isChestplate(_ item: String) -> Bool { isArmor(item) && item.hasSuffix("_chestplate") }
    static func isLeggings(_ item: String) -> Bool { isArmor(item) && item.hasSuffix("_leggings") }
    static func isBoots(_ item: String) -> Bool { isArmor(item) && item.hasSuffix("_boots") }

    static func isSword(_ item: String) -> Bool {
        guard item.hasSuffix("_sword") else { return false }
        return toolMaterials.contains(prefix(of: item))
    }

    static func isSpear(_ item: String) -> Bool {
        guard item.hasSuffix("_spear") else { return false }
        return toolMaterials.contains(prefix(of: item))
    }

    static func isAxe(_ item: String) -> Bool {
        guard item.hasSuffix("_axe") else { return false }
        return toolMaterials.contains(prefix(of: item))
    }

    static func isTool(_ item: String) -> Bool {
        if isAxe(item) { return true }
        let suffixes = ["_pickaxe", "_shovel", "_hoe"]
        guard suffixes.contains(where: { item.hasSuffix($0) }) else { return false }
        return toolMaterials.contains(prefix(of: item))
    }

    static func hasDurability(_ item: String) -> Bool {
        if isArmor(item) || isTool(item) || isSword(item) || isSpear(item) { return true }
        switch item {
        case bow, carrotOnAStick, elytra, fishingRod, flintAndSteel, shears, shield, trident, crossbow, mace:
            return true
        default:
            return false
        }
    }

    /// Mirror of `Items.getEnchantability`.
    static func getEnchantability(_ item: String) -> Int {
        if isArmor(item) {
            switch prefix(of: item) {
            case "leather": return 15
            case "iron": return 9
            case "chainmail": return 12
            case "golden": return 25
            case "diamond": return 10
            case "turtle": return 9
            case "netherite": return 15
            case "copper": return 8
            default: return 0
            }
        }
        if isSword(item) || isSpear(item) || isTool(item) {
            switch prefix(of: item) {
            case "wooden": return 15
            case "stone": return 5
            case "iron": return 14
            case "golden": return 22
            case "diamond": return 10
            case "netherite": return 15
            case "copper": return 13
            default: return 0
            }
        }
        switch item {
        case bow: return 1
        case fishingRod: return 1
        case trident: return 1
        case crossbow: return 1
        case mace: return 15
        case book: return 1
        default: return 0
        }
    }

    /// Mirror of `Items.getIntroducedVersion`.
    static func getIntroducedVersion(_ item: String) -> MCVersion {
        switch item {
        case elytra, shield:
            return .v1_9
        case trident, "turtle_helmet":
            return .v1_13
        case crossbow:
            return .v1_14
        case "netherite_helmet", "netherite_chestplate", "netherite_leggings", "netherite_boots",
             "netherite_sword", "netherite_pickaxe", "netherite_axe", "netherite_shovel", "netherite_hoe":
            return .v1_16
        case mace:
            return .v1_21
        case "copper_helmet", "copper_chestplate", "copper_leggings", "copper_boots",
             "copper_sword", "copper_pickaxe", "copper_axe", "copper_shovel", "copper_hoe":
            return .v1_21_9
        case "netherite_spear", "diamond_spear", "golden_spear", "iron_spear",
             "copper_spear", "stone_spear", "wooden_spear":
            return .v1_21_11
        default:
            return .v1_8
        }
    }
}

// MARK: - Item catalogue for the picker UI (the 9 rows of the original item grid)

struct MCItem: Identifiable, Hashable {
    let id: String
    let displayName: String
    let material: ItemMaterial
}

enum ItemCatalog {
    private static let typeNames: [String: String] = [
        "sword": "剑", "pickaxe": "镐", "axe": "斧", "shovel": "锹", "hoe": "锄",
        "spear": "矛", "helmet": "头盔", "chestplate": "胸甲", "leggings": "护腿", "boots": "靴子"
    ]

    private static let materialNames: [String: String] = [
        "netherite": "下界合金", "diamond": "钻石", "golden": "金", "iron": "铁",
        "copper": "铜", "chainmail": "锁链", "stone": "石", "leather": "皮革",
        "turtle": "海龟", "wooden": "木质"
    ]

    private static func item(_ id: String, _ material: ItemMaterial) -> MCItem {
        let p = Items.prefix(of: id)
        let t = String(id.dropFirst(p.count + 1))
        let materialName = materialNames[p] ?? ""
        let name = materialName + (typeNames[t] ?? t)
        return MCItem(id: id, displayName: name, material: material)
    }

    private static func set(_ prefix: String, _ material: ItemMaterial) -> [MCItem] {
        return ["sword", "pickaxe", "axe", "shovel", "hoe", "spear",
                "helmet", "chestplate", "leggings", "boots"].map { item(prefix + "_" + $0, material) }
    }

    /// All items, in the same row order as the original desktop item picker.
    static let all: [MCItem] = {
        var result: [MCItem] = []
        result += set("netherite", .netherite)
        result += set("diamond", .diamond)
        result += set("golden", .gold)
        result += set("iron", .iron)
        result += set("copper", .copper)
        // chainmail row: iron tools, chainmail armour
        result += ["iron_sword", "iron_pickaxe", "iron_axe", "iron_shovel", "iron_hoe",
                   "iron_spear", "chainmail_helmet", "chainmail_chestplate",
                   "chainmail_leggings", "chainmail_boots"].map { item($0, .chain) }
        // stone row: stone tools, turtle helmet + leather armour
        result += ["stone_sword", "stone_pickaxe", "stone_axe", "stone_shovel", "stone_hoe",
                   "stone_spear", "turtle_helmet", "leather_chestplate",
                   "leather_leggings", "leather_boots"].map { item($0, .stone) }
        // leather row: wooden tools, leather armour
        result += ["wooden_sword", "wooden_pickaxe", "wooden_axe", "wooden_shovel", "wooden_hoe",
                   "wooden_spear", "leather_helmet", "leather_chestplate",
                   "leather_leggings", "leather_boots"].map { item($0, .leather) }
        result += [
            MCItem(id: "bow", displayName: "弓", material: .misc),
            MCItem(id: "fishing_rod", displayName: "钓鱼竿", material: .misc),
            MCItem(id: "crossbow", displayName: "弩", material: .misc),
            MCItem(id: "trident", displayName: "三叉戟", material: .misc),
            MCItem(id: "mace", displayName: "重锤", material: .misc),
            MCItem(id: "book", displayName: "书", material: .misc),
        ]
        return result
    }()

    private static let byID: [String: MCItem] = {
        var d: [String: MCItem] = [:]
        for i in all { d[i.id] = i }
        return d
    }()

    static func item(id: String) -> MCItem? { byID[id] }

    /// Items of a material that exist in `version`.
    static func items(for material: ItemMaterial, version: MCVersion) -> [MCItem] {
        return all.filter { $0.material == material && !version.before(Items.getIntroducedVersion($0.id)) }
    }

    /// Materials that have at least one item in `version`.
    static func materials(in version: MCVersion) -> [ItemMaterial] {
        return ItemMaterial.allCases.filter { m in
            !version.before(m.introducedVersion) && !items(for: m, version: version).isEmpty
        }
    }
}

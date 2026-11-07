import Foundation
import Combine

/// How much memory the cracker may spend on storing candidate seeds (4 bytes each).
let crackerMemoryBudget = 32_000_000

enum CrackStatus: Equatable {
    case idle
    case running
    case possible(Int)
    case found(Int32)
    case impossible
}

struct EnchantOption: Identifiable, Hashable {
    let id: String
    let name: String
    let maxLevel: Int
}

struct CalcResult: Equatable {
    let possible: Bool
    let timesNeeded: Int
    let bookshelves: Int
    let slot: Int
    var dropText: String
    var slotText: String
    var bookshelvesText: String
}

/// The whole app state: XP-seed cracking tab plus the enchantment-calculator tab.
final class CrackerModel: ObservableObject {

    // MARK: Cracker inputs

    @Published var version: MCVersion = .latest {
        didSet { revalidateSelection() }
    }
    @Published var bookshelvesText: String = "15"
    @Published var slot1Text: String = ""
    @Published var slot2Text: String = ""
    @Published var slot3Text: String = ""

    // MARK: Cracker status

    @Published var status: CrackStatus = .idle
    @Published var isCracking: Bool = false
    @Published var progress: Double = 0
    @Published var progressText: String = ""
    @Published var statusTitle: String = "输入书架数量和三个附魔格对应的等级，然后点「检查」"
    @Published var statusDetail: String = ""
    @Published var possibleSeeds: Int = 0
    @Published var foundSeed: Int32? = nil

    // MARK: XP seed / player seed

    @Published var xpSeed1Text: String = ""
    @Published var xpSeed2Text: String = ""
    @Published var playerSeedText: String = ""
    @Published var playerSeedStatus: String = ""

    // MARK: Calculator inputs

    @Published var material: ItemMaterial = .diamond {
        didSet { revalidateItem() }
    }
    @Published var itemID: String = "diamond_sword" {
        didSet {
            targets = [:]
            calcResult = nil
            calcMessage = ""
        }
    }
    @Published var maxBookshelvesText: String = "15" {
        didSet { calcResult = nil }
    }
    @Published var playerLevelText: String = "999" {
        didSet { calcResult = nil }
    }
    @Published var targets: [String: Int] = [:]
    @Published var calcResult: CalcResult? = nil
    @Published var calcMessage: String = ""
    @Published var isCalculating: Bool = false

    // MARK: Private state

    private let cracker = SeedCracker()
    private var progressTimer: Timer?

    init() {
        if ProcessInfo.processInfo.arguments.contains("-autocrack") {
            // Debug/simulator end-to-end test: run a real 2^32 scan shortly after launch.
            bookshelvesText = "15"
            slot1Text = "5"
            slot2Text = "11"
            slot3Text = "30"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.check()
            }
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-demo") {
            bookshelvesText = "15"
            slot1Text = "5"
            slot2Text = "11"
            slot3Text = "30"
            statusTitle = "可能的种子数：1.01 亿个"
            statusDetail = "换一个书架数量再点「检查」继续缩小范围"
            status = .possible(100_663_118)
            possibleSeeds = 100_663_118
            playerSeedText = "1A2B3C4D5E6F"
            xpSeed1Text = "12345678"
            xpSeed2Text = "87654321"
            targets = ["sharpness": 3, "smite": -1]
        }
    }

    deinit {
        progressTimer?.invalidate()
    }

    // MARK: - Derived

    var availableMaterials: [ItemMaterial] {
        return ItemCatalog.materials(in: version)
    }

    var itemOptions: [MCItem] {
        return ItemCatalog.items(for: material, version: version)
    }

    /// The enchantments the currently selected item can possibly get from a table,
    /// with the maximum table level for each — same list the desktop item picker builds.
    var enchantOptions: [EnchantOption] {
        guard let item = ItemCatalog.item(id: itemID) else { return [] }
        let enchantability = Items.getEnchantability(item.id)
        var level = 30 + 1 + enchantability / 4 + enchantability / 4
        level += javaRound(Float(level) * 1.15)
        if level < 1 { level = 1 }

        var ids: [String] = []
        while level > 0 {
            for instance in Enchantments.highestAllowedEnchantments(level: level, item: item.id, version: version) {
                if !ids.contains(instance.enchantment) {
                    ids.append(instance.enchantment)
                }
            }
            level -= 5
        }
        let registryOrder = Dictionary(uniqueKeysWithValues:
            Enchantments.tableEnchantments.enumerated().map { ($1, $0) })
        ids.sort { (registryOrder[$0] ?? Int.max) < (registryOrder[$1] ?? Int.max) }

        return ids.map { id in
            EnchantOption(id: id,
                          name: Enchantments.name(of: id),
                          maxLevel: max(1, Enchantments.maxLevelInTable(id, item.id)))
        }
    }

    var isSeedKnown: Bool {
        return playerSeedValue != nil || foundSeed != nil
    }

    var canCheck: Bool {
        return !isCracking
    }

    var playerSeedValue: UInt64? {
        let text = playerSeedText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !text.isEmpty, text.count <= 12, let value = UInt64(text, radix: 16) else { return nil }
        return value & 0x0000_FFFF_FFFF_FFFF
    }

    /// A checked seed can be turned into a player seed automatically when unique.
    var currentXPSeedHex: String? {
        if let seed = foundSeed {
            return String(format: "%08X", UInt32(bitPattern: seed))
        }
        return nil
    }

    // MARK: - Cracker actions

    func check() {
        guard !isCracking else { return }

        guard let bookshelves = parseInt(bookshelvesText), (0...15).contains(bookshelves) else {
            failInput("书架数量必须是 0 到 15 之间的整数")
            return
        }
        guard let slot1 = parseInt(slot1Text), (0...30).contains(slot1) else {
            failInput("第 1 个附魔等级必须是 0 到 30 之间的整数")
            return
        }
        guard let slot2 = parseInt(slot2Text), (0...30).contains(slot2) else {
            failInput("第 2 个附魔等级必须是 0 到 30 之间的整数")
            return
        }
        guard let slot3 = parseInt(slot3Text), (0...30).contains(slot3) else {
            failInput("第 3 个附魔等级必须是 0 到 30 之间的整数")
            return
        }

        let observation = SeedObservation(bookshelves: bookshelves, slot1: slot1, slot2: slot2, slot3: slot3)

        status = .running
        isCracking = true
        progress = 0
        progressText = "进度：0%"
        statusTitle = "正在扫描全部 2³² 个种子…"
        statusDetail = "第一次检查需要完整扫描，约需 5-20 秒"
        startProgressTimer()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.cracker.add(observation: observation, memoryBudget: crackerMemoryBudget)
            DispatchQueue.main.async {
                self.finishCrack(result)
            }
        }
    }

    func cancelCrack() {
        cracker.requestAbort()
    }

    func resetCracker() {
        cracker.requestAbort()
        cracker.reset()
        stopProgressTimer()
        isCracking = false
        progress = 0
        progressText = ""
        status = .idle
        possibleSeeds = 0
        foundSeed = nil
        bookshelvesText = "15"
        slot1Text = ""
        slot2Text = ""
        slot3Text = ""
        statusTitle = "输入书架数量和三个附魔格对应的等级，然后点「检查」"
        statusDetail = ""
    }

    private func failInput(_ message: String) {
        status = .idle
        statusTitle = message
        statusDetail = ""
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        let timer = Timer(timeInterval: 0.12, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        guard isCracking else { return }
        let scanned = cracker.scannedSeeds
        let fraction = Double(scanned) / Double(SeedCracker.totalSeeds)
        progress = min(1.0, max(0.0, fraction))
        progressText = "进度：\(Int(progress * 100))%   " + CrackerModel.formatBigNumber(scanned) + " / 4.29B"
    }

    private func finishCrack(_ result: CrackScanResult) {
        stopProgressTimer()
        isCracking = false

        if result.aborted {
            status = .idle
            progress = 0
            progressText = ""
            statusTitle = "已取消扫描"
            statusDetail = "点「检查」可以重新开始"
            return
        }

        progress = 1
        progressText = ""
        possibleSeeds = result.matchingSeeds
        // The same numbers must not be submitted twice in a row, so clear the level fields.
        slot1Text = ""
        slot2Text = ""
        slot3Text = ""

        if result.matchingSeeds == 0 {
            foundSeed = nil
            status = .impossible
            statusTitle = "找不到可能的XP种子"
            statusDetail = "请确认输入的三个等级与书架数量是否正确"
            return
        }

        if let candidates = result.candidates, candidates.count == 1 {
            let seed = candidates[0]
            foundSeed = seed
            status = .found(seed)
            statusTitle = "XP种子：" + String(format: "%08X", UInt32(bitPattern: seed))
            statusDetail = "种子已唯一确定，可以填到下面的 XP种子 里计算玩家种子"
            let hex = String(format: "%08X", UInt32(bitPattern: seed))
            if xpSeed1Text.isEmpty {
                xpSeed1Text = hex
            } else if xpSeed2Text.isEmpty {
                xpSeed2Text = hex
            }
            return
        }

        foundSeed = nil
        status = .possible(result.matchingSeeds)
        statusTitle = "可能的种子数：" + CrackerModel.formatSeedCount(result.matchingSeeds)
        if result.candidates == nil {
            statusDetail = "换一个书架数量再点「检查」继续缩小范围（会重新完整扫描）"
        } else {
            statusDetail = "换一个书架数量再点「检查」继续缩小范围"
        }
    }

    // MARK: - Player seed

    func calculatePlayerSeed() {
        guard let seed1 = parseHex32(xpSeed1Text), let seed2 = parseHex32(xpSeed2Text) else {
            playerSeedStatus = "Fail!"
            playerSeedText = ""
            return
        }
        if let seed = PlayerSeedCalculator.recover(xpSeed1: seed1, xpSeed2: seed2) {
            playerSeedText = PlayerSeedCalculator.hex48(seed)
            playerSeedStatus = "Success!"
        } else {
            playerSeedText = ""
            playerSeedStatus = "Fail!"
        }
    }

    // MARK: - Calculator

    func selectMaterial(_ newMaterial: ItemMaterial) {
        material = newMaterial
        let items = itemOptions
        guard let current = ItemCatalog.item(id: itemID) else {
            itemID = items.first?.id ?? itemID
            return
        }
        // keep the same item type when switching material (diamond_sword -> netherite_sword)
        let suffix = current.id.hasPrefix(Items.prefix(of: current.id) + "_")
            ? String(current.id.dropFirst(Items.prefix(of: current.id).count + 1))
            : current.id
        if let sameType = items.first(where: { $0.id.hasSuffix("_" + suffix) }) {
            itemID = sameType.id
        } else {
            itemID = items.first?.id ?? itemID
        }
    }

    func selectItem(_ id: String) {
        guard ItemCatalog.item(id: id) != nil else { return }
        itemID = id
    }

    func setTarget(_ enchantmentID: String, level: Int) {
        let maxLevel = Enchantments.maxLevelInTable(enchantmentID, itemID)
        let clamped = max(-1, min(level, maxLevel))
        calcResult = nil
        calcMessage = ""
        if clamped == 0 {
            targets.removeValue(forKey: enchantmentID)
        } else {
            targets[enchantmentID] = clamped
        }
    }

    func runCalculator() {
        guard !isCalculating else { return }
        calcResult = nil
        calcMessage = ""

        guard let playerSeed = playerSeedValue else {
            calcMessage = "请先破解出玩家种子（第一个标签页）"
            return
        }
        guard let maxShelves = parseInt(maxBookshelvesText), (0...15).contains(maxShelves) else {
            calcMessage = "最大书架数量必须是 0 到 15 之间的整数"
            return
        }
        guard let playerLevel = parseInt(playerLevelText), playerLevel >= 1 else {
            calcMessage = "玩家等级必须是正整数"
            return
        }

        var wanted: [Enchantments.Instance] = []
        var unwanted: [Enchantments.Instance] = []
        for option in enchantOptions {
            guard let value = targets[option.id] else { continue }
            if value >= 1 {
                wanted.append(Enchantments.Instance(enchantment: option.id, level: value))
            } else if value == -1 {
                unwanted.append(Enchantments.Instance(enchantment: option.id, level: 1))
            }
        }
        guard !wanted.isEmpty || !unwanted.isEmpty else {
            calcMessage = "请至少选择一个目标附魔（或标记为「不要」）"
            return
        }

        let item = itemID
        let version = self.version
        isCalculating = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = EnchantmentCalculator.search(playerSeed: playerSeed,
                                                      item: item,
                                                      version: version,
                                                      maxBookshelves: maxShelves,
                                                      playerLevel: playerLevel,
                                                      wanted: wanted,
                                                      unwanted: unwanted)
            DispatchQueue.main.async {
                self.finishCalculate(result)
            }
        }
    }

    private func finishCalculate(_ result: CalcSearchResult) {
        isCalculating = false
        guard result.timesNeeded != -2 else {
            calcResult = nil
            calcMessage = "没有匹配的结果：在当前等级和书架数量下找不到想要的附魔组合"
            return
        }

        var dropText: String
        if result.timesNeeded == -1 {
            dropText = "不需要"
        } else if result.timesNeeded > 63 {
            dropText = "64×\(result.timesNeeded / 64) + \(result.timesNeeded % 64)"
        } else {
            dropText = String(result.timesNeeded)
        }

        calcResult = CalcResult(possible: true,
                                timesNeeded: result.timesNeeded,
                                bookshelves: result.bookshelves,
                                slot: result.slot,
                                dropText: dropText,
                                slotText: String(result.slot + 1),
                                bookshelvesText: String(result.bookshelves))
        calcMessage = ""
    }

    /// The "完成" button: consume the calculated result, advancing the player seed and level.
    func applyResult() {
        guard let result = calcResult, result.possible, let seed = playerSeedValue else { return }

        var currentSeed = seed
        if result.timesNeeded != -1 {
            var i = 0
            while i < result.timesNeeded {
                var j = 0
                while j < 4 {
                    currentSeed = PlayerSeedCalculator.advance(currentSeed)
                    j += 1
                }
                i += 1
            }
            // the dummy enchantment
            currentSeed = PlayerSeedCalculator.advance(currentSeed)
        }
        // the real enchantment
        currentSeed = PlayerSeedCalculator.advance(currentSeed)

        if var level = parseInt(playerLevelText) {
            if result.timesNeeded != -1 {
                level -= 1
            }
            level -= (result.slot + 1)
            playerLevelText = String(level)
        }
        playerSeedText = PlayerSeedCalculator.hex48(currentSeed)
        playerSeedStatus = ""

        calcResult = nil
        calcMessage = ""
    }

    func resetCalculator() {
        targets = [:]
        calcResult = nil
        calcMessage = ""
    }

    // MARK: - Selection housekeeping

    private func revalidateSelection() {
        let materials = availableMaterials
        if !materials.contains(material) {
            material = materials.first ?? .diamond
        } else {
            revalidateItem()
        }
    }

    private func revalidateItem() {
        let items = ItemCatalog.items(for: material, version: version)
        if !items.contains(where: { $0.id == itemID }) {
            if let preferred = items.first {
                itemID = preferred.id
            }
        }
    }

    // MARK: - Number parsing / formatting helpers

    private func parseInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    private func parseHex32(_ text: String) -> Int32? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty, trimmed.count <= 8, let value = UInt32(trimmed, radix: 16) else { return nil }
        return Int32(bitPattern: value)
    }

    static func formatSeedCount(_ value: Int) -> String {
        if value >= 100_000_000 {
            return trimNumber(Double(value) / 100_000_000.0, decimals: 2) + " 亿个"
        }
        if value >= 10_000 {
            return trimNumber(Double(value) / 10_000.0, decimals: 1) + " 万个"
        }
        return "\(value) 个"
    }

    static func formatBigNumber(_ value: Int64) -> String {
        if value >= 1_000_000_000 {
            return trimNumber(Double(value) / 1_000_000_000.0, decimals: 2) + "B"
        }
        if value >= 1_000_000 {
            return trimNumber(Double(value) / 1_000_000.0, decimals: 2) + "M"
        }
        if value >= 1_000 {
            return trimNumber(Double(value) / 1_000.0, decimals: 1) + "K"
        }
        return "\(value)"
    }

    private static func trimNumber(_ value: Double, decimals: Int) -> String {
        var text = String(format: "%.\(decimals)f", value)
        while text.contains(".") && (text.hasSuffix("0") || text.hasSuffix(".")) {
            text.removeLast()
        }
        return text
    }
}

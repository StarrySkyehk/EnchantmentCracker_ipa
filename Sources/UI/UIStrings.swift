import Foundation

/// Every user-facing string, copied from the original desktop app's Chinese
/// resource bundle (`resources/i18n/EnchantmentCracker_zh.properties`).
/// Strings that only exist as labels inside the original artwork are translated
/// here in the same style.
enum L {

    // MARK: - App / tabs

    static let appName = "Enchantment Cracker"
    static let appNameCN = "附魔破解器"

    static let tabCracker = "附魔破解器"
    static let tabCalculator = "附魔计算器"
    static let tabAbout = "关于"

    // MARK: - Enchantment cracker tab

    static let gameVersion = "游戏版本"
    static let versionHint = "选择你正在游玩的 Minecraft 版本"
    static let switchVersion = "切换"
    static let crackerHint = "破解 XP 种子，推算出玩家种子"
    static let calculatorHint = "算出还要丢几件物品才能附到想要的魔咒"
    static let inputData = "附魔台数据"

    static let bookshelves = "书架"
    static let bookshelvesTooltip = "附魔台周围的有效书架数量"

    static let slot1 = "第 1 格"
    static let slot2 = "第 2 格"
    static let slot3 = "第 3 格"

    static let xpCost1Tooltip = "第一个附魔所需的经验等级"
    static let xpCost2Tooltip = "第二个附魔所需的经验等级"
    static let xpCost3Tooltip = "第三个附魔所需的经验等级"

    static let check = "检查"
    static let checkTooltip = "使用这个功能来找到可能的XP种子"
    static let cancel = "取消"
    static let progressPrefix = "进度"

    static let statusSection = "破解状态"

    static let playerSeedSection = "计算玩家种子"
    static let playerSeedSectionHint = "连续两次打开附魔台，把两次看到的 XP 种子都填进来。"
    static let xpSeed1 = "XP种子 1"
    static let xpSeed1Tooltip = "所需的第一个XP种子"
    static let xpSeed2 = "XP种子 2"
    static let xpSeed2Tooltip = "所需的第二个XP种子"
    static let calculateSeed = "计算种子"
    static let playerSeed = "玩家种子"
    static let playerSeedPlaceholder = "12 位十六进制"

    static let reset = "重置"
    static let resetTooltip = "重置当前的XP种子破解器来破解新的XP种子"

    // MARK: - Enchantment calculator tab

    static let itemSetupTitle = "物品设置"
    static let materialSection = "材料"
    static let materialTooltip = "想要附魔的物品的材料"
    static let itemSection = "物品"
    static let itemTooltip = "想要附魔的物品"
    static let itemPlaceholder = "选择物品"

    static let maxBookshelves = "最大书架数"
    static let maxBookshelvesTooltip = "使用的最大书架数量"
    static let playerLevel = "玩家等级"
    static let levelPrefix = "等级:"
    static let playerLevelTooltip = "玩家当前的经验等级。允许查找30级及以下的附魔"

    static let targetsSection = "目标附魔"
    static let targetsHint = "按需要选择每个附魔的期望等级"
    static let noTargetsHint = "先选择物品和材料，才会列出可以附出的魔咒。"
    static let noPreference = "无要求"
    static let unwanted = "不要"
    static let targetNone = "无要求"

    static let calculate = "计算"
    static let calculateTooltip = "按下来计算你可能需要丢出多少物品来获得想要的附魔"

    static let resultSection = "计算结果"
    static let dropCount = "抛出物品数"
    static let dropCountTooltip = "需要丢出物品的数量"
    static let bookshelvesResult = "书架数"
    static let bookshelvesResultTooltip = "附魔所用的有效书架数量"
    static let slotResult = "附魔格"
    static let slotResultTooltip = "需要附魔的物品"
    static let done = "完成"
    static let doneTooltip = "按下来让破解器知道你已经获得了想要的附魔"
    static let resetCalculator = "重置计算器"

    static let playerSeedNotFound = "你需要先破解玩家种子！\n先去第一个选项卡里看看吧"
    static let playerSeedNotFoundTitle = "还没有玩家种子"
    static let impossible = "没有匹配"
    static let noDummy = "没有重复"

    // MARK: - About tab

    static let aboutHint = "Minecraft 附魔种子破解工具"
    static let aboutCreditsTitle = "致谢"
    static let aboutCreditOriginal = "Earthcomputer 的原始版本"
    static let aboutCreditImprovements = "Hexicube 改进了速度和 UI"
    static let aboutLinksTitle = "链接"
    static let aboutLinkGithub = "GitHub 页面（英文）"
    static let aboutLinkVideo = "Minecraft, Vanilla Survival: Cracking the Enchantment Seed（英文）"
    static let aboutLinkAlbum = "MC enchantment Cracker Tutorial 图片集（英文）"
    static let aboutStepsTitle = "使用步骤"
    static let aboutLicenseTitle = "许可证"
    static let aboutLicense = "本应用是根据 Earthcomputer/EnchantmentCracker 移植的 iOS 原生版本，按 GNU GPL-3.0 发布。"
    static let aboutBugReport = "请在问题追踪器上报告您发现的任何错误（使用英文）。"

    static let aboutSteps: [String] = [
        "在游戏里摆好附魔台，周围放好书架。",
        "打开附魔台，记下三格分别需要消耗的经验等级。",
        "回到「附魔破解器」，填入书架数和三个等级，点「检查」。",
        "再开一次附魔台，把新的等级也填进去，直到可能只剩一个 XP 种子。",
        "再开一次附魔台，用两次的 XP 种子算出玩家种子。",
        "切到「附魔计算器」，选物品、设置想要的附魔，点「计算」。",
        "照着结果丢物品、摆书架、点对应的附魔格，最后点「完成」。"
    ]

    // MARK: - Roman numerals for enchantment levels

    static func roman(_ value: Int) -> String {
        if value <= 0 { return "\(value)" }
        if value > 20 { return "\(value)" }
        let table: [(Int, String)] = [
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]
        var remainder = value
        var result = ""
        for (number, symbol) in table {
            while remainder >= number {
                result += symbol
                remainder -= number
            }
        }
        return result
    }
}

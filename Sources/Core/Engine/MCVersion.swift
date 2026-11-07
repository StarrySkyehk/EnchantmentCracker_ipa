import Foundation

/// Mirror of `enchcracker.Versions` — the distinct enchantment-algorithm eras of Minecraft.
enum MCVersion: Int, CaseIterable, Identifiable, Hashable {
    case v1_8 = 0
    case v1_9
    case v1_11
    case v1_11_1
    case v1_13
    case v1_14
    case v1_14_3
    case v1_16
    case v1_21
    case v1_21_9
    case v1_21_11

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .v1_8: return "1.8 - 1.8.9"
        case .v1_9: return "1.9 - 1.10.2"
        case .v1_11: return "1.11"
        case .v1_11_1: return "1.11.1 - 1.12.2"
        case .v1_13: return "1.13 - 1.13.2"
        case .v1_14: return "1.14 - 1.14.2"
        case .v1_14_3: return "1.14.3 - 1.15.2"
        case .v1_16: return "1.16 - 1.20.6"
        case .v1_21: return "1.21 - 1.21.8"
        case .v1_21_9: return "1.21.9 - 1.21.10"
        case .v1_21_11: return "1.21.11 - 最新"
        }
    }

    @inline(__always)
    func before(_ other: MCVersion) -> Bool { rawValue < other.rawValue }

    @inline(__always)
    func after(_ other: MCVersion) -> Bool { rawValue > other.rawValue }

    static var latest: MCVersion { .v1_21_11 }
}

import Foundation

/// Port of `enchcracker.SimpleRandom`, a Java `java.util.Random` clone optimised for
/// this app's use case (only `next(31)`, `next(24)` and `nextInt` are needed).
///
/// Kept as a value type so the hot cracking loop can keep it in a register.
struct SimpleRandom {
    private static let multiplier: UInt64 = 0x5DEECE66D
    private static let addend: UInt64 = 0xB
    private static let mask: UInt64 = (1 << 48) - 1

    private var seed: UInt64 = 0

    init() {}

    @inline(__always)
    mutating func setSeed(_ seed: Int32) {
        self.seed = (UInt64(bitPattern: Int64(seed)) ^ SimpleRandom.multiplier) & SimpleRandom.mask
    }

    @inline(__always)
    private mutating func next31() -> Int32 {
        seed = (seed &* SimpleRandom.multiplier &+ SimpleRandom.addend) & SimpleRandom.mask
        return Int32(truncatingIfNeeded: seed >> 17)
    }

    @inline(__always)
    mutating func nextInt(_ bound: Int) -> Int {
        let r = next31()
        let m = bound - 1
        if (bound & m) == 0 {
            // power of two
            return Int((Int64(bound) * Int64(r)) >> 31)
        }
        // `r` is always in [0, 2^31), so Java's rejection loop
        // (u - (r = u % bound) + m < 0) can never iterate.
        return Int(r % Int32(bound))
    }

    @inline(__always)
    mutating func nextFloat() -> Float {
        seed = (seed &* SimpleRandom.multiplier &+ SimpleRandom.addend) & SimpleRandom.mask
        let r = Int32(truncatingIfNeeded: seed >> 24)
        return Float(r) / Float(1 << 24)
    }
}

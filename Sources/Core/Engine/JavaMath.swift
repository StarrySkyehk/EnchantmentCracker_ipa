import Foundation

/// Port of the Java `Math.round(float)` semantics (floor(x + 0.5)), which differ
/// from Swift's `rounded()` for negative halves.
@inline(__always)
func javaRound(_ f: Float) -> Int {
    return Int(floor(Double(f) + 0.5))
}

/// Java `Math.round(float)` returning Int32-ish saturation is not needed by this app.
@inline(__always)
func javaRoundI32(_ f: Float) -> Int32 {
    return Int32(floor(Double(f) + 0.5))
}

import Foundation

// Performance benchmark for the Swift seed cracker (run on macOS CI, not part of the app).
// Build from the repository root:
//   swiftc -O Sources/Core/Engine/*.swift bench/main.swift -o /tmp/bench && /tmp/bench

func time(_ label: String, _ body: () -> Void) {
    let start = DispatchTime.now().uptimeNanoseconds
    body()
    let end = DispatchTime.now().uptimeNanoseconds
    let seconds = Double(end - start) / 1_000_000_000.0
    print(String(format: "%-34s %8.2f s", (label as NSString).utf8String!, seconds))
}

print("cores: \(ProcessInfo.processInfo.activeProcessorCount)")

// One observation: the typical 15-bookshelf table reading (100.6M matching seeds).
do {
    let cracker = SeedCracker()
    let obs = SeedObservation(bookshelves: 15, slot1: 5, slot2: 11, slot3: 30)
    let start = DispatchTime.now().uptimeNanoseconds
    let result = cracker.add(observation: obs, memoryBudget: 32_000_000)
    let seconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000.0
    let rate = 4_294_967_296.0 / seconds / 1_000_000.0
    print(String(format: "full 2^32 scan: %.2f s  (%.0f M seeds/s)  matches=%d  stored=%@",
                 seconds, rate, result.matchingSeeds,
                 result.candidates == nil ? "no" : "yes"))
}

// Two observations: the second scan runs with both constraints applied at once.
do {
    let cracker = SeedCracker()
    let start = DispatchTime.now().uptimeNanoseconds
    _ = cracker.add(observation: SeedObservation(bookshelves: 15, slot1: 5, slot2: 11, slot3: 30),
                    memoryBudget: 32_000_000)
    let second = cracker.add(observation: SeedObservation(bookshelves: 14, slot1: 4, slot2: 9, slot3: 28),
                             memoryBudget: 32_000_000)
    let seconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000.0
    print(String(format: "two checks total: %.2f s  matches=%d  stored=%@",
                 seconds, second.matchingSeeds,
                 second.candidates == nil ? "no" : "yes"))
}

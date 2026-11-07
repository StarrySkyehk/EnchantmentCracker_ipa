import Foundation
import Dispatch

/// One "enchanting table observation": the number of bookshelves plus the three
/// XP cost levels that were displayed in the table.
struct SeedObservation: Equatable {
    let bookshelves: Int
    let slot1: Int
    let slot2: Int
    let slot3: Int
}

struct CrackScanResult {
    /// Total number of seeds in the whole 2^32 space that match every observation.
    let matchingSeeds: Int
    /// Number of seeds visited (candidates tested, or the size of the previous candidate list).
    let seedsSearched: Int64
    /// Matching seeds in ascending order, or nil when more matches were found than the
    /// memory budget allows (caller should rescan with the next observation instead).
    let candidates: [Int32]?
    let aborted: Bool
}

/// Brute-forces the 32-bit XP seed, mirroring `JavaSingleSeedCracker`.
///
/// The first observation alone usually leaves ~10^8 candidates, which is too much to keep
/// on a phone, so the cracker works in two modes:
///  - if the match count fits in `memoryBudget`, the candidates are kept and later
///    observations are applied by simply filtering that list (very fast);
///  - otherwise the list is dropped and the next observation triggers a fresh full scan
///    with all observations applied at once (memory stays flat).
final class SeedCracker {

    static let totalSeeds: Int64 = Int64(UInt32.max) + 1

    private let stateLock = NSLock()
    private var abortRequested = false
    private var scannedSoFar: Int64 = 0

    /// Observations collected so far (in the order the user entered them).
    private(set) var observations: [SeedObservation] = []
    /// Kept candidates, nil if the last full scan exceeded the memory budget.
    private(set) var candidates: [Int32]? = nil
    private(set) var lastMatchCount = 0

    var hasCandidates: Bool { candidates != nil }
    var hasObservations: Bool { !observations.isEmpty }

    // MARK: Control

    func reset() {
        stateLock.lock()
        abortRequested = false
        scannedSoFar = 0
        stateLock.unlock()
        observations = []
        candidates = nil
        lastMatchCount = 0
    }

    func requestAbort() {
        stateLock.lock()
        abortRequested = true
        stateLock.unlock()
    }

    var isAbortRequested: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return abortRequested
    }

    /// How many seeds have been visited by the current scan.
    var scannedSeeds: Int64 {
        stateLock.lock()
        defer { stateLock.unlock() }
        return scannedSoFar
    }

    // MARK: Scanning

    /// Adds an observation and narrows / recomputes the candidate set.
    /// Blocking CPU work — call it off the main thread.
    func add(observation: SeedObservation, memoryBudget: Int) -> CrackScanResult {
        stateLock.lock()
        abortRequested = false
        scannedSoFar = 0
        stateLock.unlock()

        observations.append(observation)

        if let existing = candidates {
            return filterCandidates(existing)
        }
        return fullScan(memoryBudget: memoryBudget)
    }

    private func filterCandidates(_ existing: [Int32]) -> CrackScanResult {
        var rng = SimpleRandom()
        var kept: [Int32] = []
        kept.reserveCapacity(min(existing.count, 65536))
        let obs = observations
        var visited: Int64 = 0

        for seed in existing {
            if visited % 262144 == 0 {
                if isAbortRequested {
                    lastMatchCount = kept.count
                    return CrackScanResult(matchingSeeds: kept.count, seedsSearched: visited,
                                           candidates: kept, aborted: true)
                }
                reportScanned(visited)
            }
            visited += 1
            var matched = true
            for o in obs {
                rng.setSeed(seed)
                let base = 1 + (o.bookshelves >> 1)
                let bs = o.bookshelves
                // Each of the three table slots draws its own generic enchantability level.
                var level = rng.nextInt(8) + base + rng.nextInt(bs + 1)
                if max(level / 3, 1) != o.slot1 { matched = false; break }
                level = rng.nextInt(8) + base + rng.nextInt(bs + 1)
                if level * 2 / 3 + 1 != o.slot2 { matched = false; break }
                level = rng.nextInt(8) + base + rng.nextInt(bs + 1)
                if max(level, bs * 2) != o.slot3 { matched = false; break }
            }
            if matched {
                kept.append(seed)
            }
        }

        kept.sort()
        candidates = kept
        lastMatchCount = kept.count
        reportScanned(visited)
        return CrackScanResult(matchingSeeds: kept.count, seedsSearched: visited,
                               candidates: kept, aborted: false)
    }

    private final class Shared {
        let lock = NSLock()
        var matchCount = 0
        var stored: [Int32] = []
        var memoryExceeded = false
    }

    private func fullScan(memoryBudget: Int) -> CrackScanResult {
        let obs = observations
        let workers = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
        let chunkCount = max(workers, workers * 4)
        let chunkSize = SeedCracker.totalSeeds / Int64(chunkCount)
        let shared = Shared()
        var abortedFlag = false

        DispatchQueue.concurrentPerform(iterations: chunkCount) { chunk in
            let start = Int64(chunk) * chunkSize
            let end = chunk == chunkCount - 1 ? SeedCracker.totalSeeds : start + chunkSize

            var rng = SimpleRandom()
            var buffer: [Int32] = []
            buffer.reserveCapacity(4096)
            var localMatches = 0
            var i = start
            var lastReport = start

            while i < end {
                if (i & 0xFFFF) == 0 {
                    if isAbortRequested { break }
                }

                // Hot loop: keep the matching inline so no per-seed function call / ARC happens.
                let seed = Int32(bitPattern: UInt32(truncatingIfNeeded: i))
                var matched = true
                for o in obs {
                    rng.setSeed(seed)
                    let base = 1 + (o.bookshelves >> 1)
                    let bs = o.bookshelves
                    // Each of the three table slots draws its own generic enchantability level.
                    var level = rng.nextInt(8) + base + rng.nextInt(bs + 1)
                    if max(level / 3, 1) != o.slot1 { matched = false; break }
                    level = rng.nextInt(8) + base + rng.nextInt(bs + 1)
                    if level * 2 / 3 + 1 != o.slot2 { matched = false; break }
                    level = rng.nextInt(8) + base + rng.nextInt(bs + 1)
                    if max(level, bs * 2) != o.slot3 { matched = false; break }
                }
                if matched {
                    localMatches += 1
                    if !shared.memoryExceeded {
                        buffer.append(seed)
                        if buffer.count >= 4096 {
                            shared.lock.lock()
                            if shared.memoryExceeded {
                                buffer.removeAll(keepingCapacity: true)
                            } else {
                                shared.stored.append(contentsOf: buffer)
                                if shared.stored.count > memoryBudget {
                                    shared.memoryExceeded = true
                                    shared.stored.removeAll(keepingCapacity: false)
                                }
                                buffer.removeAll(keepingCapacity: true)
                            }
                            shared.lock.unlock()
                        }
                    }
                }

                i += 1
                if i - lastReport >= 65536 {
                    shared.lock.lock()
                    shared.matchCount += localMatches
                    shared.lock.unlock()
                    localMatches = 0
                    reportScanned(i - start)
                    lastReport = i
                }
            }

            shared.lock.lock()
            shared.matchCount += localMatches
            if !shared.memoryExceeded && !buffer.isEmpty {
                shared.stored.append(contentsOf: buffer)
                if shared.stored.count > memoryBudget {
                    shared.memoryExceeded = true
                    shared.stored.removeAll(keepingCapacity: false)
                }
            }
            shared.lock.unlock()
        }

        if isAbortRequested { abortedFlag = true }

        lastMatchCount = shared.matchCount
        if shared.memoryExceeded || abortedFlag {
            candidates = nil
            reportScanned(SeedCracker.totalSeeds)
            return CrackScanResult(matchingSeeds: shared.matchCount, seedsSearched: SeedCracker.totalSeeds,
                                   candidates: nil, aborted: abortedFlag)
        }

        var result = shared.stored
        if result.count <= 100_000 { result.sort() }
        candidates = result
        reportScanned(SeedCracker.totalSeeds)
        return CrackScanResult(matchingSeeds: shared.matchCount, seedsSearched: SeedCracker.totalSeeds,
                               candidates: result, aborted: false)
    }

    // MARK: Progress

    private func reportScanned(_ count: Int64) {
        stateLock.lock()
        scannedSoFar = count
        stateLock.unlock()
    }
}

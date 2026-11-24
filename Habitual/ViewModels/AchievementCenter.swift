import Foundation
import Observation

@Observable
final class AchievementCenter {

    // Trophies waiting to be shown, first in line at the front
    private(set) var queue: [Achievement] = []

    // IDs we've already queued this session, so a trophy is never queued twice
    private var seen: Set<String> = []

    // The one currently on screen (nil = nothing to show)
    var current: Achievement? { queue.first }

    // How many are still waiting after the current one
    var remainingAfterCurrent: Int { max(0, queue.count - 1) }

    func enqueue(_ achievement: Achievement) {
        guard !seen.contains(achievement.id) else { return }
        seen.insert(achievement.id)
        queue.append(achievement)
    }

    func dismissCurrent() {
        if !queue.isEmpty { queue.removeFirst() }
    }

    func skipAll() {
        queue.removeAll()
    }
}

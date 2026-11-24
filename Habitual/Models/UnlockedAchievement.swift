import Foundation
import SwiftData

@Model
final class UnlockedAchievement {
    // .unique = the database refuses duplicates of the same achievement
    @Attribute(.unique) var achievementID: String
    var unlockedAt: Date

    init(achievementID: String, unlockedAt: Date = Date()) {
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
    }
}

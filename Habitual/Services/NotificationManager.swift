import Foundation
import UserNotifications
import SwiftData

// MARK: - The reminder scheduler
// Analogy: setting alarms on your phone. We don't ring them ourselves.
// We hand iOS the alarm ("every day at 9:00") and iOS rings it, even if the app is closed.
enum NotificationManager {

    static let categoryID = "HABIT_REMINDER"
    static let completeActionID = "COMPLETE_HABIT"

    // A sensible default reminder time: 9:00 AM
    static func defaultTime() -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }

    // Tell iOS our reminders come with a "Mark as done" button.
    // Call once when the app launches.
    static func registerCategories() {
        let doneAction = UNNotificationAction(
            identifier: completeActionID,
            title: "Mark as done",
            options: []                       // [] = runs in the background, doesn't open the app
        )
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: [doneAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // Ask the user's permission. iOS only shows the pop-up the first time; later it just answers.
    static func requestPermission() async -> Bool {
        let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    // Schedule a reminder that repeats every day at the given time.
    // We pass plain values (id, name, time) rather than the Habit itself, which keeps this
    // function independent of the database.
    static func schedule(habitID: UUID, name: String, time: Date) async {
        // Replace any existing reminder for this habit
        cancel(habitID: habitID)

        let messages = [
            "A small step today keeps your streak alive.",
            "Two minutes now, and it's done.",
            "Future you will thank you for this one.",
            "Show up today. That's the whole game."
        ]

        let content = UNMutableNotificationContent()
        content.title = name
        content.body = messages.randomElement() ?? messages[0]
        content.sound = .default
        content.categoryIdentifier = categoryID                 // attaches the "Mark as done" button
        content.userInfo = ["habitID": habitID.uuidString]      // so we know which habit the button is for

        // Only the hour and minute matter. repeats: true = every day.
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)

        // Using the habit's id as the request id means "one reminder per habit"
        let request = UNNotificationRequest(identifier: habitID.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // Remove a habit's reminder (used when the habit is deleted or the reminder is turned off)
    static func cancel(habitID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [habitID.uuidString])
    }

    // DEBUG helper: fires a test notification in 5 seconds so you don't wait until tomorrow.
    static func scheduleTest(habitID: UUID, name: String) async {
        let content = UNMutableNotificationContent()
        content.title = name
        content.body = "This is a test reminder."
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.userInfo = ["habitID": habitID.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Reacting to notifications
// iOS calls this object when a notification arrives or a button is tapped.
// Analogy: the receptionist. The post comes in, and they decide what to do with it.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // One shared instance. iOS only keeps a weak reference, so we hold it strongly here.
    static let shared = NotificationDelegate()

    // A notification arrives while the app is OPEN: show it anyway (by default iOS would hide it).
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // The user tapped the notification or one of its buttons.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        // We only care about our "Mark as done" button
        guard response.actionIdentifier == NotificationManager.completeActionID else { return }

        // Which habit is it for? We stashed its id in userInfo when scheduling.
        let info = response.notification.request.content.userInfo
        guard let idString = info["habitID"] as? String,
              let habitID = UUID(uuidString: idString) else { return }

        // Database work must happen on the main thread
        await MainActor.run {
            HabitService.complete(habitID: habitID, in: AppDatabase.container.mainContext)
        }
    }
}

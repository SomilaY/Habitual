import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabitualApp: App {

    init() {
        // Tell iOS who should handle notifications, and register the "Mark as done" button
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationManager.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        // Use our one shared database (instead of letting SwiftUI make its own)
        .modelContainer(AppDatabase.container)
    }
}

import Foundation
import UserNotifications

enum NotificationManager {
    static let dailyNewsIdentifier = "world.daily.news"

    static func requestPermissionAndScheduleDaily(hour: Int = 7, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification authorization error: \(error.localizedDescription)")
                return
            }

            guard granted else {
                print("Notification permission not granted.")
                return
            }

            scheduleDailyNewsNotification(hour: hour, minute: minute)
        }
    }

    static func scheduleDailyNewsNotification(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "World News"
        content.body = "New headlines are ready."
        content.sound = .default

        var components = DateComponents()
        components.calendar = Calendar.current
        components.timeZone = .current
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyNewsIdentifier, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [dailyNewsIdentifier])
        center.add(request) { error in
            if let error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }
}

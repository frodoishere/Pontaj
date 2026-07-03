import UserNotifications

/// Notificari locale: memento daca pontajul ramane pornit prea mult timp.
enum NotificationManager {
    private static let longSessionId = "pontaj-long-session"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Programeaza o notificare dupa 12 ore daca sesiunea inca ruleaza.
    static func scheduleLongSessionReminder(projectName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pontaj inca pornit"
        content.body = "Ai un pontaj activ pe \"\(projectName)\" de peste 12 ore. Nu uita sa il opresti."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12 * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: longSessionId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelLongSessionReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [longSessionId])
    }
}

import Foundation
import UserNotifications

enum LocalReminders {
    static let prefix = "campuscompanion.activity."
    private static let fireKey = "campusCompanion.notificationFireDates"
    private static let consumedKey = "campusCompanion.notifiedOccurrences"
    private static func consumed(at now: Date) -> Set<String> {
        var used = Set(UserDefaults.standard.stringArray(forKey: consumedKey) ?? [])
        let fires = UserDefaults.standard.dictionary(forKey: fireKey) as? [String: Double] ?? [:]
        for (id, time) in fires where time <= now.timeIntervalSince1970 { used.insert(id) }
        // Keep recent date-qualified IDs; past trigger times are treated as consumed
        // even if Focus hid the notification or the user dismissed it.
        let cutoff = CampusCompanionDate.day(now.addingTimeInterval(-9 * 86400))
        used = Set(used.filter { String($0.prefix(10)) >= cutoff })
        UserDefaults.standard.set(Array(used), forKey: consumedKey)
        return used
    }
    static func clear() async {
        _ = consumed(at: Date())
        UserDefaults.standard.removeObject(forKey: fireKey)
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        let delivered = await center.deliveredNotifications()
        center.removeDeliveredNotifications(withIdentifiers: delivered.map { $0.request.identifier }.filter { $0.hasPrefix(prefix) })
    }

    static func schedule(_ snapshot: CampusCompanionSnapshot, now: Date = Date()) async throws -> Int {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { await clear(); return 0 }
        let used = consumed(at: now)
        let requests = makeRequests(snapshot, now: now, consumed: used)
        let wanted = Set(requests.map(\.identifier))
        let previous = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: previous.map(\.identifier).filter { $0.hasPrefix(prefix) && !wanted.contains($0) })
        var fires = (UserDefaults.standard.dictionary(forKey: fireKey) as? [String: Double] ?? [:]).filter { wanted.contains(prefix + $0.key) }
        for request in requests {
            try await center.add(request)
            if let fire = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() {
                fires[String(request.identifier.dropFirst(prefix.count))] = fire.timeIntervalSince1970
            }
            UserDefaults.standard.set(fires, forKey: fireKey)
        }
        if requests.isEmpty { UserDefaults.standard.removeObject(forKey: fireKey) }
        return requests.count
    }

    static func triggerComponents(for fire: Date) -> DateComponents {
        // Store the exact instant in UTC; configured-zone fall-back wall times can repeat.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.dateComponents([.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second], from: fire)
    }

    static func makeRequests(_ snapshot: CampusCompanionSnapshot, now: Date, consumed: Set<String>) -> [UNNotificationRequest] {
        Array(snapshot.events.sorted { $0.startDate! < $1.startDate! }.compactMap { event -> UNNotificationRequest? in
            guard let start = event.startDate, let link = CampusCompanionDeepLink.activityURL(for: event) else { return nil }
            let fire = start.addingTimeInterval(-20 * 60)
            guard fire > now, !consumed.contains(event.id) else { return nil }
            let content = UNMutableNotificationContent()
            content.title = event.course.isEmpty ? event.title : event.course + " · " + event.title
            var lines = [event.timeLabel, (event.location ?? "").isEmpty ? "Location not confirmed" : event.location!]
            let remaining = event.preparation.filter { !$0.done }
            if !remaining.isEmpty {
                lines.append(remaining.map { ($0.type == .required ? "Before: " : "Preparation: ") + $0.title }.joined(separator: "; "))
            }
            content.body = lines.joined(separator: "\n")
            content.sound = nil
            content.interruptionLevel = .active
            content.threadIdentifier = "campuscompanion.schedule"
            content.userInfo = ["campusCompanionURL": link.absoluteString]
            let parts = triggerComponents(for: fire)
            return UNNotificationRequest(identifier: prefix + event.id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
        }.prefix(60))
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .list] }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let raw = response.notification.request.content.userInfo["campusCompanionURL"] as? String,
              let link = URL(string: raw), CampusCompanionDeepLink.destination(from: link) != nil else { return }
        await MainActor.run { NotificationCenter.default.post(name: .campusCompanionOpen, object: link) }
    }
}

extension Notification.Name { static let campusCompanionOpen = Notification.Name("CampusCompanion.open") }

import Foundation

enum CampusCompanionWidgetConfiguration {
    static let appGroup = "group.org.example.campuscompanion.mobile"
    static let kind = "CampusCompanion.UpNext"
    static let siteHost = "planner.example.org"
    static let timeZone = "UTC"
}

enum CampusCompanionCourseKey: String, Codable, Sendable { case other }
enum CampusCompanionPreparationKind: String, Codable, Sendable { case required, preparation }
enum CampusCompanionEventKind: String, Codable, Sendable { case course, work }

struct CampusCompanionPreparation: Codable, Equatable, Sendable {
    let id: String?
    let title: String
    let type: CampusCompanionPreparationKind
    let done: Bool
}

struct CampusCompanionEvent: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let kind: CampusCompanionEventKind?
    let title: String
    let course: String
    let courseKey: CampusCompanionCourseKey
    let startAt: String
    let endAt: String
    let location: String?
    let preparation: [CampusCompanionPreparation]
    let taskId: String?
    let url: String
    let nextStep: String?

    var startDate: Date? { CampusCompanionDate.parse(startAt) }
    var endDate: Date? { CampusCompanionDate.parse(endAt) }
    var locationText: String { location ?? "" }
    var preparationLabel: String? {
        if preparation.contains(where: { $0.type == .required && !$0.done }) { return "Prep needed" }
        if preparation.contains(where: { !$0.done }) { return "Prep suggested" }
        return preparation.isEmpty ? nil : "Prep ready"
    }
    var timeLabel: String {
        guard let startDate, let endDate else { return "Time unavailable" }
        return CampusCompanionDate.time(startDate) + "–" + CampusCompanionDate.time(endDate)
    }
}

enum CampusCompanionWidgetError: Error, Equatable {
    case invalidSnapshot, invalidEvent, invalidLink, cacheUnavailable, olderSnapshot, cacheTooLarge
}

enum CampusCompanionDate {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: CampusCompanionWidgetConfiguration.timeZone)!
        return calendar
    }
    static func parse(_ value: String) -> Date? {
        guard value.count <= 40,
              value.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})$"#, options: .regularExpression) != nil else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
    static func day(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
    static func dayStart(_ value: String) -> Date? {
        guard value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else { return nil }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              day(date) == value else { return nil }
        return date
    }
    static func nextMidnight(after date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
    }
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    static func updated(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    static func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

enum CampusCompanionDeepLink {
    static let openURL = URL(string: "campuscompanion://open")!

    // A widget may open only this planner's root with date/block and optional task.
    // The native shell must call destination(from:) again before loading a URL.
    static func validatedWebURL(_ value: String) -> URL? {
        guard value.utf8.count <= 4096, let url = URL(string: value),
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "https",
              parts.host?.lowercased() == CampusCompanionWidgetConfiguration.siteHost,
              parts.user == nil, parts.password == nil, parts.port == nil,
              parts.path.isEmpty || parts.path == "/", parts.fragment == nil else { return nil }
        let query = parts.queryItems ?? []
        guard (2...3).contains(query.count),
              query.allSatisfy({ ["date", "block", "task"].contains($0.name) }),
              query.filter({ $0.name == "task" }).count <= 1,
              query.filter({ $0.name == "date" }).count == 1,
              query.filter({ $0.name == "block" }).count == 1,
              let date = query.first(where: { $0.name == "date" })?.value,
              CampusCompanionDate.dayStart(date) != nil,
              let block = query.first(where: { $0.name == "block" })?.value,
              !block.isEmpty, block.count <= 300,
              !block.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        if let task = query.first(where: { $0.name == "task" }) {
            guard let value = task.value, !value.isEmpty, value.count <= 300,
                  !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        }
        return url
    }

    static func activityURL(for event: CampusCompanionEvent) -> URL? {
        guard let destination = validatedWebURL(event.url) else { return nil }
        var parts = URLComponents()
        parts.scheme = "campuscompanion"; parts.host = "activity"
        parts.queryItems = [URLQueryItem(name: "url", value: destination.absoluteString)]
        return parts.url
    }

    static func destination(from link: URL) -> URL? {
        guard let parts = URLComponents(url: link, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "campuscompanion", parts.host == "activity",
              parts.path.isEmpty, parts.user == nil, parts.password == nil,
              parts.port == nil, parts.fragment == nil,
              let query = parts.queryItems, query.count == 1,
              query[0].name == "url", let value = query[0].value else { return nil }
        return validatedWebURL(value)
    }
}

struct CampusCompanionSnapshot: Codable, Equatable, Sendable {
    let version: Int
    let generatedAt: String
    let planDate: String
    let timeZone: String
    let revision: Int
    let validUntil: String
    let events: [CampusCompanionEvent]

    static let maximumBytes = 256 * 1024
    static func decode(data: Data) throws -> CampusCompanionSnapshot {
        guard data.count <= maximumBytes else { throw CampusCompanionWidgetError.cacheTooLarge }
        let result = try JSONDecoder().decode(Self.self, from: data)
        try result.validate()
        return result
    }
    func validate() throws {
        guard version == 1, revision >= 0,
              timeZone == CampusCompanionWidgetConfiguration.timeZone,
              let generated = CampusCompanionDate.parse(generatedAt),
              let expires = CampusCompanionDate.parse(validUntil), expires > generated,
              let start = CampusCompanionDate.dayStart(planDate), events.count <= 80,
              CampusCompanionDate.day(generated) == planDate,
              expires == CampusCompanionDate.nextMidnight(after: start),
              Set(events.map(\.id)).count == events.count else { throw CampusCompanionWidgetError.invalidSnapshot }
        let end = CampusCompanionDate.calendar.date(byAdding: .day, value: 8, to: start)!
        for event in events {
            guard Self.validText(event.id, maximum: 400), Self.validText(event.title, maximum: 400),
                  Self.validText(event.course, maximum: 120, allowEmpty: true),
                  event.location.map({ Self.validText($0, maximum: 300, allowEmpty: true) }) ?? true,
                  event.taskId.map({ Self.validText($0, maximum: 300) }) ?? true,
                  event.nextStep.map({ Self.validText($0, maximum: 1200, allowEmpty: true) }) ?? true,
                  event.preparation.count <= 30,
                  event.preparation.allSatisfy({ Self.validText($0.title, maximum: 400) && ($0.id.map { Self.validText($0, maximum: 300) } ?? true) }),
                  let begins = event.startDate, let ends = event.endDate,
                  begins >= start, begins < end, ends > begins, ends <= CampusCompanionDate.nextMidnight(after: begins),
                  CampusCompanionDate.day(begins) == planDate || event.kind == .course else { throw CampusCompanionWidgetError.invalidEvent }
            guard let url = CampusCompanionDeepLink.validatedWebURL(event.url),
                  let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                  let date = query.first(where: { $0.name == "date" })?.value,
                  let block = query.first(where: { $0.name == "block" })?.value,
                  date == CampusCompanionDate.day(begins), event.id == date + "|" + block,
                  query.first(where: { $0.name == "task" }).map({ $0.value == event.taskId }) ?? true else { throw CampusCompanionWidgetError.invalidLink }
        }
    }
    private static func validText(_ value: String, maximum: Int, allowEmpty: Bool = false) -> Bool {
        value.count <= maximum && (allowEmpty || !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            && !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    }

    func presentation(at now: Date) -> CampusCompanionWidgetPresentation {
        guard (try? validate()) != nil,
              let generated = CampusCompanionDate.parse(generatedAt), let expires = CampusCompanionDate.parse(validUntil) else { return .unavailable }
        let stale = now >= expires || CampusCompanionDate.day(now) != planDate || generated > now.addingTimeInterval(300)
        let ordered = events.filter { !stale || $0.kind == .course }.sorted { ($0.startDate!, $0.id) < ($1.startDate!, $1.id) }
        let current = ordered.first { $0.startDate! <= now && now < $0.endDate! }
        let next = ordered.first { now < $0.startDate! }
        return CampusCompanionWidgetPresentation(status: stale ? .stale : current != nil ? .current : next != nil ? .upNext : .finished,
                                               event: current ?? next, generatedAt: generated, referenceDate: now)
    }

    // Includes expiry and configured-zone midnight even if the final class ends earlier.
    // WidgetKit decides actual display timing; this is not an exact alarm.
    func timelineDates(after now: Date) -> [Date] {
        let midnight = CampusCompanionDate.nextMidnight(after: now)
        var dates = [now, midnight]
        if let expiry = CampusCompanionDate.parse(validUntil), expiry > now, expiry < midnight { dates.append(expiry) }
        for event in events {
            dates += [event.startDate, event.endDate].compactMap { $0 }.filter { $0 > now && $0 < midnight }
        }
        return Array(Set(dates)).sorted()
    }
}

struct CampusCompanionWidgetPresentation: Equatable, Sendable {
    enum Status: Sendable { case unconfigured, unavailable, stale, current, upNext, finished }
    let status: Status
    let event: CampusCompanionEvent?
    let generatedAt: Date?
    let referenceDate: Date?
    static let unconfigured = Self(status: .unconfigured, event: nil, generatedAt: nil, referenceDate: nil)
    static let unavailable = Self(status: .unavailable, event: nil, generatedAt: nil, referenceDate: nil)
    var heading: String {
        switch status {
        case .unconfigured: "Set up Campus Companion"
        case .unavailable: "Plan unavailable"
        case .stale: event == nil ? "Update needed" : "Saved class · refresh"
        case .current: "Now"
        case .upNext: "Up next"
        case .finished: "Nothing scheduled next"
        }
    }
    var isFresh: Bool { status == .current || status == .upNext || status == .finished }
    var eventDayLabel: String? {
        guard let event, let start = event.startDate, let referenceDate,
              CampusCompanionDate.day(start) != CampusCompanionDate.day(referenceDate) else { return nil }
        return CampusCompanionDate.shortDay(start)
    }
    var eventTimeLabel: String {
        guard let event else { return "" }
        return eventDayLabel.map { $0 + " · " + event.timeLabel } ?? event.timeLabel
    }
    var actionURL: URL { event.flatMap(CampusCompanionDeepLink.activityURL(for:)) ?? CampusCompanionDeepLink.openURL }
    var accessibilityLabel: String {
        var pieces = [heading]
        if let event { pieces += [event.course, event.title, eventTimeLabel, event.locationText, event.preparationLabel ?? ""] }
        if let generatedAt { pieces.append("Saved " + CampusCompanionDate.updated(generatedAt)) }
        if !isFresh { pieces.append("Open the app to refresh the saved plan.") }
        return pieces.filter { !$0.isEmpty }.joined(separator: ". ")
    }
}

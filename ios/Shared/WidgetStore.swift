import Foundation

enum CampusCompanionWidgetCache: Sendable {
    case unconfigured
    case unavailable
    case snapshot(CampusCompanionSnapshot)

    func presentation(at date: Date) -> CampusCompanionWidgetPresentation {
        switch self {
        case .unconfigured: .unconfigured
        case .unavailable: .unavailable
        case .snapshot(let snapshot): snapshot.presentation(at: date)
        }
    }
}

// The app is the sole writer; its authenticated refresh controller must serialize
// save/clear calls. The widget reads only and never receives authentication secrets.
struct CampusCompanionWidgetStore: Sendable {
    let directory: URL?
    static var appGroup: Self {
        Self(directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CampusCompanionWidgetConfiguration.appGroup))
    }
    private var fileURL: URL? { directory?.appendingPathComponent("widget-plan-v1.json", isDirectory: false) }

    func read() -> CampusCompanionWidgetCache {
        guard let fileURL else { return .unavailable }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .unconfigured }
        do {
            let size = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= CampusCompanionSnapshot.maximumBytes else { return .unavailable }
            return .snapshot(try CampusCompanionSnapshot.decode(data: Data(contentsOf: fileURL)))
        } catch { return .unavailable }
    }

    func save(_ snapshot: CampusCompanionSnapshot) throws {
        try snapshot.validate()
        guard let directory, let fileURL else { throw CampusCompanionWidgetError.cacheUnavailable }
        if case .snapshot(let previous) = read() {
            guard snapshot.revision >= previous.revision,
                  CampusCompanionDate.parse(snapshot.generatedAt)! >= CampusCompanionDate.parse(previous.generatedAt)! else {
                throw CampusCompanionWidgetError.olderSnapshot
            }
        }
        let data = try JSONEncoder().encode(snapshot)
        guard data.count <= CampusCompanionSnapshot.maximumBytes else { throw CampusCompanionWidgetError.cacheTooLarge }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #if os(iOS)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: fileURL, options: .atomic)
        #endif
        var excluded = URLResourceValues(); excluded.isExcludedFromBackup = true
        var saved = fileURL; try? saved.setResourceValues(excluded)
    }

    // Call on logout/account change, then reload the widget timeline from the app.
    func clear() throws {
        guard let fileURL else { throw CampusCompanionWidgetError.cacheUnavailable }
        if FileManager.default.fileExists(atPath: fileURL.path) { try FileManager.default.removeItem(at: fileURL) }
    }
}

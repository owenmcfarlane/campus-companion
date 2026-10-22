import SwiftUI
import Combine
import WidgetKit
import UniformTypeIdentifiers
import UserNotifications

@MainActor final class PlannerModel: ObservableObject {
    static let site = URL(string: "https://planner.example.org/")!
    @Published var snapshot: CampusCompanionSnapshot?
    @Published var message = "Open your planner and sign in to save your widget’s schedule."
    @Published var destination = site
    @Published var tab = 0
    @Published var refreshToken = 0
    @Published var reminderCount = 0
    @Published var bridgeEpoch = 0
    @Published var bridgePaused = false
    @Published var remindersEnabled = UserDefaults.standard.bool(forKey: "silentReminders")
    private var scheduling: Task<Void, Never>?
    init() {
        if case .snapshot(let cached) = CampusCompanionWidgetStore.appGroup.read() {
            snapshot = cached; message = "Saved " + CampusCompanionDate.updated(CampusCompanionDate.parse(cached.generatedAt)!)
        }
    }
    func refresh() {
        bridgeEpoch += 1; bridgePaused = false; refreshToken += 1
    }
    func receive(_ data: Data) {
        do {
            let next = try CampusCompanionSnapshot.decode(data: data)
            try CampusCompanionWidgetStore.appGroup.save(next)
            let changed = snapshot?.events != next.events || snapshot?.planDate != next.planDate || snapshot?.revision != next.revision
            snapshot = next
            message = "Updated " + CampusCompanionDate.updated(CampusCompanionDate.parse(next.generatedAt)!)
            if changed { WidgetCenter.shared.reloadTimelines(ofKind: CampusCompanionWidgetConfiguration.kind) }
            if remindersEnabled { schedule(next) }
        } catch CampusCompanionWidgetError.olderSnapshot {
            message = "This saved file is older than your current plan. Open the planner to refresh."
        } catch { message = "That plan couldn’t be saved. Refresh your planner and try again." }
    }
    private func schedule(_ next: CampusCompanionSnapshot) {
        // Serialize replacements so a slower previous refresh cannot restore obsolete reminders.
        let previous = scheduling
        scheduling = Task {
            await previous?.value
            guard remindersEnabled, snapshot == next else { return }
            do { reminderCount = try await LocalReminders.schedule(next) }
            catch { message = "The widget is saved, but reminders couldn’t be scheduled. Try refreshing." }
        }
    }
    func enableReminders() async {
        do {
            let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
            remindersEnabled = allowed; UserDefaults.standard.set(allowed, forKey: "silentReminders")
            if allowed, let snapshot { schedule(snapshot) }
            if !allowed { message = "Allow notifications in iPhone Settings → Campus Companion → Notifications." }
        } catch { message = "Notification permission could not be requested." }
    }
    func disableReminders() async {
        remindersEnabled = false; UserDefaults.standard.set(false, forKey: "silentReminders")
        await scheduling?.value; await LocalReminders.clear(); reminderCount = 0
    }
    func clear() {
        bridgeEpoch += 1; bridgePaused = true
        snapshot = nil
        try? CampusCompanionWidgetStore.appGroup.clear()
        WidgetCenter.shared.reloadTimelines(ofKind: CampusCompanionWidgetConfiguration.kind)
        message = "Saved widget plan cleared."
        Task { await scheduling?.value; await LocalReminders.clear(); reminderCount = 0 }
    }
    func open(_ url: URL) {
        if let destination = CampusCompanionDeepLink.destination(from: url) { self.destination = destination; tab = 0 }
        else if url.scheme == "campuscompanion", url.host == "open" { tab = 0; refresh() }
        else if url.scheme == "campuscompanion", url.host == "widget" { tab = 1 }
        else if url.isFileURL { importFile(url) }
    }
    func importFile(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 131072 else { throw CampusCompanionWidgetError.cacheTooLarge }
            receive(try Data(contentsOf: url)); tab = 1
        } catch { message = "Couldn’t read that schedule file. Export a new one from your planner." }
    }
}

@main struct CampusCompanionApp: App {
    @StateObject private var model = PlannerModel()
    @Environment(\.scenePhase) private var phase
    private let notificationDelegate = NotificationDelegate()
    init() { UNUserNotificationCenter.current().delegate = notificationDelegate }
    var body: some Scene {
        WindowGroup {
            TabView(selection: $model.tab) {
                PlannerWebView(model: model).tabItem { Label("Planner", systemImage: "checklist") }.tag(0)
                WidgetSetup(model: model).tabItem { Label("My widget", systemImage: "rectangle.inset.filled") }.tag(1)
            }
            .tint(Color(red: 0.22, green: 0.33, blue: 0.70))
            .onOpenURL { model.open($0) }
            .onReceive(NotificationCenter.default.publisher(for: .campusCompanionOpen)) { if let url = $0.object as? URL { model.open(url) } }
            .onChange(of: phase) { _, value in if value == .active { model.refreshToken += 1 } }
        }
    }
}

struct WidgetSetup: View {
    @ObservedObject var model: PlannerModel
    @State private var importing = false
    @State private var confirmClear = false
    @Environment(\.openURL) private var openURL
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let snapshot = model.snapshot, let event = snapshot.presentation(at: Date()).event {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(snapshot.presentation(at: Date()).heading.uppercased()).font(.caption).foregroundStyle(.secondary)
                            Text(event.course).font(.subheadline).foregroundStyle(.secondary)
                            Text(event.title).font(.headline)
                            Text(snapshot.presentation(at: Date()).eventTimeLabel)
                            Label((event.location ?? "").isEmpty ? "Location not confirmed" : event.location!, systemImage: "mappin")
                            if let prep = event.preparationLabel { Label(prep, systemImage: "checklist") }
                        }.padding(.vertical, 8)
                    } else { Label(model.snapshot == nil ? "Your next activity will appear here" : "Nothing scheduled next", systemImage: "calendar") }
                    Text(model.message).font(.footnote).foregroundStyle(.secondary)
                    Button("Refresh from planner") { model.tab = 0; model.refresh() }
                } header: { Text("Up next") } footer: { Text("Saved on this iPhone. Open the planner daily and after changing your day. Future days include confirmed classes; work blocks refresh when you open that day’s plan.") }
                Section("Add to your Lock Screen") {
                    Text("1. Hold your Lock Screen, then tap Customize.")
                    Text("2. Select Lock Screen → Add Widgets.")
                    Text("3. Choose Campus Companion → Up next.")
                    Text("Tap the widget to open its activity in your planner.").font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    if model.remindersEnabled {
                        Label("Silent reminders enabled", systemImage: "bell.badge")
                        Text("\(model.reminderCount) upcoming reminders scheduled").font(.footnote).foregroundStyle(.secondary)
                        Button("Turn off reminders") { Task { await model.disableReminders() } }
                    } else { Button("Enable silent 20-minute reminders") { Task { await model.enableReminders() } } }
                    Button("Notification settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                } footer: { Text("No sound. iPhone delivers reminders from the saved plan even with the app closed. Open the planner after edits to replace old reminders. Lock Screen visibility depends on your notification and Focus settings.") }
                Section("If sign-in needs Safari") {
                    Button("Open planner in Safari") { openURL(PlannerModel.site) }
                    Text("In your planner, tap the phone icon → Save schedule for widget. Share the saved file to Campus Companion, or import it below.").font(.footnote).foregroundStyle(.secondary)
                    Button("Import saved schedule") { importing = true }
                }
                Section { Button("Clear saved widget plan", role: .destructive) { confirmClear = true } }
            }
            .navigationTitle("My widget")
            .fileImporter(isPresented: $importing, allowedContentTypes: [UTType(filenameExtension: "campusplan") ?? .json, .json]) { result in
                if case .success(let url) = result { model.importFile(url) }
            }
            .confirmationDialog("Clear the widget and its reminders?", isPresented: $confirmClear) {
                Button("Clear saved plan", role: .destructive) { model.clear() }
            } message: { Text("Your online checklist and task progress stay saved.") }
        }
    }
}

import SwiftUI
import WidgetKit

struct CampusCompanionWidgetEntry: TimelineEntry {
    let date: Date
    let presentation: CampusCompanionWidgetPresentation
}

struct CampusCompanionWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CampusCompanionWidgetEntry {
        CampusCompanionWidgetEntry(date: Date(), presentation: .unconfigured)
    }
    func getSnapshot(in context: Context, completion: @escaping (CampusCompanionWidgetEntry) -> Void) {
        let now = Date()
        completion(CampusCompanionWidgetEntry(date: now, presentation: CampusCompanionWidgetStore.appGroup.read().presentation(at: now)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CampusCompanionWidgetEntry>) -> Void) {
        let now = Date(), cache = CampusCompanionWidgetStore.appGroup.read()
        let dates: [Date]
        if case .snapshot(let snapshot) = cache { dates = snapshot.timelineDates(after: now) }
        else { dates = [now, CampusCompanionDate.nextMidnight(after: now)] }
        let entries = dates.map { CampusCompanionWidgetEntry(date: $0, presentation: cache.presentation(at: $0)) }
        // This only re-reads the app-group cache. It cannot authenticate or fetch.
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
    }
}

struct CampusCompanionWidget: Widget {
    let kind = CampusCompanionWidgetConfiguration.kind
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CampusCompanionWidgetProvider()) { entry in
            CampusCompanionWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(.systemBackground) }
                .widgetURL(entry.presentation.actionURL)
        }
        .configurationDisplayName("Up next")
        .description("Your current activity or next class, from your saved school plan.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}

private struct CampusCompanionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CampusCompanionWidgetEntry
    private var view: CampusCompanionWidgetPresentation { entry.presentation }

    var body: some View {
        Group {
            if family == .accessoryInline { inline }
            else if !view.isFresh && view.event == nil { status }
            else if let event = view.event {
                if family == .systemSmall { small(event) } else { rectangular(event) }
            } else { finished }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(view.accessibilityLabel)
        .privacySensitive()
    }

    private var inline: some View {
        HStack(spacing: 3) {
            Image(systemName: view.isFresh ? "calendar" : "arrow.clockwise")
            if let event = view.event {
                Text("\(view.heading): \(event.course.isEmpty ? event.title : event.course) · \(view.eventDayLabel.map { $0 + " " } ?? "")\(CampusCompanionDate.time(event.startDate!))\(event.locationText.isEmpty ? "" : " · " + event.locationText)\(event.preparationLabel == "Prep needed" ? " · Prep!" : "")")
            } else { Text(view.heading) }
        }
    }

    private func course(_ event: CampusCompanionEvent) -> some View {
        HStack(spacing: 4) {
            Text(event.course.isEmpty ? "Campus Companion" : event.course).lineLimit(1)
            Circle().fill(tint(event.courseKey)).frame(width: 5, height: 5).accessibilityHidden(true)
        }
    }
    private func rectangular(_ event: CampusCompanionEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) { Text(view.heading).fontWeight(.semibold); course(event) }.font(.caption2)
            Text(event.title).font(.headline).lineLimit(1).minimumScaleFactor(0.85)
            HStack(spacing: 3) {
                Text(view.eventDayLabel.map { $0 + " " + CampusCompanionDate.time(event.startDate!) } ?? event.timeLabel).lineLimit(1).minimumScaleFactor(0.8)
                if !event.locationText.isEmpty { Text("· " + event.locationText).lineLimit(1) }
                if event.preparationLabel == "Prep needed" { Image(systemName: "exclamationmark.circle").accessibilityLabel("Prep needed") }
            }.font(.caption2)
        }
    }
    private func small(_ event: CampusCompanionEvent) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(view.heading).font(.caption).foregroundStyle(.secondary)
            course(event).font(.caption).fontWeight(.semibold)
            Text(event.title).font(.headline).lineLimit(2)
            Text(view.eventTimeLabel).font(.caption).fontWeight(.medium).lineLimit(2)
            if !event.locationText.isEmpty { Label(event.locationText, systemImage: "mappin").font(.caption2).lineLimit(1) }
            if let preparation = event.preparationLabel { Label(preparation, systemImage: preparation == "Prep needed" ? "exclamationmark.circle" : "checklist").font(.caption2).lineLimit(1) }
            Spacer(minLength: 0)
            if let generated = view.generatedAt { Text("Saved " + (view.isFresh ? CampusCompanionDate.time(generated) : CampusCompanionDate.updated(generated))).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(2) }
        }
    }
    private var status: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(view.heading, systemImage: "arrow.clockwise").font(.caption).fontWeight(.semibold).lineLimit(1)
            Text(view.status == .unconfigured ? "Open the app to load your plan." : "Open the app to refresh.").font(.caption2).lineLimit(2)
            if let generated = view.generatedAt { Text("Saved " + CampusCompanionDate.updated(generated)).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(2) }
        }
    }
    private var finished: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Campus Companion").font(.caption).foregroundStyle(.secondary)
            Text(view.heading).font(.headline).lineLimit(2)
            Text("Open your planner for other tasks.").font(.caption2).foregroundStyle(.secondary).lineLimit(2)
        }
    }
    private func tint(_ key: CampusCompanionCourseKey) -> Color {
        Color(red: 33/255, green: 100/255, blue: 90/255)
    }
}

// Root integrates CampusCompanionWidget in the extension's WidgetBundle @main.

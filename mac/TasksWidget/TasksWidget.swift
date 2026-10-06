import SwiftUI
import WidgetKit

@main
struct TasksWidgetBundle: WidgetBundle {
    var body: some Widget {
        DueWidget()
        OpenWidget()
    }
}

struct DueWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.dueKind, provider: SnapshotProvider()) { entry in
            DueWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Due Today")
        .description("Tasks that are overdue or due today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct OpenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.openKind, provider: SnapshotProvider()) { entry in
            OpenWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Open Tasks")
        .description("Every task you haven’t ticked off yet, soonest first.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SnapshotEntry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot?

    var today: Day { Day(date) }

    var due: (overdue: [WidgetSnapshot.Item], today: [WidgetSnapshot.Item]) {
        snapshot?.due(on: today) ?? ([], [])
    }

    static let placeholder: SnapshotEntry = {
        let today = Day.today()
        let items: [WidgetSnapshot.Item] = [
            .init(id: "a", title: "Pay rent", listTitle: "My Tasks", color: "blue", due: today.adding(days: -1).googleDue),
            .init(id: "b", title: "Call mom", listTitle: "Home", color: "green", due: today.googleDue),
            .init(id: "c", title: "Send invoice", listTitle: "Work", color: "orange", due: today.googleDue),
        ]
        let open = items + [
            .init(id: "d", title: "Return library books", listTitle: "My Tasks", color: "blue", due: today.adding(days: 4).googleDue),
            .init(id: "e", title: "Buy printer ink", listTitle: "My Tasks", color: "blue", due: ""),
        ]
        return SnapshotEntry(
            date: .now,
            snapshot: WidgetSnapshot(isSignedIn: true, showsLists: true, items: items, open: open, openCount: open.count)
        )
    }()
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = WidgetSnapshot.load()
        completion(context.isPreview && snapshot == nil ? .placeholder : SnapshotEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date.now
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        let entries = [SnapshotEntry(date: now, snapshot: snapshot), SnapshotEntry(date: midnight, snapshot: snapshot)]
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(3_600))))
    }
}

struct DueWidgetView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let due = entry.due
        let rows = due.overdue + due.today
        TaskWidgetLayout(
            entry: entry,
            title: "Today",
            symbol: "calendar",
            tint: .blue,
            rows: rows,
            total: rows.count,
            emptyText: "Nothing due."
        ) { item in
            let overdue = Day(googleDue: item.due).map { $0 < entry.today } ?? false
            return overdue && family != .systemSmall ? .due(red: true) : .list
        }
    }
}

struct OpenWidgetView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        TaskWidgetLayout(
            entry: entry,
            title: "Open",
            symbol: "tray.fill",
            tint: .gray,
            rows: entry.snapshot?.open ?? [],
            total: entry.snapshot?.openCount ?? 0,
            emptyText: "All done."
        ) { item in
            guard family != .systemSmall, let day = Day(googleDue: item.due) else { return .list }
            return .due(red: day < entry.today)
        }
    }
}

enum RowDetail {
    case list
    case due(red: Bool)
}

struct TaskWidgetLayout: View {
    let entry: SnapshotEntry
    let title: String
    let symbol: String
    let tint: Color
    let rows: [WidgetSnapshot.Item]
    let total: Int
    let emptyText: String
    let detail: (WidgetSnapshot.Item) -> RowDetail
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            header
            if entry.snapshot?.isSignedIn != true {
                message("Open Tasks to sign in.")
            } else if rows.isEmpty {
                message(emptyText)
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
                    ForEach(rows.prefix(rowLimit)) { item in
                        row(item)
                    }
                }
                if total > min(rows.count, rowLimit) {
                    Text("\(total - min(rows.count, rowLimit)) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var rowLimit: Int {
        switch family {
        case .systemSmall: 3
        case .systemMedium: 4
        default: 11
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)
            Spacer()
            if total > 0 {
                Text(total, format: .number)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func row(_ item: WidgetSnapshot.Item) -> some View {
        let color = (ListColor(rawValue: item.color) ?? .blue).color
        return HStack(spacing: 6) {
            Image(systemName: "circle")
                .foregroundStyle(color)
                .imageScale(.small)
            Text(item.title.isEmpty ? "Untitled Task" : item.title)
                .font(family == .systemSmall ? .caption : .callout)
                .lineLimit(1)
            Spacer(minLength: 4)
            trailing(item)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func trailing(_ item: WidgetSnapshot.Item) -> some View {
        switch detail(item) {
        case .due(let red):
            if let day = Day(googleDue: item.due) {
                Text(DueText.text(for: day, today: entry.today))
                    .font(.caption)
                    .foregroundStyle(red ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            }
        case .list:
            if family == .systemLarge, entry.snapshot?.showsLists == true {
                Text(item.listTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }
}

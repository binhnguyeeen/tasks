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
    var ticked: Set<String> = []
    var hidden: Set<String> = []

    init(date: Date, snapshot: WidgetSnapshot?, ticks: WidgetTicks = WidgetTicks(times: [:])) {
        self.date = date
        self.snapshot = snapshot
        ticked = ticks.ticked(at: date)
        hidden = ticks.hidden(at: date)
    }

    var today: Day { Day(date) }

    var due: (overdue: [WidgetSnapshot.Item], today: [WidgetSnapshot.Item]) {
        guard let due = snapshot?.due(on: today) else { return ([], []) }
        return (due.overdue.filter(isShown), due.today.filter(isShown))
    }

    var open: [WidgetSnapshot.Item] {
        (snapshot?.open ?? []).filter(isShown)
    }

    var openCount: Int {
        let gone = (snapshot?.open ?? []).count { hidden.contains($0.id) || ticked.contains($0.id) }
        return max((snapshot?.openCount ?? 0) - gone, 0)
    }

    private func isShown(_ item: WidgetSnapshot.Item) -> Bool {
        !hidden.contains(item.id)
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
        let ticks = WidgetTicks.load()
        let now = Date.now
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        let dates = [now] + ticks.changeDates(after: now).filter { $0 < midnight } + [midnight]
        let entries = dates.map { SnapshotEntry(date: $0, snapshot: snapshot, ticks: ticks) }
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
            total: rows.count { !entry.ticked.contains($0.id) },
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
            rows: entry.open,
            total: entry.openCount,
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
                    .transition(.opacity)
            } else {
                let shown = rows.prefix(rowLimit)
                let more = total - shown.count { !entry.ticked.contains($0.id) }
                VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
                    ForEach(shown) { item in
                        row(item)
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                if more > 0 {
                    Text("\(more) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
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
                    .contentTransition(.numericText())
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
        let isTicked = entry.ticked.contains(item.id)
        let title = item.title.isEmpty ? "Untitled Task" : item.title
        return HStack(spacing: 6) {
            Button(intent: TickTaskIntent(taskID: item.id)) {
                Image(systemName: isTicked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(color)
                    .imageScale(family == .systemSmall ? .small : .medium)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(minWidth: 16, minHeight: 16)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isTicked ? "Mark “\(title)” as Not Done" : "Mark “\(title)” as Done")
            Text(title)
                .font(family == .systemSmall ? .caption : .callout)
                .foregroundStyle(isTicked ? .secondary : .primary)
                .lineLimit(1)
            Spacer(minLength: 4)
            trailing(item)
        }
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

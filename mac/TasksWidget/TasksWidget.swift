import SwiftUI
import WidgetKit

@main
struct TasksWidgetBundle: WidgetBundle {
    var body: some Widget {
        DueWidget()
    }
}

struct DueWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.widgetKind, provider: DueProvider()) { entry in
            DueWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Due Today")
        .description("Tasks that are overdue or due today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct DueEntry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot?

    var today: Day { Day(date) }

    var due: (overdue: [WidgetSnapshot.Item], today: [WidgetSnapshot.Item]) {
        snapshot?.due(on: today) ?? ([], [])
    }

    static let placeholder = DueEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            isSignedIn: true,
            showsLists: false,
            items: [
                .init(id: "a", title: "Pay rent", listTitle: "My Tasks", color: "blue", due: Day.today().adding(days: -1).googleDue),
                .init(id: "b", title: "Call mom", listTitle: "Home", color: "green", due: Day.today().googleDue),
                .init(id: "c", title: "Send invoice", listTitle: "Work", color: "orange", due: Day.today().googleDue),
            ]
        )
    )
}

struct DueProvider: TimelineProvider {
    func placeholder(in context: Context) -> DueEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DueEntry) -> Void) {
        let snapshot = WidgetSnapshot.load()
        completion(context.isPreview && snapshot == nil ? .placeholder : DueEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DueEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date.now
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        let entries = [DueEntry(date: now, snapshot: snapshot), DueEntry(date: midnight, snapshot: snapshot)]
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(3_600))))
    }
}

struct DueWidgetView: View {
    let entry: DueEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let due = entry.due
        let rows = due.overdue.map { ($0, true) } + due.today.map { ($0, false) }
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            header(count: rows.count)
            if entry.snapshot?.isSignedIn != true {
                message("Open Tasks to sign in.")
            } else if rows.isEmpty {
                message("Nothing due.")
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
                    ForEach(rows.prefix(rowLimit), id: \.0.id) { item, overdue in
                        row(item, overdue: overdue)
                    }
                }
                if rows.count > rowLimit {
                    Text("\(rows.count - rowLimit) more")
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

    private func header(count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label("Today", systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(.blue)
            Spacer()
            if count > 0 {
                Text(count, format: .number)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(.blue)
            }
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func row(_ item: WidgetSnapshot.Item, overdue: Bool) -> some View {
        let color = (ListColor(rawValue: item.color) ?? .blue).color
        let dueText = Day(googleDue: item.due).map { DueText.text(for: $0, today: entry.today) }
        return HStack(spacing: 6) {
            Image(systemName: "circle")
                .foregroundStyle(color)
                .imageScale(.small)
            Text(item.title.isEmpty ? "Untitled Task" : item.title)
                .font(family == .systemSmall ? .caption : .callout)
                .lineLimit(1)
            Spacer(minLength: 4)
            if overdue, family != .systemSmall, let dueText {
                Text(dueText)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if family == .systemLarge, entry.snapshot?.showsLists == true {
                Text(item.listTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

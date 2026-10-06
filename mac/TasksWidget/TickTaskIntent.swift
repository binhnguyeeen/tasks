import AppIntents
import WidgetKit

struct TickTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Tick Off Task"
    static let isDiscoverable = false

    @Parameter(title: "Task")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        WidgetTicks.toggle(taskID)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

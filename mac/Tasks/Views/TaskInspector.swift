import SwiftUI

struct TaskInspector: View {
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window

    var body: some View {
        if let id = window.selectedTaskID, let task = store.task(id), !task.isPending {
            TaskDetailForm(task: task)
                .id(task.id)
        } else {
            ContentUnavailableView("No Selection", systemImage: "info.circle", description: Text("Select a task to see its details."))
        }
    }
}

struct InspectorPanel: View {
    let isShown: Bool
    @AppStorage("inspectorWidth") private var width = 280.0
    @State private var dragStartWidth: Double?

    var body: some View {
        HStack(spacing: 0) {
            Divider()
                .overlay {
                    Color.clear
                        .frame(width: 8)
                        .contentShape(.rect)
                        .onHover { inside in
                            if inside { NSCursor.columnResize.push() } else { NSCursor.pop() }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    let start = dragStartWidth ?? width
                                    dragStartWidth = start
                                    width = min(360, max(260, start - value.translation.width))
                                }
                                .onEnded { _ in dragStartWidth = nil }
                        )
                }
            TaskInspector()
                .frame(width: width)
        }
        .modifier(Reveal(fraction: isShown ? 1 : 0, width: width + 1))
        .allowsHitTesting(isShown)
        .accessibilityHidden(!isShown)
    }
}

private struct Reveal: ViewModifier, Animatable {
    var fraction: Double
    let width: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func body(content: Content) -> some View {
        content
            .frame(width: width, alignment: .leading)
            .frame(width: width * fraction, alignment: .trailing)
            .clipped()
    }
}

private struct TaskDetailForm: View {
    let task: TaskItem
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    @State private var title: String
    @State private var notes: String
    @State private var hasDue: Bool
    @State private var dueDate: Date
    @State private var isPickingDate = false
    @FocusState private var focus: Field?

    private enum Field {
        case title
        case notes
    }

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _hasDue = State(initialValue: task.due != nil)
        _dueDate = State(initialValue: (task.due ?? .today()).date())
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title, prompt: Text("Title"))
                    .font(.title3)
                    .labelsHidden()
                    .focused($focus, equals: .title)
                    .onSubmit(saveText)
                TextField("Notes", text: $notes, prompt: Text("Notes"), axis: .vertical)
                    .labelsHidden()
                    .lineLimit(2...8)
                    .focused($focus, equals: .notes)
                    .onSubmit(saveText)
            }
            Section {
                Toggle("Due Date", isOn: $hasDue)
                if hasDue {
                    LabeledContent("Date") {
                        Button(dueDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())) {
                            isPickingDate = true
                        }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $isPickingDate, arrowEdge: .bottom) {
                            DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .padding()
                        }
                    }
                }
            }
            Section {
                Picker("List", selection: Binding(
                    get: { task.listID },
                    set: { store.moveTask(task.id, to: $0) }
                )) {
                    ForEach(store.lists.filter { !$0.id.hasPrefix("local-") }) { list in
                        Text(list.title).tag(list.id)
                    }
                }
                .pickerStyle(.menu)
            }
            Section {
                Button("Delete Task…", role: .destructive) {
                    window.taskPendingDeletion = task
                }
            }
        }
        .formStyle(.grouped)
        .disabled(!store.canEdit)
        .onChange(of: focus) { old, new in
            if old != nil && old != new { saveText() }
        }
        .onChange(of: hasDue) { saveDue() }
        .onChange(of: dueDate) {
            isPickingDate = false
            saveDue()
        }
        .onDisappear(perform: saveText)
    }

    private func saveText() {
        guard store.task(task.id) != nil else { return }
        store.updateTask(task.id, title: title, notes: notes)
    }

    private func saveDue() {
        store.updateTask(task.id, due: .some(hasDue ? Day(dueDate) : nil))
    }
}

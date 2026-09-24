import SwiftUI

struct Checkbox: View {
    let isDone: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var bounce = 0

    var body: some View {
        Button(action: action) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .imageScale(.large)
                .foregroundStyle(style)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, options: .nonRepeating, value: bounce)
                .frame(minWidth: 24, minHeight: 24)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .onChange(of: isDone) { _, done in
            if done && !reduceMotion { bounce += 1 }
        }
        .help(isDone ? "Mark as Not Done" : "Mark as Done")
        .accessibilityLabel(isDone ? "Mark as Not Done" : "Mark as Done")
    }

    private var style: AnyShapeStyle {
        if !isEnabled { return AnyShapeStyle(.quaternary) }
        if isDone || isHovering { return AnyShapeStyle(tint) }
        return AnyShapeStyle(.tertiary)
    }
}

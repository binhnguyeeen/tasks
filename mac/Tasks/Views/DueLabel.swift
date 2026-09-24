import SwiftUI

struct DueLabel: View {
    let text: String
    let isOverdue: Bool
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Text(text)
            .foregroundStyle(style)
    }

    private var style: AnyShapeStyle {
        if prominence == .increased { return AnyShapeStyle(.secondary) }
        return isOverdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary)
    }
}

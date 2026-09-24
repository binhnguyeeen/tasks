import SwiftUI

nonisolated enum ListColor: String, CaseIterable, Identifiable, Sendable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case graphite

    var id: String { rawValue }

    var name: String {
        rawValue.capitalized
    }
}

nonisolated enum ListPalette {
    static let automatic: [ListColor] = [.blue, .orange, .green, .purple, .red, .yellow]

    static func automaticColor(for listID: String, isDefault: Bool) -> ListColor {
        if isDefault { return .blue }
        var hash: UInt32 = 2_166_136_261
        for byte in listID.utf8 {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }
        return automatic[Int(hash % UInt32(automatic.count))]
    }
}

extension ListColor {
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .graphite: .gray
        }
    }
}

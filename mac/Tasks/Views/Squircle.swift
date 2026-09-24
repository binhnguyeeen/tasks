import SwiftUI

enum Squircle {
    static let tile = RoundedRectangle(cornerRadius: 12, style: .continuous)
    static let field = RoundedRectangle(cornerRadius: 10, style: .continuous)
    static let row = RoundedRectangle(cornerRadius: 7, style: .continuous)
}

extension Shape where Self == RoundedRectangle {
    static var tileSquircle: RoundedRectangle { Squircle.tile }
    static var fieldSquircle: RoundedRectangle { Squircle.field }
    static var rowSquircle: RoundedRectangle { Squircle.row }
}

extension InsettableShape where Self == RoundedRectangle {
    static var tileSquircle: RoundedRectangle { Squircle.tile }
    static var fieldSquircle: RoundedRectangle { Squircle.field }
    static var rowSquircle: RoundedRectangle { Squircle.row }
}

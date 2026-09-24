import AppKit
import SwiftUI

struct QuickAddField: NSViewRepresentable {
    @Binding var text: String
    var highlight: NSRange?
    var placeholder: String
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> AutofocusTextField {
        let field = AutofocusTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .preferredFont(forTextStyle: .body)
        field.placeholderString = placeholder
        field.lineBreakMode = .byTruncatingTail
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        field.delegate = context.coordinator
        field.setAccessibilityLabel(placeholder)
        return field
    }

    func updateNSView(_ field: AutofocusTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        field.isEnabled = context.environment.isEnabled
        context.coordinator.applyHighlight(to: field)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: QuickAddField

        init(_ parent: QuickAddField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard selector == #selector(NSResponder.insertNewline(_:)) else { return false }
            parent.onSubmit()
            return true
        }

        func applyHighlight(to field: NSTextField) {
            guard let editor = field.currentEditor() as? NSTextView, let storage = editor.textStorage else { return }
            let whole = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.removeAttribute(.backgroundColor, range: whole)
            storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: whole)
            if let range = parent.highlight, NSMaxRange(range) <= storage.length {
                storage.addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: range)
                storage.addAttribute(.backgroundColor, value: NSColor.controlAccentColor.withAlphaComponent(0.15), range: range)
            }
            storage.endEditing()
            editor.typingAttributes[.foregroundColor] = NSColor.labelColor
            editor.typingAttributes[.backgroundColor] = nil
        }
    }
}

final class AutofocusTextField: NSTextField {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, window.firstResponder === window || window.firstResponder == nil else { return }
            window.makeFirstResponder(self)
        }
    }
}

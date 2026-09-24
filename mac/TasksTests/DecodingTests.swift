import Foundation
import Testing
@testable import Tasks

struct DecodingTests {
    private let json = """
    {
      "items": [
        {
          "kind": "tasks#task",
          "id": "abc",
          "title": "Pay rent",
          "notes": "Transfer before noon",
          "status": "needsAction",
          "due": "2026-09-18T00:00:00.000Z",
          "position": "00000000000000000001",
          "updated": "2026-09-17T08:00:00.000Z",
          "webViewLink": "https://tasks.google.com/task/abc"
        },
        {
          "id": "def",
          "title": "Book flights",
          "status": "completed",
          "completed": "2026-09-19T03:12:45.123Z",
          "parent": "trip",
          "position": "00000000000000000000",
          "hidden": true
        }
      ]
    }
    """

    private struct Page: Decodable {
        var items: [GoogleTask]
    }

    @Test func decodesGoogleTasks() throws {
        let page = try JSONDecoder().decode(Page.self, from: Data(json.utf8))
        let items = page.items.map { TaskItem($0, listID: "mine") }
        #expect(items[0].title == "Pay rent")
        #expect(items[0].due == Day(year: 2026, month: 9, day: 18))
        #expect(items[0].isDone == false)
        #expect(items[0].isOverdue(today: Day(year: 2026, month: 9, day: 19)!))
        #expect(items[1].isDone)
        #expect(items[1].parentID == "trip")
        #expect(items[1].completedAt != nil)
    }

    @Test func patchesSendNullToClearFields() throws {
        let patch = TaskPatch(notes: .some(nil), due: .some(nil), status: .needsAction, completed: .some(nil))
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(patch)) as? [String: Any]
        #expect(object?["title"] == nil)
        #expect(object?["notes"] is NSNull)
        #expect(object?["due"] is NSNull)
        #expect(object?["completed"] is NSNull)
        #expect(object?["status"] as? String == "needsAction")
    }

    @Test func patchesLeaveOutUntouchedFields() throws {
        let patch = TaskPatch(status: .completed)
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(patch)) as? [String: Any]
        #expect(object?.keys.sorted() == ["status"])
    }

    @Test func readsTheEmailFromAnIDToken() {
        let payload = Data(#"{"email":"someone@example.com"}"#.utf8).base64URLEncodedString()
        #expect(GoogleAuth.email(fromIDToken: "header.\(payload).signature") == "someone@example.com")
    }

    @Test func pkceChallengeMatchesTheRFCExample() {
        #expect(PKCE.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk") == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func listColorsAreStableAndMyTasksIsBlue() {
        #expect(ListPalette.automaticColor(for: "anything", isDefault: true) == .blue)
        #expect(ListPalette.automaticColor(for: "work-list", isDefault: false) == ListPalette.automaticColor(for: "work-list", isDefault: false))
        #expect(!ListPalette.automatic.contains(.graphite))
    }
}

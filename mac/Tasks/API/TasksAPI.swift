import Foundation

nonisolated enum TasksAPIError: Error, Sendable {
    case offline
    case http(status: Int, message: String)
    case invalidResponse
}

actor TasksAPI {
    typealias TokenProvider = @Sendable (_ forceRefresh: Bool) async throws -> String

    private let token: TokenProvider
    private let session: URLSession
    private let base = "https://tasks.googleapis.com/tasks/v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    static let uncachedSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    init(session: URLSession = TasksAPI.uncachedSession, token: @escaping TokenProvider) {
        self.session = session
        self.token = token
    }

    func taskLists() async throws -> [TaskList] {
        var lists: [TaskList] = []
        var pageToken: String?
        repeat {
            let page: Page<TaskList> = try await get("/users/@me/lists", query: ["maxResults": "100", "pageToken": pageToken])
            lists += page.items ?? []
            pageToken = page.nextPageToken
        } while pageToken != nil
        return lists
    }

    func defaultTaskList() async throws -> TaskList {
        try await get("/users/@me/lists/@default")
    }

    func insertList(title: String) async throws -> TaskList {
        try await send("POST", "/users/@me/lists", body: ListTitle(title: title))
    }

    func renameList(_ listID: String, title: String) async throws -> TaskList {
        try await send("PATCH", "/users/@me/lists/\(escape(listID))", body: ListTitle(title: title))
    }

    func deleteList(_ listID: String) async throws {
        _ = try await data("DELETE", "/users/@me/lists/\(escape(listID))")
    }

    func tasks(in listID: String) async throws -> [GoogleTask] {
        var tasks: [GoogleTask] = []
        var pageToken: String?
        repeat {
            let page: Page<GoogleTask> = try await get(
                "/lists/\(escape(listID))/tasks",
                query: [
                    "maxResults": "100",
                    "showCompleted": "true",
                    "showHidden": "true",
                    "pageToken": pageToken,
                ]
            )
            tasks += page.items ?? []
            pageToken = page.nextPageToken
        } while pageToken != nil
        return tasks.filter { $0.deleted != true }
    }

    func insertTask(_ task: NewTask, in listID: String, parent: String?, previous: String?) async throws -> GoogleTask {
        try await send(
            "POST",
            "/lists/\(escape(listID))/tasks",
            query: ["parent": parent, "previous": previous],
            body: task
        )
    }

    func patchTask(_ taskID: String, in listID: String, patch: TaskPatch) async throws -> GoogleTask {
        try await send("PATCH", "/lists/\(escape(listID))/tasks/\(escape(taskID))", body: patch)
    }

    func moveTask(
        _ taskID: String,
        from listID: String,
        to destinationID: String? = nil,
        parent: String? = nil,
        previous: String? = nil
    ) async throws -> GoogleTask {
        let data = try await data(
            "POST",
            "/lists/\(escape(listID))/tasks/\(escape(taskID))/move",
            query: ["destinationTasklist": destinationID, "parent": parent, "previous": previous]
        )
        return try decoder.decode(GoogleTask.self, from: data)
    }

    func deleteTask(_ taskID: String, in listID: String) async throws {
        _ = try await data("DELETE", "/lists/\(escape(listID))/tasks/\(escape(taskID))")
    }

    private struct Page<Item: Decodable & Sendable>: Decodable, Sendable {
        var items: [Item]?
        var nextPageToken: String?
    }

    private struct ErrorBody: Decodable {
        struct Detail: Decodable { var message: String? }
        var error: Detail?
    }

    private func get<T: Decodable>(_ path: String, query: [String: String?] = [:]) async throws -> T {
        try decoder.decode(T.self, from: try await data("GET", path, query: query))
    }

    private func send<T: Decodable>(_ method: String, _ path: String, query: [String: String?] = [:], body: some Encodable) async throws -> T {
        let payload = try encoder.encode(body)
        return try decoder.decode(T.self, from: try await data(method, path, query: query, body: payload))
    }

    private func data(_ method: String, _ path: String, query: [String: String?] = [:], body: Data? = nil) async throws -> Data {
        guard var components = URLComponents(string: base + path) else { throw TasksAPIError.invalidResponse }
        let items = query.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }
        if !items.isEmpty { components.queryItems = items.sorted { $0.name < $1.name } }
        guard let url = components.url else { throw TasksAPIError.invalidResponse }

        var (payload, response) = try await perform(method, url: url, body: body, forceRefresh: false)
        if response.statusCode == 401 {
            (payload, response) = try await perform(method, url: url, body: body, forceRefresh: true)
        }
        guard (200..<300).contains(response.statusCode) else {
            let message = (try? decoder.decode(ErrorBody.self, from: payload))?.error?.message ?? ""
            throw TasksAPIError.http(status: response.statusCode, message: message)
        }
        return payload
    }

    private func perform(_ method: String, url: URL, body: Data?, forceRefresh: Bool) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(try await token(forceRefresh))", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        do {
            let (payload, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TasksAPIError.invalidResponse }
            return (payload, http)
        } catch let error as URLError where error.isConnectivityProblem {
            throw TasksAPIError.offline
        }
    }

    private func escape(_ id: String) -> String {
        id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? id
    }
}

nonisolated extension URLError {
    var isConnectivityProblem: Bool {
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
             .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
            true
        default:
            false
        }
    }
}

import Foundation

enum SupabaseError: Error, LocalizedError {
    case authExpired
    case http(Int, String)
    case decode(String)
    var errorDescription: String? {
        switch self {
        case .authExpired: return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại"
        case .http(let c, let b): return "HTTP \(c): \(b.prefix(200))"
        case .decode(let m): return "Decode error: \(m)"
        }
    }
}

actor SupabaseApi {
    static let shared = SupabaseApi()

    private(set) var currentToken: String?
    private(set) var currentRefreshToken: String?
    var onTokensRefreshed: ((String, String?) async -> Void)?
    var onAuthExpired: (() async -> Void)?

    func setTokens(token: String?, refresh: String?) {
        self.currentToken = token
        self.currentRefreshToken = refresh
    }
    func setOnTokensRefreshed(_ cb: @escaping (String, String?) async -> Void) { self.onTokensRefreshed = cb }
    func setOnAuthExpired(_ cb: @escaping () async -> Void) { self.onAuthExpired = cb }

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 20
        c.timeoutIntervalForResource = 20
        return URLSession(configuration: c)
    }()

    private let decoder: JSONDecoder = { let d = JSONDecoder(); return d }()
    private let encoder: JSONEncoder = { let e = JSONEncoder(); return e }()

    private func headers(token: String?) -> [String: String] {
        [
            "apikey": Config.supabaseAnonKey,
            "Authorization": "Bearer \(token ?? Config.supabaseAnonKey)",
            "Content-Type": "application/json"
        ]
    }

    private func makeRequest(_ url: URL, method: String, token: String?, body: Data? = nil, prefer: String? = nil) -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = method
        for (k, v) in headers(token: token) { r.setValue(v, forHTTPHeaderField: k) }
        if let p = prefer { r.setValue(p, forHTTPHeaderField: "Prefer") }
        r.httpBody = body
        return r
    }

    private func refreshAccessToken() async -> String? {
        guard let rt = currentRefreshToken, !rt.isEmpty else { return nil }
        let url = URL(string: "\(Config.supabaseURL)/auth/v1/token?grant_type=refresh_token")!
        let body = try? JSONSerialization.data(withJSONObject: ["refresh_token": rt])
        let req = makeRequest(url, method: "POST", token: nil, body: body)
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            let auth = try decoder.decode(AuthResponse.self, from: data)
            guard let newAccess = auth.access_token else { return nil }
            currentToken = newAccess
            if let nr = auth.refresh_token, !nr.isEmpty { currentRefreshToken = nr }
            await onTokensRefreshed?(newAccess, auth.refresh_token)
            return newAccess
        } catch { return nil }
    }

    private func executeAuthed(makeReq: (String) -> URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let t = currentToken else { throw SupabaseError.authExpired }
        var (data, resp) = try await session.data(for: makeReq(t))
        var http = resp as! HTTPURLResponse
        if http.statusCode == 401 || http.statusCode == 403 {
            guard let nt = await refreshAccessToken() else {
                await onAuthExpired?()
                throw SupabaseError.authExpired
            }
            (data, resp) = try await session.data(for: makeReq(nt))
            http = resp as! HTTPURLResponse
            if http.statusCode == 401 || http.statusCode == 403 {
                await onAuthExpired?()
                throw SupabaseError.authExpired
            }
        }
        return (data, http)
    }

    // MARK: - Auth
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(Config.supabaseURL)/auth/v1/token?grant_type=password")!
        let body = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let req = makeRequest(url, method: "POST", token: nil, body: body)
        let (data, _) = try await session.data(for: req)
        return try decoder.decode(AuthResponse.self, from: data)
    }

    func getMyEmployee(userId: String) async throws -> Employee? {
        let urlStr = "\(Config.supabaseURL)/rest/v1/employees?user_id=eq.\(userId)&select=id,full_name,employee_code,position,department,user_id,is_active&limit=1"
        let url = URL(string: urlStr)!
        let (data, http) = try await executeAuthed { t in self.makeRequest(url, method: "GET", token: t) }
        guard (200..<300).contains(http.statusCode) else { return nil }
        return (try? decoder.decode([Employee].self, from: data))?.first
    }

    func getTodayAttendance(employeeId: String, date: String) async throws -> AttendanceRecord? {
        let urlStr = "\(Config.supabaseURL)/rest/v1/attendance_records?employee_id=eq.\(employeeId)&work_date=eq.\(date)&select=*&limit=1"
        let url = URL(string: urlStr)!
        let (data, http) = try await executeAuthed { t in self.makeRequest(url, method: "GET", token: t) }
        guard (200..<300).contains(http.statusCode) else { return nil }
        return (try? decoder.decode([AttendanceRecord].self, from: data))?.first
    }

    func checkIn(record: AttendanceRecord) async throws {
        let url = URL(string: "\(Config.supabaseURL)/rest/v1/attendance_records")!
        let body = try encoder.encode(record)
        let (data, http) = try await executeAuthed { t in
            self.makeRequest(url, method: "POST", token: t, body: body, prefer: "return=minimal")
        }
        if !(200..<300).contains(http.statusCode) {
            throw SupabaseError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func updateCheckOut(recordId: String, checkOut: String) async throws {
        let url = URL(string: "\(Config.supabaseURL)/rest/v1/attendance_records?id=eq.\(recordId)")!
        let body = try JSONSerialization.data(withJSONObject: ["check_out": checkOut])
        _ = try await executeAuthed { t in
            self.makeRequest(url, method: "PATCH", token: t, body: body, prefer: "return=minimal")
        }
    }

    func getLeaveRequests(employeeId: String) async throws -> [LeaveRequest] {
        let urlStr = "\(Config.supabaseURL)/rest/v1/leave_requests?employee_id=eq.\(employeeId)&select=*&order=created_at.desc&limit=50"
        let url = URL(string: urlStr)!
        let (data, http) = try await executeAuthed { t in self.makeRequest(url, method: "GET", token: t) }
        guard (200..<300).contains(http.statusCode) else { return [] }
        return (try? decoder.decode([LeaveRequest].self, from: data)) ?? []
    }

    func getAttendanceMonth(employeeId: String, from: String, to: String) async throws -> [AttendanceRecord] {
        let urlStr = "\(Config.supabaseURL)/rest/v1/attendance_records?employee_id=eq.\(employeeId)&work_date=gte.\(from)&work_date=lte.\(to)&select=*&order=work_date.desc"
        let url = URL(string: urlStr)!
        let (data, http) = try await executeAuthed { t in self.makeRequest(url, method: "GET", token: t) }
        guard (200..<300).contains(http.statusCode) else { return [] }
        return (try? decoder.decode([AttendanceRecord].self, from: data)) ?? []
    }
}

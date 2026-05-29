import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    struct Session: Equatable {
        var token: String?
        var refreshToken: String?
        var userId: String?
        var employeeId: String?
        var employeeName: String?
        var position: String?
        var department: String?
    }

    @Published private(set) var session = Session()
    @Published var isLoading = true

    private let d = UserDefaults.standard
    private let kToken = "kba.token"
    private let kRefresh = "kba.refresh"
    private let kUser = "kba.user"
    private let kEmpId = "kba.empId"
    private let kEmpName = "kba.empName"
    private let kPos = "kba.pos"
    private let kDep = "kba.dep"

    func load() {
        session = Session(
            token: d.string(forKey: kToken),
            refreshToken: d.string(forKey: kRefresh),
            userId: d.string(forKey: kUser),
            employeeId: d.string(forKey: kEmpId),
            employeeName: d.string(forKey: kEmpName),
            position: d.string(forKey: kPos),
            department: d.string(forKey: kDep)
        )
        isLoading = false
    }

    var isLoggedIn: Bool {
        !(session.token?.isEmpty ?? true) && !(session.employeeId?.isEmpty ?? true)
    }

    func save(token: String, refresh: String?, userId: String, empId: String, name: String, pos: String?, dep: String?) {
        d.set(token, forKey: kToken)
        d.set(refresh ?? "", forKey: kRefresh)
        d.set(userId, forKey: kUser)
        d.set(empId, forKey: kEmpId)
        d.set(name, forKey: kEmpName)
        d.set(pos ?? "", forKey: kPos)
        d.set(dep ?? "", forKey: kDep)
        load()
    }

    func updateTokens(token: String, refresh: String?) {
        d.set(token, forKey: kToken)
        if let r = refresh, !r.isEmpty { d.set(r, forKey: kRefresh) }
        load()
    }

    func clear() {
        [kToken, kRefresh, kUser, kEmpId, kEmpName, kPos, kDep].forEach { d.removeObject(forKey: $0) }
        load()
    }
}

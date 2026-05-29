import Foundation

struct AuthUser: Codable { let id: String; let email: String? }

struct AuthResponse: Codable {
    let access_token: String?
    let refresh_token: String?
    let expires_in: Int?
    let user: AuthUser?
    let error: String?
    let error_description: String?
    let msg: String?
}

struct Employee: Codable, Identifiable {
    let id: String
    let full_name: String
    let employee_code: String?
    let position: String?
    let department: String?
    let user_id: String?
    let is_active: Bool?
}

struct AttendanceRecord: Codable, Identifiable {
    var id: String?
    let employee_id: String
    let work_date: String
    var check_in: String?
    var check_out: String?
    var status: String = "present"
    var notes: String?
    var off_site: Bool? = false
}

struct LeaveRequest: Codable, Identifiable {
    let id: String
    let employee_id: String
    let leave_type: String
    let start_date: String
    let end_date: String
    let total_days: Double?
    let reason: String?
    let status: String
    let approved_at: String?
    let created_at: String?
}

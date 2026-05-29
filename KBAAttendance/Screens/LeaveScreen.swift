import SwiftUI

func fmtDate(_ s: String) -> String {
    guard s.count >= 10 else { return s }
    let p = s.prefix(10).split(separator: "-")
    guard p.count == 3 else { return s }
    return "\(p[2])/\(p[1])/\(p[0])"
}

private func statusLabel(_ s: String) -> (String, Color) {
    switch s {
    case "approved": return ("Đã duyệt", Color(red: 0.09, green: 0.64, blue: 0.29))
    case "rejected": return ("Từ chối", Color(red: 0.86, green: 0.15, blue: 0.15))
    case "pending": return ("Chờ duyệt", Color(red: 0.85, green: 0.47, blue: 0.02))
    default: return (s, .gray)
    }
}

struct LeaveScreen: View {
    @EnvironmentObject var store: SessionStore
    @State private var items: [LeaveRequest] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let e = error {
                Text(e).foregroundColor(.red).padding()
            } else if items.isEmpty {
                Text("Chưa có đơn nghỉ phép nào").padding()
            } else {
                List(items) { lr in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(lr.leave_type.capitalized).font(.headline)
                            Spacer()
                            let (label, color) = statusLabel(lr.status)
                            Text(label).font(.caption).bold().padding(.horizontal, 8).padding(.vertical, 3)
                                .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(8)
                        }
                        Text("Từ \(fmtDate(lr.start_date)) → \(fmtDate(lr.end_date)) (\(String(format: "%g", lr.total_days ?? 1)) ngày)")
                            .font(.subheadline)
                        if let r = lr.reason, !r.isEmpty {
                            Text("Lý do: \(r)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Đơn nghỉ phép")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let emp = store.session.employeeId else { loading = false; return }
            do { items = try await SupabaseApi.shared.getLeaveRequests(employeeId: emp) }
            catch { self.error = error.localizedDescription }
            loading = false
        }
    }
}

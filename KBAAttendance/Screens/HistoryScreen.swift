import SwiftUI

struct HistoryScreen: View {
    @EnvironmentObject var store: SessionStore
    @State private var items: [AttendanceRecord] = []
    @State private var loading = true

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if items.isEmpty {
                Text("Chưa có chấm công trong tháng").padding()
            } else {
                List(items, id: \.work_date) { r in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fmtDate(r.work_date)).font(.headline)
                        HStack {
                            Text("Vào: \(r.check_in ?? "—")")
                            Spacer()
                            Text("Ra: \(r.check_out ?? "—")")
                        }.font(.subheadline)
                        if r.off_site == true { Text("📍 Ngoài site").font(.caption).foregroundColor(.secondary) }
                        if let n = r.notes, !n.isEmpty { Text(n).font(.caption).foregroundColor(.secondary) }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Lịch sử chấm công")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let emp = store.session.employeeId else { loading = false; return }
            let cal = Calendar(identifier: .gregorian)
            let now = Date()
            let comps = cal.dateComponents([.year, .month], from: now)
            let first = cal.date(from: comps)!
            let range = cal.range(of: .day, in: .month, for: first)!
            let last = cal.date(byAdding: DateComponents(day: range.count - 1), to: first)!
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
            items = (try? await SupabaseApi.shared.getAttendanceMonth(employeeId: emp, from: f.string(from: first), to: f.string(from: last))) ?? []
            loading = false
        }
    }
}

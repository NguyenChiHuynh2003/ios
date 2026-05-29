import SwiftUI

private let vnTZ = TimeZone(identifier: "Asia/Ho_Chi_Minh")!

private let dateFmtAPI: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = vnTZ
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private let timeFmt: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = vnTZ
    f.dateFormat = "HH:mm:ss"
    return f
}()

private let displayFmt: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "vi_VN")
    f.timeZone = vnTZ
    f.dateFormat = "EEEE, dd/MM/yyyy"
    return f
}()

struct HomeScreen: View {
    @EnvironmentObject var store: SessionStore
    @State private var today: AttendanceRecord?
    @State private var loading = false
    @State private var msg: String?
    @State private var offSite = false
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Greeting card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Xin chào,").font(.caption).foregroundColor(.secondary)
                        Text(store.session.employeeName ?? "...").font(.title3).bold()
                        let sub = [store.session.position, store.session.department].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • ")
                        if !sub.isEmpty { Text(sub).font(.caption).foregroundColor(.secondary) }
                        Text(displayFmt.string(from: Date()).capitalized).font(.caption).padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Today attendance card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chấm công hôm nay").font(.headline)
                        Text("Vào: \(today?.check_in ?? "—")")
                        Text("Ra:  \(today?.check_out ?? "—")")
                        if today?.off_site == true {
                            Text("📍 Ngoài site").font(.caption)
                        }
                        Toggle("Đi công tác (ngoài site)", isOn: $offSite)
                            .disabled(today != nil)
                        TextField("Ghi chú (tuỳ chọn)", text: $notes)
                            .textFieldStyle(.roundedBorder)
                            .disabled(today != nil)

                        Button(action: doCheckIn) {
                            HStack {
                                if loading { ProgressView().tint(.white) }
                                Text(today == nil ? "Chấm công" : "Đã chấm công hôm nay").bold()
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(today != nil ? Color.gray : Color(red: 0.07, green: 0.45, blue: 0.20))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(today != nil || loading)

                        if let m = msg { Text(m).font(.footnote) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(red: 0.86, green: 0.95, blue: 0.88))
                    .cornerRadius(12)

                    NavigationLink(destination: LeaveScreen()) {
                        navRow(icon: "calendar.badge.clock", title: "Đơn nghỉ phép", sub: "Xem trạng thái duyệt")
                    }
                    NavigationLink(destination: HistoryScreen()) {
                        navRow(icon: "clock.arrow.circlepath", title: "Lịch sử chấm công", sub: "Tháng hiện tại")
                    }
                    NavigationLink(destination: GuideScreen()) {
                        navRow(icon: "questionmark.circle", title: "Hướng dẫn sử dụng", sub: "Cách dùng app KBA Chấm công")
                    }
                }
                .padding()
            }
            .navigationTitle("KBA Chấm công")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { store.clear() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .task { await reload() }
        }
        .navigationViewStyle(.stack)
    }

    private func navRow(icon: String, title: String, sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundColor(Color(red: 0.07, green: 0.45, blue: 0.20))
            VStack(alignment: .leading) {
                Text(title).font(.body).foregroundColor(.primary)
                Text(sub).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func reload() async {
        guard let emp = store.session.employeeId else { return }
        let date = dateFmtAPI.string(from: Date())
        today = try? await SupabaseApi.shared.getTodayAttendance(employeeId: emp, date: date)
    }

    private func doCheckIn() {
        guard let emp = store.session.employeeId else { return }
        loading = true; msg = nil
        Task { @MainActor in
            defer { loading = false }
            let date = dateFmtAPI.string(from: Date())
            do {
                if let existing = try await SupabaseApi.shared.getTodayAttendance(employeeId: emp, date: date) {
                    today = existing
                    msg = "Bạn đã chấm công hôm nay rồi. Mai mới được chấm tiếp."
                    return
                }
                let now = timeFmt.string(from: Date())
                let rec = AttendanceRecord(
                    id: nil, employee_id: emp, work_date: date,
                    check_in: now, check_out: "17:00:00",
                    status: "present", notes: notes.isEmpty ? nil : notes, off_site: offSite
                )
                try await SupabaseApi.shared.checkIn(record: rec)
                msg = "Đã chấm công lúc \(now) (giờ ra mặc định 17:00)"
                await reload()
                if today == nil { today = rec }
            } catch {
                let em = error.localizedDescription
                if em.contains("23505") || em.lowercased().contains("duplicate") || em.contains("409") {
                    today = (try? await SupabaseApi.shared.getTodayAttendance(employeeId: emp, date: date))
                    msg = "Bạn đã chấm công hôm nay rồi. Mai mới được chấm tiếp."
                } else {
                    msg = "Lỗi: \(em)"
                }
            }
        }
    }
}

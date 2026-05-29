import SwiftUI

struct GuideScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                section("1. Đăng nhập",
                        "Dùng đúng email + mật khẩu nội bộ KBA (giống tài khoản trên kba2018.vn/noi-bo).")
                section("2. Chấm công hôm nay",
                        "Mở app → nhấn nút Chấm công. Giờ vào lấy theo giờ Việt Nam, giờ ra mặc định 17:00. Mỗi ngày chỉ chấm 1 lần.")
                section("3. Đi công tác (ngoài site)",
                        "Bật công tắc “Đi công tác” trước khi bấm Chấm công nếu hôm đó làm việc ngoài văn phòng.")
                section("4. Đơn nghỉ phép",
                        "Xem trạng thái Chờ duyệt / Đã duyệt / Từ chối các đơn đã gửi.")
                section("5. Lịch sử chấm công",
                        "Xem toàn bộ ngày đã chấm công trong tháng hiện tại.")
                section("6. Đăng xuất",
                        "Bấm nút Đăng xuất ở góc trên bên phải màn hình chính.")
            }
            .padding()
        }
        .navigationTitle("Hướng dẫn sử dụng")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(body).font(.body).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

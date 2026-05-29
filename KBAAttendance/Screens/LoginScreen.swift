import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var store: SessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .padding(.top, 24)
                    Text("Đăng nhập").font(.title).bold()

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Mật khẩu", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if let e = error {
                        Text(e).foregroundColor(.red).font(.footnote)
                    }

                    Button(action: signIn) {
                        HStack {
                            if loading { ProgressView().tint(.white) }
                            Text("Đăng nhập").bold()
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background((email.isEmpty || password.isEmpty || loading) ? Color.gray : Color(red: 0.07, green: 0.45, blue: 0.20))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || loading)

                    Text("Sử dụng tài khoản nội bộ kba2018.vn")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(24)
            }
            .navigationTitle("KBA Chấm công")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private func signIn() {
        error = nil
        loading = true
        Task { @MainActor in
            defer { loading = false }
            do {
                let res = try await SupabaseApi.shared.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
                guard let token = res.access_token, let uid = res.user?.id else {
                    error = res.error_description ?? res.msg ?? "Đăng nhập thất bại"; return
                }
                await SupabaseApi.shared.setTokens(token: token, refresh: res.refresh_token)
                guard let emp = try await SupabaseApi.shared.getMyEmployee(userId: uid) else {
                    error = "Không tìm thấy hồ sơ nhân viên"; return
                }
                if emp.is_active == false {
                    error = "Tài khoản đã bị vô hiệu hoá"; return
                }
                store.save(token: token, refresh: res.refresh_token, userId: uid, empId: emp.id, name: emp.full_name, pos: emp.position, dep: emp.department)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

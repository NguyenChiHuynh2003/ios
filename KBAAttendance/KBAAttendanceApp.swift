import SwiftUI

@main
struct KBAAttendanceApp: App {
    @StateObject private var store = SessionStore()

    init() {
        // Brand: primary green
        UINavigationBar.appearance().tintColor = UIColor(red: 0.07, green: 0.45, blue: 0.20, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    store.load()
                    let s = store.session
                    await SupabaseApi.shared.setTokens(token: s.token, refresh: s.refreshToken)
                    await SupabaseApi.shared.setOnTokensRefreshed { [weak store] access, refresh in
                        await MainActor.run { store?.updateTokens(token: access, refresh: refresh) }
                    }
                    await SupabaseApi.shared.setOnAuthExpired { [weak store] in
                        await MainActor.run { store?.clear() }
                    }
                }
                .tint(Color(red: 0.07, green: 0.45, blue: 0.20))
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: SessionStore
    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
            } else if store.isLoggedIn {
                HomeScreen()
            } else {
                LoginScreen()
            }
        }
    }
}

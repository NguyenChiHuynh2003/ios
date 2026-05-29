# KBA Chấm công (iOS)

Ứng dụng iOS native viết bằng SwiftUI, dùng chung backend Supabase với app Android KBA.

## Yêu cầu
- Xcode 14.2 trở lên
- iOS 15.0+ (hỗ trợ iPhone X trở lên), portrait only, iPhone only
- Swift 5.7 (không dùng macro/API mới của Swift 5.9 / iOS 17)

## Mở dự án
Dự án đã có sẵn `KBAAttendance.xcodeproj` được commit vào repo. Sau khi clone, chỉ cần:

```bash
open KBAAttendance.xcodeproj
```

Không cần cài `xcodegen` hay chạy bất kỳ lệnh sinh project nào. Nhấn Run trong Xcode 14.2 là build được ngay.

## Cấu hình
- Bundle ID: `vn.kba2018.attendance`
- Supabase URL & anon key được cấu hình trong `KBAAttendance/Config.swift`.

## Tuỳ chọn: regenerate bằng XcodeGen
File `project.yml` vẫn được giữ để tham khảo / regenerate khi cần:

```bash
brew install xcodegen
xcodegen generate
```

## Cấu trúc
```
KBAAttendance/
├── KBAAttendance.xcodeproj/        # Project Xcode native (đã commit)
├── KBAAttendance/
│   ├── KBAAttendanceApp.swift      # @main entry
│   ├── Config.swift                # Supabase URL/key
│   ├── SessionStore.swift          # Auth session lưu Keychain/UserDefaults
│   ├── Info.plist                  # Portrait, iPhone only
│   ├── Api/                        # SupabaseApi, Models
│   ├── Screens/                    # Login, Home, Leave, History, Guide
│   └── Assets.xcassets/            # Logo, AppIcon, AccentColor
├── project.yml                     # (tuỳ chọn) spec cho XcodeGen
└── README.md
```
# ios

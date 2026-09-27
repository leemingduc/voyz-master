# Thiết kế Kỹ thuật: Tinh Chỉnh UI, Cài Đặt Âm Thanh Profile, Đồng Bộ Supabase & Ngôn Ngữ Mặc Định

**Ngày:** 2026-09-27  
**Nhánh:** `image-loading-effects`  
**Mục tiêu:**
1. Biến nút AI Tool thành nút icon tròn đặc trưng AIVIVU không chữ, nâng vị trí lên trên để không che nút gửi tin nhắn.
2. Xóa nút âm thanh nổi trên màn hình chính, chuyển vào màn hình Profile thành một dòng cài đặt ngang có hiển thị trạng thái Bật/Tắt rõ ràng.
3. Đảm bảo lưu địa điểm luôn đồng bộ lên bảng `saved_trips` trong Supabase và bổ sung nút bookmark trên đầu màn hình chi tiết điểm đến.
4. Thiết lập ngôn ngữ mặc định khi mở app là Tiếng Việt (`vi`).

---

## 1. Nút AI Tool nổi (`AIToolsButton`)

### 1.1 Giao diện & Kích thước
- Chuyển `FloatingActionButton.extended` thành nút tròn độc đáo:
  - Đường kính 50x50 px, bo tròn (`BoxShape.circle`).
  - Nền gradient thương hiệu AIVIVU (`AppTheme.brandGradient`).
  - Viền mỏng `Border.all(color: AppTheme.cyan.withValues(alpha: 0.5), width: 1.5)`.
  - Icon: `Icons.auto_awesome` màu trắng, kích thước 22, có bóng đổ nhẹ.
  - Không có text nhãn "AI Tools" để tối ưu không gian hiển thị.

### 1.2 Tọa độ vị trí (`lib/main.dart`)
- `bottom: MediaQuery.of(context).padding.bottom + 124` (tăng từ 92 lên 124).
- `right: 16`.
- Khoảng cách này đảm bảo nằm cao hơn thanh dock chat (vốn ở 76-80px), không bao giờ che khuất nút gửi của ô nhập prompt.

---

## 2. Di chuyển nút âm thanh vào Profile (`ProfileScreen`)

### 2.1 Xóa overlay trong `main.dart`
- Loại bỏ `Positioned` chứa `BackgroundMusicButton` khỏi `Stack` trong `lib/main.dart`.

### 2.2 Dòng cài đặt âm thanh trong `ProfileScreen`
- Thêm một thẻ cài đặt ngang (`_MusicSettingTile`) trong danh sách cài đặt:
  - Bên trái: Vòng tròn icon nốt nhạc gradient tím hồng (`Icons.music_note` khi bật, `Icons.music_off` khi tắt).
  - Ở giữa:
    - Tiêu đề: *"Âm thanh nền vũ trụ"*
    - Trạng thái: *"Đang bật"* (màu `AppTheme.cyan`) hoặc *"Đang tắt"* (màu `Colors.white54`).
  - Bên phải: `Switch` tùy chỉnh với màu `AppTheme.primaryPink`, gọi `BackgroundMusicService.instance.toggle()`.
  - Lắng nghe trạng thái thay đổi qua `ValueNotifier` trong `BackgroundMusicService`.

---

## 3. Đồng bộ lưu địa điểm vào Supabase (`SavedTripsProvider` & `DestinationDetailScreen`)

### 3.1 Nút Bookmark ở đầu màn hình `DestinationDetailScreen`
- Trong `_HeroSection` (thanh điều hướng phía trên):
  - Bên cạnh nút Share, bổ sung nút `_CircleBtn`:
    - Nếu đã lưu: Icon `Icons.bookmark` màu tím hồng (`AppTheme.primaryPink`).
    - Nếu chưa lưu: Icon `Icons.bookmark_border` màu trắng.
    - Nhấn vào: Gọi `_onSaveInfo(context)`.

### 3.2 Kiểm tra trạng thái đã lưu khi mở màn hình
- Trong `_loadDetail` hoặc sau khi frame render:
  - Đối chiếu `widget.destinationName` với `SavedTripsProvider.of(context).savedItems`.
  - Nếu đã tồn tại, gán `_savedItem` tương ứng để đồng bộ trạng thái ngay lập tức.

### 3.3 Cơ chế lưu vào Supabase
- Hàm `saveFullTrip()` trong `SavedTripsProvider` gọi `_upsertItem()`.
- Ghi dữ liệu vào bảng `saved_trips` trên Supabase:
  - Nếu người dùng đã đăng nhập (`userId != 'anonymous'`), gửi request `upsert` với `user_id` và `name`.
  - Lưu vào local cache Hive để người dùng thấy ngay cả khi mạng chậm.
  - Khi mở app lại, `SavedTripsProvider.load()` tải từ `saved_trips` xuống và hiển thị đầy đủ.

---

## 4. Ngôn ngữ mặc định là Tiếng Việt (`vi`)

### 4.1 Cập nhật `LocaleSettingsStore.load`
- Trong `lib/data/locale_provider.dart`:
  - `final saved = box.get(_languageCodeKey);`
  - Nếu `saved == null`: mặc định chọn `'vi'` (thay vì lấy `deviceLocale.languageCode`).
- Trong `lib/main.dart`:
  - Khởi tạo fallback locale: `initialLocale = const Locale('vi')`.
  - Trong `localeResolutionCallback`: fallback về `const Locale('vi')`.

---

## 5. Kế hoạch kiểm thử & nghiệm thu
- Widget test cho `AIToolsButton` dạng icon-only.
- Widget test cho `DestinationDetailScreen` với nút bookmark trên hero header.
- Unit test cho `LocaleSettingsStore.load()` mặc định là `'vi'`.
- Chạy `flutter analyze` và `flutter test` đảm bảo 100% pass.

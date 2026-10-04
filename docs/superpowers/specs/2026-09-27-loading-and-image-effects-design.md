# Thiết kế Kỹ thuật: Hiệu ứng Loading & Tải Ảnh cho AIVIVU

**Ngày:** 2026-09-27  
**Nhánh:** `image-loading-effects`  
**Mục tiêu:** Nâng cấp trải nghiệm người dùng trong quá trình chờ AI phản hồi và tải ảnh điểm đến:
1. Hiệu ứng gõ chữ Messenger (`TypingBubble` / 3 bouncing dots) thay cho spinner đơn điệu khi AI đang soạn câu trả lời.
2. Hiệu ứng chờ gợi ý chuyến đi (`PlannerGeneratingCard`) với thông điệp luân phiên và hiệu ứng phát sáng chuyển động (cosmic shimmer).
3. Hiệu ứng tải ảnh điểm đến (`DestinationImage`) với skeleton shimmer wave và chuyển cảnh fade-in mềm mại.

---

## 1. Thành phần `TypingIndicatorBubble` (Messenger-style Typing Indicator)

### 1.1 Vị trí sử dụng
- `SmartPlannerScreen`: hiển thị khi `_isSending == true` trong cuộc trò chuyện hỏi đáp.
- `ChatScreen`: hiển thị trong danh sách tin nhắn khi bot AI đang tạo phản hồi.

### 1.2 Thiết kế UI & Hoạt họa
- Avatar AI bên trái: Vòng tròn gradient thương hiệu AIVIVU chứa icon `Icons.auto_awesome` màu trắng (kích thước 16).
- Bong bóng chat: Màu nền `AppTheme.surfaceDark`, bo góc 16px (góc dưới trái bo 4px giống kiểu `PlannerBubble`).
- 3 chấm tròn (chấm nảy bouncing dots):
  - Kích thước: 7x7 px, bo tròn (`BoxShape.circle`), màu tím/hồng thương hiệu nhạt (`Colors.white70` hoặc `AppTheme.primaryPink`).
  - Animation: Dùng `AnimationController` lặp lại (`repeat`) trong chu kỳ 1200ms, điều khiển dịch chuyển theo trục Y (-4px đến 0px) với độ trễ so le (0ms, 200ms, 400ms) để tạo nhịp gõ chữ chân thực giống Facebook Messenger / iMessage.

---

## 2. Thành phần `PlannerGeneratingCard` (Hiệu ứng khi AI tạo gợi ý chuyến đi)

### 2.1 Bối cảnh kích hoạt
- Trong `SmartPlannerScreen`, khi người dùng gửi prompt yêu cầu tạo phương án (hoặc nhấn "Gợi ý luôn" / `forceOptions: true`).

### 2.2 Thiết kế UI & Thông điệp
- Khung hiển thị: Thiết kế dạng card mềm mại (`GlassCard` hoặc container viền gradient cyan/tím mờ), hòa hợp với nền vũ trụ cosmic dark của AIVIVU.
- Thông điệp luân phiên (Step Messages) tự động thay đổi sau mỗi 2.2 giây:
  1. *"Đang phân tích sở thích và mong muốn của bạn..."*
  2. *"Khám phá và chọn lọc các điểm đến phù hợp nhất..."*
  3. *"Tính toán lộ trình tối ưu và dự toán ngân sách..."*
  4. *"Đang hoàn tất các phương án du lịch tuyệt vời..."*
- Hoạt họa:
  - Thanh trạng thái hoặc vệt sáng cosmic shimmer chuyển động liên tục từ trái sang phải.
  - Hiệu ứng `AnimatedSwitcher` làm mờ và trượt nhẹ khi đổi thông điệp, giúp người dùng cảm giác hệ thống đang liên tục làm việc theo từng bước.

---

## 3. Nâng cấp `DestinationImage` (Hiệu ứng Shimmer & Smooth Fade-in)

### 3.1 Vấn đề cần khắc phục
- Hiện tại, khi `imageUrl` rỗng (AI chưa tìm xong ảnh) hoặc khi `CachedNetworkImage` bắt đầu tải, chỉ có một khung đen mờ đơn điệu hoặc trắng, sau đó ảnh hiện lên bất thình lình.

### 3.2 Giải pháp kỹ thuật
- **Shimmer Placeholder Widget (`ShimmerLoadingBox`)**:
  - Không cần cài thêm thư viện ngoài (giữ code tối giản theo đúng tinh thần dự án). Tự viết widget shimmer nhẹ nhàng bằng một `AnimationController` điều khiển `LinearGradient` dịch chuyển góc từ `Alignment(-2, -1)` sang `Alignment(2, 1)`.
  - Màu nền: Kết hợp giữa `AppTheme.surfaceDark` và highlight xám/tím sáng mờ (`Colors.white.withValues(alpha: 0.08)`).
  - Ở giữa có biểu tượng phong cảnh / ảnh mờ (`Icons.image_outlined`) với hiệu ứng opacity thở nhẹ nhàng.
- **Tích hợp vào `DestinationImage`**:
  - Khi `imageUrl.isEmpty`: Hiển thị `ShimmerLoadingBox` (đặc biệt khi đang trong quá trình `_loadImages` làm giàu ảnh điểm đến).
  - Khi `CachedNetworkImage` tải ảnh:
    - Sử dụng `placeholder: (_, _) => ShimmerLoadingBox(...)` thay vì khung gradient tĩnh.
    - Cấu hình `fadeInDuration: const Duration(milliseconds: 400)`.
    - Cấu hình `fadeInCurve: Curves.easeIn`.
  - Khi xảy ra lỗi tải ảnh hoặc không có ảnh: Hiển thị fallback gradient với icon núi và tên điểm đến mờ như thiết kế cũ.

---

## 4. Kế hoạch kiểm thử & nghiệm thu (Testing & Verification)
1. **Unit & Widget Tests**:
   - Test widget `TypingIndicatorBubble` hiển thị đầy đủ avatar và 3 chấm hoạt họa.
   - Test widget `DestinationImage` hiển thị shimmer khi đang tải hoặc khi `imageUrl` chưa sẵn sàng.
   - Test widget `PlannerGeneratingCard` hiển thị đúng thông điệp và không crash khi dispose timer/animation.
2. **Kiểm tra hồi quy**:
   - Chạy `flutter analyze` đảm bảo không có cảnh báo/lỗi mới.
   - Chạy `flutter test` toàn bộ suite kiểm tra tính tương thích.

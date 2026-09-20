# Thiết Kế Tính Năng: Thảo Luận Chuyến Đi Cùng AI (AI Trip Consultation)

## 1. Mục tiêu (Objective)
Cung cấp màn hình thảo luận tương tác giữa người dùng và AI ngay sau khi nhập prompt và bấm nút "Gợi ý lịch trình" (Suggest) từ `SmartPlannerScreen`. 
Tại màn hình này, người dùng có thể:
- Thảo luận, nhận tư vấn và phản biện từ AI về các địa điểm, sở thích và mong muốn của chuyến đi.
- Chỉnh sửa trực tiếp các thông tin chuyến đi (ngân sách, thời gian/số ngày, sở thích du lịch) thông qua bảng thông tin có thể gập/mở.
- Nhấn nút xác nhận hoặc chốt với AI để chuyển tiếp sang màn hình gợi ý địa điểm (`SuggestionsScreen`), và từ đó xem chi tiết kế hoạch lịch trình (`DestinationPlanScreen`).

> [!IMPORTANT]
> **Ràng buộc Git**: Tuyệt đối không tự ý đẩy code lên branch `master`. Mọi thay đổi chỉ thực hiện trên branch hiện tại (`feature/ui-redesign`).

---

## 2. Kiến trúc & Luồng dữ liệu (Data & Screen Flow)

```
[SmartPlannerScreen]
  │  Người dùng nhập prompt, chọn sơ bộ ngân sách/sở thích, bấm "Gợi ý lịch trình"
  │  Hệ thống lưu thông tin vào SavedTripsProvider
  ▼
[TripConsultationScreen] (Mới)
  │  • Header: Tiêu đề + Nút "Xác nhận & Xem gợi ý" (Confirm OK)
  │  • Collapsible Trip Info Panel: Xem & chỉnh sửa trực tiếp ngân sách, số ngày, sở thích
  │  • Chat Area: AI tự động phân tích prompt ban đầu, đặt câu hỏi gợi mở, lắng nghe điều chỉnh
  │  • Quick prompt chips: Các câu gợi ý phản hồi nhanh
  │  • Input bar: Nhập tin nhắn thảo luận với AI
  │  Người dùng bấm "Xác nhận & Xem gợi ý"
  ▼
[SuggestionsScreen]
  │  Hiển thị danh sách địa điểm gợi ý tối ưu theo kết quả thảo luận & cập nhật mới nhất
  │  Người dùng chọn 1 địa điểm
  ▼
[DestinationPlanScreen]
  Hiển thị lịch trình chi tiết từng ngày (Day 1, Day 2...)
```

---

## 3. Các thành phần chi tiết (Component Details)

### 3.1. Màn hình `TripConsultationScreen` (`lib/screens/trip_consultation_screen.dart`)
- **Quản lý trạng thái**:
  - Đọc `TripData` từ `SavedTripsProvider.of(context).currentTrip`.
  - Quản lý danh sách tin nhắn `List<ChatMessage>` trong phiên thảo luận.
  - Quản lý trạng thái mở rộng/thu gọn của bảng thông tin chuyến đi (`bool _isInfoExpanded`).
  - Quản lý trạng thái loading/gửi tin nhắn (`bool _isAiResponding`).
- **Giao diện**:
  - **AppBar**: Nút Back quay lại Planner, tiêu đề "Thảo luận cùng AI", nút action "Xác nhận OK" nổi bật với icon sparkles.
  - **Thanh thông tin chuyến đi (Collapsible Trip Info)**:
    - *Thu gọn*: Hiển thị badge ngân sách, số ngày, sở thích vắn tắt, icon toggle mở rộng.
    - *Mở rộng*: Cho phép chọn lại ngân sách (Economy, Moderate, Premium, Luxury), chọn lại sở thích (chips), số ngày đi. Khi có thay đổi, lập tức cập nhật vào `SavedTripsProvider.updateTrip()` và thêm tin nhắn thông báo nhẹ trong luồng chat.
  - **Danh sách tin nhắn**: 
    - Hiển thị bubble tin nhắn người dùng và AI theo phong cách Dark Glassmorphism chuẩn Aivivu.
    - Tin nhắn đầu tiên: AI tự động phân tích prompt ban đầu từ `trip.aiPrompt` và đưa ra lời chào, tư vấn ban đầu.
  - **Quick Action Chips**: Các lựa chọn nhanh như *"Ưu tiên nghỉ dưỡng"*, *"Thêm trải nghiệm ẩm thực"*, *"Lịch trình thư thả"*, *"Tôi thấy ổn rồi, chốt nhé!"*.
  - **Message Input Box**: Nhập tin nhắn và nút gửi.

### 3.2. Cập nhật `SmartPlannerScreen` (`lib/screens/smart_planner_screen.dart`)
- Thay đổi hàm `_onGetSuggestions()`:
  - Lưu trạng thái form vào `SavedTripsProvider`.
  - Ghi nhận lịch sử tìm kiếm vào `SearchHistoryService`.
  - Điều hướng sang `TripConsultationScreen` thay vì vào thẳng `SuggestionsScreen`.

### 3.3. Dịch vụ AI `GeminiService` (`lib/services/gemini_service.dart`)
- Bổ sung phương thức `consultTrip({required String message, required List<ChatMessage> history, required TripData currentTrip, required String languageCode})`:
  - System prompt chuyên trách: đóng vai trò Chuyên gia tư vấn du lịch thông minh của Aivivu.
  - Phân tích thông tin chuyến đi hiện tại (ngân sách, số ngày, sở thích, prompt gốc).
  - Trả lời thân thiện, súc tích, tư vấn các điểm đến tiềm năng hoặc gợi ý điều chỉnh lịch trình phù hợp với ngân sách và sở thích.

### 3.4. Đa ngôn ngữ (Localization - l10n)
- Bổ sung các chuỗi ngôn ngữ vào `app_vi.arb`, `app_en.arb`, `app_ko.arb`:
  - Tiêu đề màn hình thảo luận, nhãn "Xác nhận OK", "Thông tin chuyến đi", gợi ý nhanh, v.v.

---

## 4. Kế hoạch kiểm thử & Xác thực (Verification Plan)
1. **Kiểm thử luồng điều hướng**:
   - Từ `SmartPlannerScreen`, nhập prompt "Hà Giang mùa hoa tam giác mạch" -> bấm nút Suggest -> Chuyển sang `TripConsultationScreen`.
2. **Kiểm thử khởi tạo AI**:
   - AI tự động phân tích prompt và gửi tin nhắn chào/hỏi làm rõ ban đầu.
3. **Kiểm thử chỉnh sửa thông tin**:
   - Mở rộng bảng thông tin chuyến đi, đổi từ Moderate sang Premium hoặc chọn thêm sở thích -> Kiểm tra thông tin đã cập nhật vào `SavedTripsProvider`.
4. **Kiểm thử chat tương tác**:
   - Nhắn tin bổ sung yêu cầu (VD: "Mình muốn đi 4 ngày 3 đêm") -> AI phản hồi phù hợp với ngữ cảnh.
5. **Kiểm thử xác nhận & chuyển tiếp**:
   - Nhấn "Xác nhận & Xem gợi ý" -> Chuyển sang `SuggestionsScreen`.
   - Bấm chọn 1 địa điểm -> Xem lịch trình chi tiết từng ngày tại `DestinationPlanScreen`.
6. **Kiểm tra biên dịch & phân tích mã nguồn**:
   - Chạy `flutter analyze` hoặc chạy ứng dụng xác nhận không phát sinh lỗi cú pháp hay cảnh báo nghiêm trọng.

# Spec: Smart Planner AI-First — Đơn Giản Hoá Giao Diện và Hàng Chip Tương Tác

> Ngày: 20/09/2026.
> Nhánh: `planner-ai-first`.
> Vị trí trong roadmap: Mục 2.1 của `docs/project_phase3_roadmap_ai_first.md`.
> Kế thừa: `docs/superpowers/specs/2026-09-07-planner-ai-fill-design.md` (hàm `extractTripData` đã hoàn thiện và kiểm thử).

---

## 1. Mục tiêu

Đưa màn hình Planner về đúng tinh thần **AI-first**:
- Người dùng chỉ cần mô tả chuyến đi bằng ngôn ngữ tự nhiên. Không còn biểu mẫu 7 trường rườm rà.
- Trải nghiệm **1 chạm**: Bấm "Gợi ý chuyến đi", AI tự động bóc tách tham số và chuyển trực tiếp sang `SuggestionsScreen`.
- Thông tin có cấu trúc được thể hiện qua widget hàng chip (`TripChips`) ở đầu màn hình gợi ý. Người dùng có thể xem lại và chạm vào từng chip để chỉnh sửa nhanh (ví dụ nâng hạng ngân sách) ngay tại chỗ.

---

## 2. Luồng trải nghiệm người dùng (UX Flow)

1. **Tại `SmartPlannerScreen`**:
   - Người dùng thấy lời chào thân thiện, ô nhập Prompt AI nổi bật và các thẻ gợi ý mẫu (Inspiration Chips) như:
     - *"Đi Đà Lạt 3 ngày với gia đình, tiết kiệm"*
     - *"Nghỉ dưỡng biển Phú Quốc 4 ngày cao cấp"*
     - *"Khám phá ẩm thực Hà Nội cuối tuần"*
   - Người dùng có thể gõ câu lệnh tùy ý hoặc chạm vào một chip ý tưởng mẫu để tự động điền prompt.
   - Nút bấm chính duy nhất: **"Gợi ý chuyến đi"** (hoặc icon tia sét / la bàn AI).
2. **Khi bấm nút "Gợi ý chuyến đi"**:
   - Nếu prompt trống: Hiển thị SnackBar nhắc nhở.
   - Nút chuyển sang trạng thái loading.
   - Gọi `GeminiService.instance.extractTripData(prompt)`.
   - Cập nhật `TripData` vào `SavedTripsProvider` (kết hợp các thông tin trích xuất được với thông tin mặc định từ User Profile như `preferredCurrency` và các phong cách du lịch yêu thích).
   - Ghi lại tìm kiếm vào `SearchHistoryService`.
   - Điều hướng (`Navigator.push`) sang `SuggestionsScreen`.
3. **Tại `SuggestionsScreen`**:
   - Đầu màn hình (ngay dưới Header / AppBar) hiển thị widget `TripChips`.
   - Người dùng thấy ngay các thông tin AI đã hiểu: 📍 *Điểm đến* | 📅 *Thời gian* | 💰 *Ngân sách* | 👥 *Số người* | 🏷️ *Sở thích*.
   - Chạm vào chip bất kỳ: Mở Bottom Sheet nhỏ gọn để sửa đúng trường đó (ví dụ chuyển ngân sách từ Economy sang Premium, hoặc đổi số ngày đi).
   - Khi xác nhận sửa: `SavedTripsProvider` được cập nhật, `SuggestionsScreen` tự động gọi làm mới danh sách gợi ý (`forceRefresh: true`).

---

## 3. Thiết kế chi tiết các thành phần

### 3.1. Màn hình `lib/screens/smart_planner_screen.dart`

**Các thành phần bị loại bỏ:**
- 7 bộ điều khiển & trường form cũ: `_destinationController`, `_participantsController`, `_ageRangeController`, `_notesController`, Date picker depart/return, bộ chọn budget tier (`_buildBudgetTierSelector`), danh sách checkbox chọn sở thích (`_selectedInterests`), dropdown chọn tiền tệ trên form.
- Biến trạng thái & logic điền form phức tạp: `_tierTouched`, `_interestsTouched`, `_aiFilled`, `_canFill()`, `_applyExtracted()`.

**Các thành phần giữ lại & cải tiến:**
- `_promptController`: Nhận nội dung mô tả chuyến đi.
- Header: Lời chào và `AccountMenuButton`.
- `_AiPromptBox`: Hộp văn bản nhiều dòng với placeholder truyền cảm hứng.
- Danh sách `_InspirationChips`: Các mẫu prompt thông dụng để người dùng chạm và thử nhanh.
- Nút CTA: Gradient Button lớn "Gợi ý chuyến đi" kèm hiệu ứng đang tải khi gọi AI.
- Tự động nạp cấu hình người dùng (`ProfileService.loadCurrentProfile`) trong nền để gán `currency` mặc định mà không cần hiển thị form.

### 3.2. Widget mới `lib/widgets/shared/trip_chips.dart`

**Trách nhiệm:** Hiển thị và cho phép chỉnh sửa nhanh các trường dữ liệu của `TripData`.

```dart
class TripChips extends StatelessWidget {
  final TripData trip;
  final ValueChanged<TripData> onTripChanged;

  const TripChips({
    super.key,
    required this.trip,
    required this.onTripChanged,
  });
}
```

**Các chip hiển thị:**
1. **Điểm đến (Destination)**:
   - Nếu có: `📍 {trip.destination}`
   - Nếu chưa có / rỗng: `📍 Điểm đến: AI gợi ý` (hiển thị mờ dạng dashed/faded).
   - Tap: Mở Bottom Sheet nhập nhanh tên điểm đến mới.
2. **Thời gian (Dates / Duration)**:
   - Nếu có ngày đi & về: `📅 dd/MM - dd/MM`
   - Nếu chỉ có số ngày: `📅 {days} ngày`
   - Nếu không có: `📅 Thời gian linh hoạt`
   - Tap: Mở DateRangePicker để chọn ngày cụ thể.
3. **Ngân sách (Budget Tier)**:
   - Nhãn tương ứng với tier: `💰 Tiết kiệm / Vừa phải / Cao cấp / Sang trọng`
   - Tap: Mở Bottom Sheet chọn 1 trong 4 chip tier.
4. **Số người (Participants)**:
   - `👥 {trip.participants} người` (mặc định "1 người" nếu không có).
   - Tap: Mở bộ chọn tăng giảm số lượng (+ / -).

### 3.3. Tích hợp trên `lib/screens/suggestions_screen.dart`

- Bổ sung `TripChips` ngay trên danh sách các thẻ địa điểm đề xuất (`_suggestions`).
- Khi callback `onTripChanged` được kích hoạt:
  ```dart
  SavedTripsProvider.of(context).updateTrip(updatedTrip);
  _loadSuggestions(forceRefresh: true);
  ```

---

## 4. Xử lý ngoại lệ & Tính bền vững (Resilience)

- **Lỗi mạng hoặc Gemini Service gặp sự cố khi trích xuất:**
  - Không chặn đứng người dùng: Tạo `TripData` cơ bản với `aiPrompt = prompt` gốc và các trường mặc định.
  - Vẫn chuyển sang `SuggestionsScreen` (tại đây có cơ chế retry / reload thân thiện với người dùng).
- **Mô tả ngắn hoặc mơ hồ (Ví dụ: *"thích đi ngắm cảnh", "tour hè giá rẻ"*):**
  - AI trích xuất trả về `destination: null`.
  - Chip điểm đến hiển thị trạng thái mờ (`"Điểm đến: AI gợi ý"`).
  - Suggestions screen tiếp tục đề xuất các địa điểm phù hợp với mô tả chung.
- **Trở về màn hình Planner:**
  - Nội dung prompt đã nhập được giữ nguyên trong controller để người dùng dễ dàng xem lại hoặc chỉnh sửa prompt tiếp.

---

## 5. Kế hoạch kiểm thử

1. **Unit Test**:
   - Xác nhận `GeminiService.extractTripData` và `parseExtractedTripData` xử lý chuẩn xác cả trường hợp prompt đầy đủ thông tin lẫn prompt thiếu trường.
2. **Widget Test**:
   - `test/screens/smart_planner_screen_test.dart`:
     - Xác nhận không còn các widget form nhập liệu cũ.
     - Ô prompt và các inspiration chips hoạt động chính xác khi chạm vào.
     - Nhấn nút "Gợi ý chuyến đi" gọi hàm trích xuất và điều hướng.
   - `test/widgets/trip_chips_test.dart`:
     - Render đúng nhãn và giá trị của `TripData`.
     - Chạm vào chip ngân sách kích hoạt bottom sheet và gọi `onTripChanged`.
3. **Phân tích tĩnh & Kiểm tra tổng thể**:
   - `flutter analyze` không sinh lỗi hoặc cảnh báo mới.
   - `flutter test` vượt qua 100%.

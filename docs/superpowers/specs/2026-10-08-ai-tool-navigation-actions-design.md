# Spec Thiết Kế: AI Tool Điều Hướng & Thực Thi Lệnh Trên App (AI Action Navigation)

> Ngày: 08/10/2026  
> Nhánh làm việc: `fix-save-status-and-ai-navigation`  
> Tệp spec: `docs/superpowers/specs/2026-10-08-ai-tool-navigation-actions-design.md`

## 1. Mục Tiêu

Cho phép người dùng tương tác với **AI Tool Chat** để điều khiển và điều hướng trực tiếp trên ứng dụng VOYZ thông qua các câu lệnh tự nhiên (natural language commands).

Ví dụ:
- *"Chuyển tôi tới trang Phú Quốc"* -> AI trả lời tư vấn ngắn + tự động chuyển sang `DestinationDetailScreen` của Phú Quốc.
- *"Cho tôi xem danh sách chuyến đi đã lưu"* -> AI phản hồi + chuyển tới `SavedScreen`.
- *"Lên kế hoạch đi Đà Nẵng 4 ngày"* -> AI hỏi thêm thông tin hoặc cập nhật `TripData` và chuyển đến trang chi tiết/lịch trình.

---

## 2. Kiến Trúc & Luồng Dữ Liệu

```text
[User Prompt] -> ChatScreen 
  -> GeminiService.chatWithActions() 
  -> Gemini (với system instructions & JSON action schema)
  -> Parsed ChatResponse (text + AiAction?)
  -> Render Chat Bubble + Action Card/Button
  -> Auto-navigate hoặc user tap -> Trigger App Navigation
```

---

## 3. Mô Hình Dữ Liệu (Data Models)

### `lib/models/ai_action.dart` (Mới)

```dart
enum AiActionType {
  navigateDestination, // Chuyển đến DestinationDetailScreen
  navigateScreen,      // Chuyển đến màn hình chính (planner, explore, saved, friends, profile)
  setTripData,         // Cập nhật thông tin chuyến đi vào SavedTripsProvider
}

class AiAction {
  final AiActionType type;
  final String target; // Tên điểm đến (ví dụ 'Phú Quốc') hoặc tên màn hình ('saved', 'explore', ...)
  final String label;  // Nhãn hiển thị trên nút/thẻ (ví dụ 'Mở trang Phú Quốc')
  final Map<String, dynamic>? parameters; // Các tham số phụ (numDays, budget,...)

  const AiAction({
    required this.type,
    required this.target,
    required this.label,
    this.parameters,
  });

  factory AiAction.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### Cập nhật `ChatMessage` (`lib/models/chat_message.dart`)
Thêm thuộc tính `final AiAction? action` vào model `ChatMessage` để lưu trữ hành động kèm theo tin nhắn AI.

---

## 4. Tích Hợp Gemini Service (`lib/services/gemini_service.dart`)

Thêm hàm `chatWithActions`:
- Prompt chỉ thị cho Gemini nhận diện ý định chuyển trang/điều hướng của người dùng.
- Định dạng JSON trả về dạng:
```json
{
  "reply": "Mình sẽ đưa bạn đến trang thông tin Côn Đảo ngay nhé!",
  "action": {
    "type": "navigateDestination",
    "target": "Côn Đảo",
    "label": "Mở trang Côn Đảo"
  }
}
```

---

## 5. Trải Nghiệm Nối Giao Diện (UI/UX)

1. Trong `ChatScreen`:
   - Khi nhận tin nhắn AI chứa `action`:
   - Bong bóng chat của AI sẽ hiển thị đoạn hội thoại và 1 **Action Card / Button** nổi bật (ví dụ: nút bấm gradient `🚀 Mở trang Phú Quốc`).
   - Tự động kích hoạt chuyển màn hình sau 1-1.5s ngắn (hoặc khi người dùng nhấn trực tiếp vào thẻ).
2. Xử lý điều hướng:
   - `navigateDestination`: Mở `DestinationDetailScreen(destinationName: action.target)`.
   - `navigateScreen`: Mở màn tương ứng (`SavedScreen`, `ExploreScreen`, `FriendsScreen`, `SmartPlannerScreen`).

---

## 6. Tiêu Chí Nghiệm Thu & Test

- [ ] Gõ `"Mở trang Đà Lạt"` -> AI trả lời và tự động/cho phép nhấn mở `DestinationDetailScreen` Đà Lạt.
- [ ] Gõ `"Xem danh sách đã lưu"` -> AI trả lời và chuyển sang `SavedScreen`.
- [ ] Gõ `"Gợi ý chuyến đi Nha Trang 3 ngày"` -> AI phản hồi thông tin và kèm nút mở chi tiết Nha Trang.
- [ ] Unit test cho parser `AiAction.fromJson` và `GeminiService.chatWithActions`.
- [ ] `flutter analyze` 0 lỗi, `flutter test` pass 100%.

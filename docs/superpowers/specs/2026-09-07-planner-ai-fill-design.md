# Spec: AI điền form planner để người dùng review (bước 1.5 của prompt-first)

> Ngày: 07/09/2026. Trạng thái: đã duyệt thiết kế với giáo viên.
> Baseline: `master` sau khi merge `simple-cache` và `trip-identity` (`6a5645c`).
> Vị trí trong roadmap: nằm giữa bước 1 đã làm (prompt là trường bắt buộc duy nhất) và mục 2.1 (bỏ form, hàng chip). Tạm thời: form vẫn còn và đóng vai trò vừa hiển thị vừa sửa những gì AI bóc tách được. Khi làm 2.1 chỉ thay phần hiển thị, hàm trích xuất giữ nguyên.

## 1. Mục tiêu

Người dùng nhìn thấy AI đã hiểu gì từ mô tả chuyến đi, sửa nếu sai, rồi mới nhận gợi ý. Dữ liệu ghi vào `search_history` và mang sang các màn hình sau vẫn là `TripData` lấy từ form như hiện tại, nên không đổi DB, không đổi provider, không đổi màn hình khác.

## 2. Luồng

1. Người dùng gõ mô tả, bấm nút. Lần đầu nút ghi **"Phân tích bằng AI"**: gọi `extractTripData`, đổ kết quả vào form theo quy tắc mục 4, snackbar "AI đã điền N thông tin. Kiểm tra rồi bấm Nhận gợi ý AI."
2. Nút đổi thành **"Nhận gợi ý AI"**. Người dùng xem form, sửa nếu cần.
3. Bấm lần hai: `_onGetSuggestions` như hiện tại (ghi `search_history`, sang Suggestions).
4. Sửa nội dung ô mô tả sau khi đã phân tích thì nút quay về "Phân tích bằng AI".

## 3. Trích xuất (`lib/services/gemini_service.dart`)

```dart
Future<TripData> extractTripData(String prompt, {String languageCode = 'vi'});

@visibleForTesting
TripData parseExtractedTripData(String text);   // thuần parse, test được
```

- Dùng `_gemini` (JSON mode) như các feature khác. Không cache.
- Prompt tiếng Việt, kèm ngày hôm nay (`yyyy-MM-dd`) để hiểu "cuối tuần này", "tháng sau". Yêu cầu JSON đúng các key:

```json
{
  "destination": "string hoặc null",
  "departDate": "yyyy-MM-dd hoặc null",
  "returnDate": "yyyy-MM-dd hoặc null",
  "numDays": "số nguyên hoặc null",
  "budgetTier": "economy | moderate | premium | luxury hoặc null",
  "participants": "số nguyên hoặc null",
  "ageRange": "string hoặc null",
  "interests": ["chỉ dùng: beach, adventure, culture, food, wellness"]
}
```

- `parseExtractedTripData` quy tắc:
  - Key thiếu hoặc null thì trường tương ứng rỗng (`''`, `null`, `[]`).
  - `budgetTier` ngoài 4 giá trị thì bỏ (rỗng).
  - `interests` chỉ giữ phần tử nằm trong `MockData.interests`, bỏ phần còn lại, không tạo mới.
  - `departDate` có, `returnDate` không có, `numDays` có thì `returnDate = departDate + (numDays - 1)` ngày. Chỉ có `numDays` mà không có `departDate` thì bỏ qua (ngày để null).
  - `participants` là số thì đổi sang chuỗi (`"4"`), không phải số thì rỗng.
  - `aiPrompt` gán bằng prompt gốc; `currency`, `additionalNotes` để mặc định.
- Lỗi mạng hoặc JSON hỏng: ném exception như các hàm khác; màn hình hiện snackbar, form không đổi.

## 4. Đổ vào form (`lib/screens/smart_planner_screen.dart`)

Quy tắc: **AI chỉ điền chỗ người dùng chưa đụng.**

| Trường | Điều kiện AI được điền |
|---|---|
| Điểm đến, số người, độ tuổi | ô đang rỗng |
| Ngày đi, ngày về | cả hai đang null |
| Ngân sách (tier) | người dùng chưa tap chọn tier trong phiên (`_tierTouched == false`) và AI trả tier khác rỗng |
| Sở thích | người dùng chưa tap chip nào trong phiên (`_interestsTouched == false`) và AI trả ít nhất 1 sở thích; khi điền thì chọn đúng danh sách AI trả, bỏ chọn phần còn lại |
| Ghi chú | không đụng |

Tier và sở thích có giá trị mặc định (moderate; prefill từ profile) nên dùng cờ "đã chạm trong phiên" thay cho "ô rỗng". Prefill từ profile không tính là chạm.

State thêm: `bool _analyzed`, `bool _isAnalyzing`, `bool _tierTouched`, `bool _interestsTouched`. Listener trên `_promptController`: text đổi thì `_analyzed = false`. Số trường được điền đếm để hiện trong snackbar; bằng 0 thì hiện "AI chưa suy ra được thông tin nào từ mô tả." và vẫn chuyển sang trạng thái đã phân tích (người dùng tự điền rồi bấm tiếp).

Trong lúc chờ AI: nút vô hiệu, nhãn "Đang phân tích...". Không thêm widget mới ngoài đổi nhãn và trạng thái nút.

## 5. Chuỗi mới (`lib/l10n/app_en.arb`, `app_vi.arb`, `app_ko.arb`, chạy `flutter gen-l10n`)

| Key | en | vi | ko |
|---|---|---|---|
| `analyzeTrip` | Analyze with AI | Phân tích bằng AI | AI로 분석 |
| `analyzingTrip` | Analyzing... | Đang phân tích... | 분석 중... |
| `aiFilledFields` (placeholder `count`) | AI filled {count} fields. Review, then tap Get AI Suggestions. | AI đã điền {count} thông tin. Kiểm tra rồi bấm Nhận gợi ý AI. | AI가 {count}개 항목을 채웠습니다. 확인 후 AI 추천 받기를 누르세요. |
| `aiFilledNothing` | AI could not extract details from your description. Fill the form, then continue. | AI chưa suy ra được thông tin nào từ mô tả. Hãy điền form rồi tiếp tục. | AI가 설명에서 정보를 추출하지 못했습니다. 양식을 채운 뒤 계속하세요. |

## 6. Test

`test/services/gemini_service_test.dart`, group `parseExtractedTripData`:
- JSON đầy đủ: mọi trường vào đúng chỗ, `participants` số thành chuỗi.
- JSON chỉ có `destination`: các trường khác rỗng, `interests` là `[]`.
- `budgetTier: "cheap"` và `interests: ["beach", "shopping"]`: tier rỗng, interests còn `["beach"]`.
- `departDate` + `numDays: 3`, không `returnDate`: `returnDate` = depart + 2 ngày.
- Chỉ `numDays`, không `departDate`: cả hai ngày null.

Không có widget test cho planner (đúng bar của project). Nghiệm thu tay ở mục 7.

## 7. Nghiệm thu

- [ ] Gõ "Đi Đà Lạt 3 ngày với gia đình 4 người, tiết kiệm, thích ẩm thực", bấm Phân tích: form hiện Đà Lạt, 4 người, tier economy, chip Ẩm thực được chọn; ngày để trống (không có ngày cụ thể); snackbar báo số trường đã điền.
- [ ] Tự gõ điểm đến "Huế" trước rồi mới Phân tích với prompt nói "Đà Lạt": ô điểm đến vẫn là Huế.
- [ ] Tap chọn tier luxury rồi Phân tích với prompt "tiết kiệm": tier vẫn luxury.
- [ ] Sửa ô mô tả sau khi phân tích: nút quay lại "Phân tích bằng AI".
- [ ] Bấm Nhận gợi ý AI: sang Suggestions, `search_history` có dòng với destination Đà Lạt.
- [ ] Tắt mạng rồi Phân tích: snackbar lỗi, form không đổi, nút vẫn là Phân tích.
- [ ] `flutter analyze` không lỗi mới, `flutter test` pass với 5 test mới.

## 8. Không làm

Không cache kết quả trích xuất. Không hiển thị JSON thô. Không streaming. Không sửa `TripData`, DB, provider, hay màn hình khác. Không tự động phân tích khi đang gõ.

# Spec: Polish ảnh điểm đến (roadmap 2.4)

> Ngày: 19/09/2026. Trạng thái: đã duyệt thiết kế với giáo viên.
> Baseline: `master` tại `a2e90cd` (sau planner AI fill). Nhánh: `image-polish`.
> Đọc kèm: roadmap mục 2.4, bài học `docs/lessons/2026-08-31-image-stability-walkthrough.md`, nghiên cứu `docs/research/2026-09-19-gemini-image-sources.md` (kết luận giữ Wikipedia làm nguồn ảnh).

## 1. Mục tiêu

Không đổi nguồn ảnh. Chỉ làm hai việc: mọi ảnh lỗi trong app trông giống nhau, và giảm request thừa tới Wikimedia. Sau nhánh này, người dùng mở Explore hay Detail thấy một kiểu placeholder duy nhất, gallery landmark không còn ô trống, console không còn chuỗi 404 `vi.wikipedia.org` với tên tiếng Anh.

## 2. Hiện trạng (vì sao ảnh trông "không ổn định")

- Sáu chỗ render ảnh điểm đến tự viết `CachedNetworkImage`, mỗi chỗ một màu nền, một icon, có chỗ có spinner có chỗ không. Ảnh lỗi ở Explore khác ảnh lỗi ở Suggestions.
- `ImageService.getImageUrl` luôn hỏi `vi.wikipedia` trước. Tên do AI sinh phần lớn không dấu hoặc tiếng Anh, nên request đầu gần như luôn 404 rồi mới sang `en`.
- Kết quả rỗng được cache suốt phiên trong memory. Một lần lỗi mạng làm điểm đến đó mất ảnh tới khi restart.
- `getImageUrls` và `getLandmarkPhotos` bắn toàn bộ request cùng lúc (10 gợi ý = tới 30 request song song), dễ dính 429.
- Landmark do AI đặt tên ("Cầu Vàng, Đà Nẵng") thường không có trang Wikipedia, rơi xuống Commons search hoặc rỗng, tạo ô trống trong gallery.
- `explore_screen._loadExplore` chỉ fallback sang Gemini khi repository trả rỗng, không fallback khi repository ném exception.

## 3. Widget chung `lib/widgets/shared/destination_image.dart` (mới)

```dart
class DestinationImage extends StatelessWidget {
  const DestinationImage({
    required this.imageUrl,
    required this.destinationName,
    this.fit = BoxFit.cover,
  });
}
```

Ba trạng thái, một kiểu nhìn:

| Trạng thái | Hiển thị |
|---|---|
| `imageUrl` rỗng | Vẽ fallback ngay, không tạo request mạng |
| Đang tải | Nền gradient từ `AppTheme.surfaceDark` sang `AppTheme.backgroundDark`, không spinner |
| Lỗi tải | Cùng gradient, thêm `Icons.landscape` mờ và `destinationName` chữ nhỏ mờ ở giữa |

Widget chỉ lo phần ảnh. Overlay gradient, badge, tiêu đề vẫn nằm trong `Stack` của màn hình gọi như hiện tại.

Thay ở đúng sáu chỗ:

| File | Chỗ |
|---|---|
| `lib/screens/suggestions_screen.dart` | card gợi ý |
| `lib/screens/saved_screen.dart` | card trip đã lưu |
| `lib/screens/explore_screen.dart` | card explore |
| `lib/screens/cultural_tips_screen.dart` | header, xoá hàm riêng `_gradientFallback` |
| `lib/screens/destination_detail_screen.dart` | ảnh hero |
| `lib/screens/destination_detail_screen.dart` | ô gallery landmark |

Không đụng: ba avatar (`friends_screen.dart`, `account_menu_button.dart`, `profile_screen.dart`). Avatar là ảnh người, không phải điểm đến, nằm ngoài 2.4.

## 4. `lib/services/image_service.dart`

### 4.1. Thứ tự ngôn ngữ theo tên

Thêm helper `bool hasVietnameseDiacritics(String s)` (public, `@visibleForTesting`), một regex nhận dấu tiếng Việt (các ký tự trong khoảng Latin mở rộng dùng cho tiếng Việt và chữ đ/Đ).

- Có dấu: `vi` rồi `en` (như hiện tại).
- Không dấu: `en` rồi `vi`.

Commons search vẫn là bước cuối, không đổi.

### 4.2. Cache kết quả rỗng có hạn

Map `_cache` đổi giá trị từ `String` sang một record nhỏ `(String url, DateTime fetchedAt)`.

- URL tìm được: giữ suốt phiên như hiện tại.
- URL rỗng: coi là hit trong 10 phút (`negativeTtl = Duration(minutes: 10)`), quá hạn thì tra lại.

Cho phép test inject thời gian bằng `static DateTime Function() now = DateTime.now;` cùng kiểu với `static http.Client client` đã có.

### 4.3. Chạy theo lô 3

`getImageUrls(names)` và `getLandmarkPhotos(...)` không `Future.wait` toàn bộ. Chia danh sách thành lô 3 phần tử, `Future.wait` từng lô theo thứ tự. Một helper private `_inBatches<T>(List<String> names, Future<T> Function(String) run)` dùng chung cho cả hai. Không thêm package.

## 5. Landmark rỗng lấy ảnh chính (`lib/services/gemini_service.dart`, `_parseDetail`)

Sau khi có `imageUrl` chính và `gallery`, landmark nào `imageUrl` rỗng thì gán bằng `imageUrl` chính. Không thêm cờ, không thêm field vào `DestinationLandmarkPhoto`: ô gallery đã phủ gradient tối phía dưới nên ảnh trùng vẫn đọc được là "cùng điểm đến". Ảnh chính cũng rỗng thì ô hiện fallback của widget chung.

## 6. Explore fallback khi repository lỗi (`lib/screens/explore_screen.dart`)

Bọc riêng lời gọi `DestinationRepository.getFeaturedDestinations` trong `try/catch`, lỗi thì coi như danh sách rỗng. Điều kiện fallback sang `GeminiService.getExploreTrending` giữ nguyên là "danh sách rỗng". `catch` ngoài vẫn giữ để báo lỗi khi Gemini cũng hỏng.

## 7. Không làm trong nhánh này

- Không đổi nguồn ảnh, không CDN, không upload, không thêm nguồn mới (kết luận nghiên cứu 19/09).
- Không sửa `tool/verify_image_urls.dart` (lỗ hổng host `thumb.wikimedia.org` đã ghi ở roadmap mục 8, để đợt cập nhật seed sau).
- Không migration seed ảnh: cả bốn điểm đến seed đã có URL trực tiếp đã verify.
- Không đụng avatar.
- Không LRU, không giới hạn dung lượng cache ảnh, không retry.

## 8. Test (`test/services/image_service_test.dart`, MockClient)

- Tên tiếng Anh: request đầu là `en.wikipedia`; `en` có ảnh thì không gọi `vi`.
- Tên có dấu: request đầu là `vi.wikipedia`.
- `hasVietnameseDiacritics`: "Đà Lạt" true, "Da Lat" false, "Kyoto" false.
- Kết quả rỗng: gọi lại trong 10 phút không tạo request mới; đẩy `now` qua 10 phút thì tra lại.
- Lô 3: với 7 tên, số request đang chờ đồng thời không vượt 3 (đếm trong MockClient bằng counter tăng khi vào, giảm khi trả).

Không có widget test (đúng bar của project).

## 9. Nghiệm thu tay

- [ ] Explore, Suggestions, Saved, Cultural tips, Detail hero, Detail gallery: tắt mạng, mọi ô ảnh hiện cùng một fallback.
- [ ] Mở Explore với điểm đến tên tiếng Anh: console không còn 404 `vi.wikipedia.org`.
- [ ] Mở Detail một điểm đến có landmark lạ: gallery không còn ô trống.
- [ ] Tắt Supabase (sai URL) rồi mở Explore: vẫn ra danh sách từ Gemini.
- [ ] `dart run tool/verify_image_urls.dart` pass, `flutter analyze` không lỗi mới, `flutter test` pass với test mới.

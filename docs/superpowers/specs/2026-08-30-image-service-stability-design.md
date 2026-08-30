# Design: Ổn định hóa hệ thống ảnh điểm đến (Image Service Stability)

> Ngày: 30/08/2026
> Trạng thái: Đã duyệt (giáo viên chốt hướng trong buổi review 30/08)
> Plan thực thi: `docs/superpowers/plans/2026-08-30-image-service-stability.md`

## 1. Vấn đề

Sau bản overhaul ImageService ngày 23/08 (commit d2957b3), toàn bộ ảnh điểm đến chết trên web build. Console cho thấy 3 loại lỗi độc lập:

1. **404 từ upload.wikimedia.org**: phần lớn URL trong map `_curatedLandmarks` là tên file không tồn tại trên Wikimedia Commons (ví dụ `Halong_bay_boats.jpg`, `Cat_Ba_Island_Vietnam.jpg`). Commit message ghi "hand-verified" nhưng thực tế chưa từng được kiểm chứng bằng máy.
2. **400 từ upload.wikimedia.org**: một số file có thật (ví dụ `Phu_Quoc_Beach.jpg`) nhưng URL thumb tự đoán sai hash path (`/7/76/` trong khi đường dẫn thật là `/b/bf/`) hoặc đòi kích thước lớn hơn ảnh gốc, Wikimedia từ chối.
3. **CORS + 503 từ source.unsplash.com**: dịch vụ `source.unsplash.com/featured` đã bị Unsplash khai tử và chưa bao giờ gửi CORS header, trong khi Flutter web (CanvasKit) tải ảnh bằng fetch nên bị chặn tuyệt đối.

Khuếch đại lỗi: cơ chế pre-cache lưu các URL hỏng này vào cache AI đa tầng (Hive + Supabase), nên URL chết được phục vụ lại cho các phiên sau.

Bài học kiểm chứng quan trọng rút ra khi điều tra: HEAD trả 302 trên `Special:FilePath` KHÔNG chứng minh file tồn tại (redirect đích vẫn có thể 404). Kiểm chứng đúng là follow redirect đến cùng và yêu cầu status 200 kèm content-type `image/*`.

**Cập nhật 20:13 ngày 30/08 (commit `857729a`):** học sinh đã tự vá một phần: thay vài URL curated bằng URL mới (3 URL được spot-check đều sống), nhưng vẫn giữ nguyên kiến trúc map-trong-code, và thay Unsplash bằng LoremFlickr, dịch vụ này đã xác minh trả 403 kèm không có CORS header, tức chết ngay từ ngày đầu, lặp lại đúng lỗi Unsplash. Bản vá này xử lý triệu chứng, không xử lý nguyên nhân (không có bước verify tự động, vẫn còn fallback URL cứng). Thiết kế trong tài liệu này không đổi; plan thực thi đã được cập nhật theo tên hàm mới sau commit đó.

## 2. Quyết định thiết kế

Kiến trúc ảnh 3 lớp, xóa mọi nguồn không kiểm chứng được:

| Lớp | Nguồn | Ghi chú |
|---|---|---|
| 1. Curated (đường chính cho điểm đến phổ biến) | Cột `image_url` và `gallery` trong bảng `destinations` | URL dạng `Special:FilePath?width=1280` (server tự tính hash path và thumb hợp lệ, không bao giờ 400). Chỉ URL đã qua script verify mới được vào seed |
| 2. Fallback động (điểm đến bất kỳ do AI gợi ý) | Wikipedia REST API `page/summary` (vi rồi en), sau đó Commons full-text search | REST summary: 1 request, CORS chính thức, server trả sẵn URL thumbnail hợp lệ. Nâng lên 1280px chỉ khi ảnh gốc đủ lớn |
| 3. Chốt chặn UI | `errorWidget` của `CachedNetworkImage` (đã có sẵn ở cả 7 call site) | Service trả chuỗi rỗng khi bó tay; UI hiển thị placeholder gradient, không bao giờ ô vỡ |

Xóa bỏ hoàn toàn:

- Map `_curatedLandmarks` viết tay trong code (data-in-code, nguồn của toàn bộ 404).
- Fallback `source.unsplash.com` (dịch vụ đã chết).
- `_getRealisticTravelFallback` (URL cứng, phần lớn cũng bịa).
- Chuỗi tra cứu Wikipedia nhiều bước `_fetchWikipediaLandscapeImage` + `_fetchFileInfo` (thay bằng REST summary 1 request).

Chống tái nhiễm:

- Script `tool/verify_image_urls.dart`: quét mọi URL ảnh Wikimedia trong `supabase/migrations/`, follow redirect, bắt buộc 200 + `image/*`. Chạy trước mọi lần merge có đổi seed ảnh. "Verified" là kết quả của script, không phải lời hứa trong commit message.
- `AiCacheService` chỉ chấp nhận image URL từ host allowlist (`upload.wikimedia.org`, `commons.wikimedia.org`, `*.supabase.co`); đổi tên box cache local sang `_v2` để bỏ sạch URL hỏng đã nhiễm.

## 3. Non-goals (không làm trong spec này)

- Không đụng `DestinationRepository`, `CommunityReviewService` hay logic màn hình (các file này thuộc phạm vi tuần 1 của người khác hoặc đang đóng băng theo `docs/week1_parallel_assignments.md`).
- Không dùng Unsplash API chính thức hay Pexels (đòi API key trong client web, quay lại bài toán lộ key).
- Không sửa policy của bảng `ai_generated_cache` (thuộc task cache hardening của bạn B tuần 1).
- Không sửa migration đã commit `20260829000100` (fix seed bằng migration UPDATE mới, giữ nguyên tắc không rewrite migration).

## 4. Dữ liệu đã verify sẵn cho seed (30/08/2026, script chạy tay bằng curl)

| Slug | File Commons (đã verify 200 + image/jpeg) |
|---|---|
| da-nang-vietnam | `Da_Nang_-_Dragon_Bridge.jpg`; gallery thêm `Aerial_view_of_the_Golden_Bridge,_Ba_Na_Hills,_Da_Nang,_Vietnam.jpg` |
| hoi-an-vietnam | `Hội_An,_Ancient_Town,_2020-01_CN-06.jpg` |
| ha-giang-vietnam | `Mã_Pí_Lèng_Pass,_Vietnam.jpg` |
| phu-quoc-vietnam | `Phu_Quoc_Beach.jpg` (file cũ đúng, chỉ sai hash path thumb; Special:FilePath giải quyết) |

Tên file trong seed cũ (`Dragon_Bridge_in_Da_Nang,_Vietnam.jpg`, `Golden_Bridge_-_Ba_Na_Hills.jpg`, `Hoi_An_night.jpg`, `Ma_Pi_Leng_Pass,_Ha_Giang.jpg`) đều là tên bịa, đã xác nhận 404 sau redirect.

## 5. Tiêu chí nghiệm thu

1. `dart run tool/verify_image_urls.dart` PASS trên toàn bộ migrations.
2. Mở Explore trên web build sạch cache: mọi card có ảnh thật hoặc placeholder gradient, console không còn request nào tới `source.unsplash.com` và không còn 404/400 từ `upload.wikimedia.org`.
3. Điểm đến ngoài seed (ví dụ "Koh Lipe, Thailand") lấy được ảnh qua REST summary hoặc hiển thị placeholder, không lỗi đỏ console.
4. `flutter analyze` không lỗi mới, `flutter test` pass kèm test mới cho REST summary parsing và sanitize allowlist.

# Bài học: Sửa tận gốc hệ thống ảnh điểm đến (walkthrough cho học sinh)

> Branch: `fix/image-stability`. Đọc kèm: spec `docs/superpowers/specs/2026-08-30-image-service-stability-design.md` và plan `docs/superpowers/plans/2026-08-30-image-service-stability.md`.
> Tài liệu này giải thích TỪNG thay đổi và VÌ SAO, để các bạn hiểu cách sửa nguyên nhân thay vì vá triệu chứng. Đọc xong nên tự diff từng commit trên branch theo thứ tự.

## 1. Chuyện gì đã xảy ra

Sau đợt "overhaul ImageService với hand-verified Wikimedia URLs" (23/08) và bản vá "Fix explore destination image fallbacks" (30/08), toàn bộ ảnh vẫn chết trên web. Có 4 lỗi độc lập chồng lên nhau:

1. **URL bịa.** Phần lớn tên file trong map `_curatedLandmarks` không tồn tại trên Wikimedia Commons (`Halong_bay_boats.jpg`, `Hoi_An_night.jpg`...). Chúng trông rất thật, nhưng là do AI sinh ra và không ai kiểm chứng bằng máy. Trong seed migration, 4 trên 5 tên file là bịa.
2. **Đoán tay URL thumbnail.** URL dạng `upload.wikimedia.org/.../thumb/7/76/File.jpg/1200px-File.jpg` chứa hash path (`7/76`) do server tính từ tên file. Đoán sai hash là 404. File `Phu_Quoc_Beach.jpg` có thật nhưng hash thật là `b/bf`, không phải `7/76`, và đòi thumb to hơn ảnh gốc thì Wikimedia trả 400.
3. **Fallback bằng dịch vụ đã chết.** `source.unsplash.com` bị khai tử (503) và không gửi CORS header. Bản vá 30/08 thay nó bằng `loremflickr.com`, dịch vụ này cũng trả 403 và cũng không có CORS header. Trên Flutter web (CanvasKit) ảnh được tải bằng `fetch()`, không có CORS header là chết tuyệt đối. Đây là ví dụ điển hình của "vá triệu chứng": thay một dịch vụ chết bằng một dịch vụ chết khác cùng loại.
4. **Bug ẩn nghiêm trọng nhất: blocklist tự chặn nguồn ảnh đúng.** Hàm `_isGoodImage` có blocklist chứa chuỗi `'wikimedia'`. Mọi URL thumbnail hợp lệ đều nằm trên `upload.wikimedia.org`, nên MỌI kết quả trả về từ Wikipedia API đều bị chính app từ chối, và code luôn rơi xuống các fallback hỏng ở trên. Nguồn ảnh đúng đắn duy nhất đã hoạt động suốt thời gian qua, nhưng bị một dòng blocklist bịt miệng.

Bốn lỗi này che nhau: vì (4) chặn nguồn tốt, (1)(2)(3) mới được dùng thường xuyên; vì (1)(2)(3) đôi khi "có vẻ chạy", không ai nghi ngờ (4). Bài học: khi mọi thứ cùng hỏng, phải tách từng tầng ra kiểm chứng độc lập bằng bằng chứng (curl từng URL), không đoán.

## 2. Thiết kế mới: 3 lớp, mỗi lớp một trách nhiệm

```text
Ảnh điểm đến
  1. Bảng destinations (curated, đã verify bằng script)   <- điểm đến phổ biến
  2. Wikipedia REST summary -> Commons search              <- điểm đến bất kỳ do AI gợi ý
  3. Chuỗi rỗng + errorWidget placeholder của UI           <- không bao giờ ô vỡ
```

Nguyên tắc quan trọng nhất: **URL curated là DỮ LIỆU, không phải CODE.** Dữ liệu nằm trong DB, được kiểm chứng bằng script, sửa không cần build lại app. Code chỉ chứa thuật toán tra cứu.

## 3. Đi qua từng commit

### Commit 1: `tool/verify_image_urls.dart` (viết test trước khi sửa)

Script quét mọi URL Wikimedia trong `supabase/migrations/*.sql`, GET follow-redirect từng URL, đòi status 200 VÀ content-type `image/*`. Chạy: `dart run tool/verify_image_urls.dart`.

Ba chi tiết đáng học:

- **Chạy script TRƯỚC khi sửa dữ liệu** và nhìn nó FAIL đủ 5 URL. Đây là tư duy RED-GREEN của TDD áp cho dữ liệu: nếu chưa thấy công cụ kiểm chứng bắt được lỗi thật, bạn chưa biết nó có hoạt động không.
- **Bẫy HEAD 302:** `Special:FilePath` LUÔN trả 302 kể cả khi file không tồn tại (redirect đích mới 404). Kiểm chứng kiểu `curl -I` thấy 302 rồi kết luận "file có thật" là sai. Phải follow đến cùng.
- **Bẫy rate limit:** bắn request dồn dập không có User-Agent, Wikimedia trả 429 và script báo FAIL oan. Fix: thêm User-Agent mô tả rõ + nghỉ 600ms giữa các request. Kết quả kiểm chứng cũng cần đáng tin như code.

Từ giờ quy tắc của repo là: **chữ "verified" chỉ có nghĩa khi là output của script này**, không phải lời hứa trong commit message.

### Commit 2: Sửa seed data

- Migration mới `20260831000300_fix_destination_seed_images.sql` UPDATE 4 slug với URL dạng `Special:FilePath/<tên file>?width=1280`. Dạng URL này để server tự tính hash path và kích thước thumb hợp lệ, loại bỏ cả lớp lỗi (2) vĩnh viễn.
- File seed cũ `20260829000100` cũng được sửa tại chỗ. Bình thường KHÔNG được rewrite migration đã deploy; ở đây được phép vì đã chứng minh nó chưa từng được apply lên project nào (chính lỗi `PGRST205` các bạn gặp là bằng chứng: bảng không tồn tại). Khi nào được sửa migration cũ là một quyết định cần bằng chứng, không phải thói quen.
- 5 tên file mới đều được chọn bằng cách search Commons API rồi verify end-to-end từng file. Không có file nào được "tin" chỉ vì tên nghe hợp lý.

### Commit 3: Viết lại ImageService (kèm test MockClient)

Trước: 690 dòng, 5 tầng fallback, 2 dịch vụ chết, 1 map 230 dòng URL tay. Sau: khoảng 190 dòng, 2 nguồn + 1 trạng thái rỗng.

- **Wikipedia REST summary** (`/api/rest_v1/page/summary/<tên>`): 1 request, CORS chính thức, server trả sẵn `thumbnail.source` hợp lệ. Nâng lên 1280px CHỈ khi `originalimage.width >= 1280` (nhớ lỗi 400 ở trên). So với chuỗi cũ opensearch + images + imageinfo (3 request), ít code hơn và ít chỗ hỏng hơn.
- **`static http.Client client`**: một dòng làm code test được. Test swap `MockClient` vào, giả lập từng response của Wikipedia, và chạy không cần mạng. Trước đây service gọi thẳng `http.get` toàn cục nên không thể test. Xem `test/services/image_service_test.dart`: 6 test phủ các nhánh nâng thumb, fallback vi sang en, blocklist, và trạng thái rỗng.
- **Chuỗi rỗng là trạng thái hợp lệ.** `getImageUrl` bó tay thì trả `''`. Cả 7 chỗ render ảnh đã có `errorWidget` placeholder, nên UI không bao giờ vỡ. `_resolvedImageUrl` trong `destination_suggestion.dart` cũng thôi tự chèn fallback cứng: model không được bịa dữ liệu để trông có vẻ đầy đủ.
- **Sửa blocklist:** bỏ từ `'wikimedia'` (lý do ở mục 1.4). Blocklist theo substring là con dao hai lưỡi: mỗi từ thêm vào phải tự hỏi "nó có match nhầm chuỗi hợp lệ nào không".
- `getImageUrlsFast` giữ lại làm alias mỏng trỏ về `getImageUrls` vì `gemini_service.dart` (file đóng băng, thuộc bạn B) đang gọi nó. Đây là cách tôn trọng ranh giới sở hữu file: không sửa file người khác chỉ để đổi một tên hàm.

### Commit 4: Chống nhiễm lại cache

Cache đa tầng đã lưu sẵn các URL hỏng từ những phiên trước, nghĩa là sửa code xong ảnh vẫn chết vì cache phục vụ lại URL cũ. Hai việc:

- **Xoay tên box Hive** sang `gemini_multi_tier_cache_v2`: vứt toàn bộ cache cũ. Cache là cache, được phép mất; đừng bao giờ ngại reset cache khi format hoặc chất lượng dữ liệu trong đó thay đổi.
- **`sanitizeImageUrls` allowlist theo host** (`upload.wikimedia.org`, `commons.wikimedia.org`, `*.supabase.co`), áp ở MỌI đường đọc và ghi (memory, Hive, Supabase). Allowlist ổn định hơn blocklist: thay vì đuổi theo từng dịch vụ chết (unsplash rồi loremflickr rồi gì nữa?), ta khai báo nguồn nào được phép và mặc định từ chối phần còn lại.
- Test của bạn nào khóa hành vi cũ (ép model tự chèn fallback URL) được viết lại theo contract mới. Test tồn tại để khóa CONTRACT, khi contract đổi có chủ đích thì test đổi theo, kèm comment giải thích vì sao.

## 3.5. Hậu ký: chính người review cũng dính bẫy (commit sửa CORS sau merge)

Trung thực để học: phiên bản đầu của fix này dùng URL dạng `Special:FilePath?width=1280` cho seed, vì nó để server tự tính hash path. Tôi đã verify bằng curl (200 + image/jpeg) và tự tin. Nhưng khi demo trên browser, toàn bộ 5 ảnh seed bị chặn CORS.

Lý do: `Special:FilePath` nằm trên `commons.wikimedia.org` và trả 302 redirect sang `upload.wikimedia.org`. Browser kiểm tra CORS trên TỪNG hop của chuỗi redirect; hop đầu (`commons.wikimedia.org`) không gửi `Access-Control-Allow-Origin`, nên browser dừng ngay tại đó. curl không có khái niệm CORS nên `curl -L` thấy 200 hoàn hảo.

Đây chính xác là vi phạm mục 3 trong checklist bên dưới, do chính người viết checklist phạm phải. Bài học kép:

- Công cụ kiểm chứng phải mô phỏng đúng MÔI TRƯỜNG THẬT sẽ dùng tài nguyên. Với web app, "URL sống" nghĩa là: 200 trực tiếp không redirect, content-type ảnh, VÀ có ACAO header. Verifier đã được nâng cấp để đòi đủ 3 điều kiện này (xem `tool/verify_image_urls.dart`), và bản nâng cấp bắt được đúng 5 URL lỗi trước khi sửa.
- Fix: resolve `Special:FilePath` MỘT LẦN lúc verify để lấy URL trực tiếp `upload.wikimedia.org` (host này gửi `ACAO: *`), lưu URL trực tiếp vào seed (migration `20260831000400`). Allowlist trong `AiCacheService` cũng siết lại: chỉ còn host phục vụ ảnh direct-hit.

## 4. Checklist rút ra cho mọi lần đưa URL bên thứ ba vào app

1. URL do AI (hoặc bạn) "nhớ ra" mặc định là bịa cho đến khi script verify nói ngược lại.
2. Verify nghĩa là: status 200 TRỰC TIẾP (không redirect), content-type đúng loại. HEAD 302 không phải bằng chứng, và curl -L thấy 200 cũng chưa phải bằng chứng cho browser.
3. Chạy trên web thì bắt buộc: response có `Access-Control-Allow-Origin`, và KHÔNG có redirect trong đường đi (browser kiểm CORS trên từng hop). curl không mô phỏng CORS, phải kiểm header một cách tường minh.
4. URL dữ liệu để trong DB/seed, không hardcode trong code.
5. Fallback phải phân biệt "kết quả rỗng" và "exception", và tầng cuối cùng phải là thứ KHÔNG THỂ hỏng (placeholder local), không phải một HTTP call khác.
6. Có cache ở giữa thì sửa nguồn chưa đủ: phải xử lý dữ liệu hỏng đã nằm trong cache (xoay version hoặc sanitize khi đọc).
7. Blocklist substring phải rà từng từ xem có match nhầm chuỗi hợp lệ; cân nhắc allowlist khi danh sách "thứ xấu" mở rộng theo thời gian.

## 5. Việc còn lại (không thuộc branch này)

- Giáo viên chạy `supabase db push` sau khi merge để apply `20260829000100` (đang thiếu, gây PGRST205) và `20260831000300`.
- Lỗi fallback exception vs rỗng ở `explore_screen._loadExplore` (Gemini fallback chỉ chạy khi kết quả rỗng, không chạy khi DB ném exception) thuộc phạm vi tuần 1 của các bạn, chưa sửa ở đây.
- Đơn giản hóa cache đa tầng (bỏ tầng Supabase) là quyết định đã bàn với giáo viên, nằm trong task tuần tới của bạn B.

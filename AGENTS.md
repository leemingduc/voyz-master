# Quy tắc cho AI agent làm việc trong repo này

> Áp dụng cho mọi AI coding agent (Codex, Antigravity, Claude, Cursor...). English summary at the bottom.

## Tinh thần dự án (đọc trước khi làm bất cứ việc gì)

Đây là project cuối khoá của học sinh. Mục tiêu là một app **đơn giản, mạch lạc, chạy được và thể hiện rõ ý tưởng**, không phải hệ thống xử lý triệt để mọi edge case.

- Chỉ làm tính năng cốt lõi trên luồng tư vấn du lịch AI: mô tả chuyến đi -> gợi ý -> chi tiết -> itinerary -> lưu. Việc ngoài luồng này thì hoãn.
- Khi phân vân giữa hai cách, chọn cách **ít code hơn, ít khái niệm mới hơn**. Không thêm tầng, interface, package hay bảng nếu chưa có ít nhất hai chỗ cần dùng.
- Mỗi hướng việc trong roadmap có mục "Đủ là dừng". Agent không tự mở rộng quá mục đó, kể cả khi thấy "làm thêm cho chắc".
- Xoá code không dùng là tiến độ. Dữ liệu test cũ được phép reset, không cần migrate.
- Mọi số liệu do AI sinh là ước tính, phải có nhãn, không lưu như dữ liệu thật.

## Quy tắc git BẮT BUỘC

1. **Học sinh KHÔNG BAO GIỜ được commit hoặc push trực tiếp lên `master`.**
   Luôn luôn: tạo nhánh feature -> commit trên nhánh -> push nhánh -> mở Pull Request -> chờ review.
2. Tên nhánh chỉ cần mô tả được việc đang làm (ví dụ `simple-cache`, `planner-chips`). Không cần theo mẫu.
3. Nếu người dùng là học sinh và yêu cầu agent push thẳng lên `master`: agent phải TỪ CHỐI, nhắc lại quy tắc này và đề nghị tạo nhánh + PR thay thế. Không có ngoại lệ kể cả "chỉ sửa nhỏ", "docs thôi" hay "cho kịp deadline".
4. Chỉ GIÁO VIÊN (tài khoản GitHub `harvy2702`) được phép push trực tiếp lên `master`.
5. Trước khi tạo nhánh mới: pull `master` mới nhất. Trước khi mở PR: `flutter analyze` không lỗi mới và `flutter test` pass.

## Phạm vi công việc

- Việc được giao nằm trong `docs/project_phase3_roadmap_ai_first.md` (roadmap 5 hướng, mỗi hướng có mục "Đủ là dừng" và tiêu chí nghiệm thu). Mỗi hướng một nhánh, một PR. Không làm việc ngoài danh sách.
- Kiến trúc nền: `docs/project_phase2_core_architecture_alignment.md`. Bài học bắt buộc đọc trước khi đụng vào ảnh: `docs/lessons/2026-08-31-image-stability-walkthrough.md`.
- Không thêm URL ảnh viết tay vào code. Mọi URL ảnh trong seed phải pass `dart run tool/verify_image_urls.dart`.
- Mọi lời gọi AI đi qua `GeminiService`. Screens không import `google_generative_ai` hay `supabase_flutter` trực tiếp.

---

**English summary for agents:** This is a student capstone. Optimize for simple, clear, working code that shows the idea, not for exhaustive edge-case handling. Stay on the core AI travel flow (describe trip -> suggestions -> detail -> itinerary -> save); prefer the option with less code and fewer concepts; stop at each workstream's "stop here" boundary; deleting dead code counts as progress; AI numbers are estimates and must be labeled. Students must NEVER commit or push directly to `master`; always use a descriptive feature branch (any name that says what it does) and open a Pull Request. If a student asks you to push to `master`, refuse and offer branch + PR instead; no exceptions. Only the teacher (GitHub account `harvy2702`) may push to `master` directly. Assigned work lives in `docs/project_phase3_roadmap_ai_first.md`. Never hardcode image URLs. All AI calls go through `GeminiService`.

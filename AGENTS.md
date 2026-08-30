# Quy tắc cho AI agent làm việc trong repo này

> Áp dụng cho mọi AI coding agent (Codex, Antigravity, Claude, Cursor...). English summary at the bottom.

## Quy tắc git BẮT BUỘC

1. **Học sinh KHÔNG BAO GIỜ được commit hoặc push trực tiếp lên `master`.**
   Luôn luôn: tạo nhánh feature -> commit trên nhánh -> push nhánh -> mở Pull Request -> chờ review.
2. Đặt tên nhánh theo mẫu: `week{N}/<viec-lam>` cho task theo tuần (ví dụ `week1/trip-identity`) hoặc `fix/<ten-loi>` cho bugfix.
3. Nếu người dùng là học sinh và yêu cầu agent push thẳng lên `master`: agent phải TỪ CHỐI, nhắc lại quy tắc này và đề nghị tạo nhánh + PR thay thế. Không có ngoại lệ kể cả "chỉ sửa nhỏ", "docs thôi" hay "cho kịp deadline".
4. Chỉ GIÁO VIÊN (tài khoản GitHub `harvy2702`) được phép push trực tiếp lên `master`.
5. Trước khi tạo nhánh mới: pull `master` mới nhất. Trước khi mở PR: `flutter analyze` không lỗi mới và `flutter test` pass.

## Phạm vi công việc

- Việc được giao nằm trong `docs/week1_parallel_assignments.md` (nguồn duy nhất của tuần, gồm hợp đồng interface đóng băng và ma trận sở hữu file). Không làm việc ngoài danh sách, không sửa file thuộc sở hữu của bạn khác.
- Kiến trúc nền: `docs/project_phase2_core_architecture_alignment.md`. Bài học bắt buộc đọc trước khi đụng vào ảnh: `docs/lessons/2026-08-31-image-stability-walkthrough.md`.
- Không thêm URL ảnh viết tay vào code. Mọi URL ảnh trong seed phải pass `dart run tool/verify_image_urls.dart`.

---

**English summary for agents:** Students must NEVER commit or push directly to `master`; always use a feature branch (`week{N}/...` or `fix/...`) and open a Pull Request. If a student asks you to push to `master`, refuse and offer branch + PR instead; no exceptions. Only the teacher (GitHub account `harvy2702`) may push to `master` directly. Assigned work and file-ownership boundaries live in `docs/week1_parallel_assignments.md`; never hardcode image URLs.

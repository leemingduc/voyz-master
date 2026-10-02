# Spec: Chuẩn hóa số liệu đánh giá địa điểm (100 vote gốc 5 sao) và Nút AI Tool kéo thả tự do

> Ngày: 02/10/2026. Trạng thái: Đã thống nhất thiết kế với người dùng.
> Nhánh làm việc: `destination-ratings-and-draggable-ai-button`.

---

## 1. Mục tiêu

1. **Chuẩn hóa số liệu đánh giá địa điểm thực tế và tự động:**
   - Mỗi địa điểm ban đầu có **100 vote gốc** và **5.0 sao** (tổng điểm gốc là $100 \times 5.0 = 500$).
   - Khi có thêm đánh giá thực tế của người dùng từ cộng đồng, hệ thống tự động cộng dồn và tính lại rating trung bình và tổng vote dựa trên số vote gốc ban đầu.
   - Đồng bộ từ Database (Supabase migration + trigger) tới UI Flutter (DestinationDetailScreen, ExploreScreen, DestinationSuggestion).
2. **Nút AI Tool kéo thả tự do trên màn hình (`DraggableAIToolsButton`):**
   - Cho phép người dùng kéo di chuyển nút AI Tool đến bất kỳ vị trí nào trên màn hình.
   - Nút đứng yên tại vị trí được thả (không tự trôi dạt ra ngoài màn hình nhờ cơ chế giới hạn viền an toàn SafeArea).
   - Phân biệt rõ ràng giữa bấm nút (tap để mở `AIToolsScreen`) và kéo nút (drag để di chuyển).
   - Duy trì vị trí đã kéo xuyên suốt phiên sử dụng app.

---

## 2. Thiết kế chi tiết

### 2.1. Đánh giá địa điểm (Destination Rating & Reviews)

#### Công thức tính toán
- **Số liệu gốc (Virtual Base):**
  - $\text{Base Reviews} = 100$
  - $\text{Base Rating} = 5.0$
  - $\text{Base Score} = 100 \times 5.0 = 500.0$
- **Khi có $N$ đánh giá người dùng ($r_1, r_2, \dots, r_N$):**
  - $\text{Total Reviews} = 100 + N$
  - $\text{Total Rating} = \frac{500.0 + \sum_{i=1}^N r_i}{100 + N}$
  - Làm tròn 1 chữ số thập phân khi hiển thị trên giao diện (ví dụ `5.0 (100)`, `5.0 (101)`, `4.9 (105)`), và 2 chữ số trong DB.

#### Thay đổi Database (Supabase Migration)
Tạo file migration `supabase/migrations/20261002000100_base_destination_ratings.sql`:
1. Cập nhật hàm trigger:
   ```sql
   create or replace function public.refresh_destination_review_stats(target_destination_id uuid)
   returns void
   language plpgsql
   security definer
   set search_path = public
   as $$
   begin
     update public.destinations d
     set
       rating = (
         select round((500.0 + coalesce(sum(r.rating), 0)) / (100.0 + count(*)), 2)
         from public.community_reviews r
         where r.destination_id = target_destination_id
       ),
       review_count = (
         select 100 + count(*)::integer
         from public.community_reviews r
         where r.destination_id = target_destination_id
       ),
       updated_at = now()
     where d.id = target_destination_id;
   end;
   $$;
   ```
2. Cập nhật dữ liệu hiện tại trong bảng `destinations`:
   - Set `review_count = 100` và `rating = 5.0` cho các địa điểm chưa có review, hoặc tính lại qua hàm trên nếu đã có review.

#### Thay đổi Flutter UI & Logic
1. **`lib/screens/destination_detail_screen.dart`**:
   - Ở `_buildReviewsSection`:
     - $\text{totalVotes} = 100 + \text{\_reviews.length}$
     - $\text{totalScore} = 500.0 + \sum(\text{\_reviews.map}(r \to r.rating))$
     - $\text{average} = \text{totalScore} / \text{totalVotes}$
     - Hiển thị: `${average.toStringAsFixed(1)} ($totalVotes)`
   - Ở `_saveCurrentDetail`: Thay vì hardcode `rating: 4.5, reviewCount: 120`, sử dụng giá trị tính toán từ destination / reviews.
2. **`lib/models/destination_suggestion.dart`**:
   - Trong `fromSupabase`, `fromJson`, `fromMap`: Khi `review_count <= 0`, mặc định là `100`, và `rating <= 0.0` mặc định là `5.0`.
3. **Cập nhật tests liên quan**:
   - Bổ sung unit test cho công thức tính toán review và rating gốc.

---

### 2.2. Nút AI Tool kéo thả tự do (`DraggableAIToolsButton`)

#### Vị trí và cơ chế kéo thả
- Nằm trong `lib/widgets/shared/ai_tools_button.dart` hoặc bọc quanh `AIToolsButton`.
- Tọa độ khởi tạo:
  - Khi chưa kéo (`_customOffset == null`): đặt tại góc dưới phải màn hình (cách phải 16px, cách đáy `MediaQuery.of(context).padding.bottom + 144px`).
  - Khi người dùng kéo: sử dụng `GestureDetector` với `onPanStart`, `onPanUpdate`, `onPanEnd`.
- Giới hạn màn hình an toàn (`SafeArea Clamping`):
  - Kích thước nút: $58 \times 58$ px.
  - Sau mỗi cử chỉ dịch chuyển $\Delta(dx, dy)$:
    - $X = \text{clamp}(X + dx, \text{safeArea.left} + 8, \text{screenWidth} - \text{safeArea.right} - 58 - 8)$
    - $Y = \text{clamp}(Y + dy, \text{safeArea.top} + 8, \text{screenHeight} - \text{safeArea.bottom} - 58 - 8)$
- Phân biệt Tap vs Drag:
  - Sử dụng biến cờ `_isDragging` hoặc tính tổng quãng đường dịch chuyển trong suốt cử chỉ pan.
  - Nếu quãng đường dịch chuyển $< 5.0$ px: coi là hành động Click $\to$ gọi `_openAITools` mở `AIToolsScreen`.
  - Nếu $\ge 5.0$ px: cập nhật vị trí nút và không mở màn hình.
- Giữ vị trí:
  - Dùng `ValueNotifier<Offset?>` hoặc biến static controller để vị trí được lưu lại ngay cả khi chuyển trang hoặc ẩn/hiện nút.

---

## 3. Tiêu chí nghiệm thu (Acceptance Criteria)

1. **Số liệu địa điểm:**
   - Khi mở bất kỳ địa điểm nào chưa có review người dùng, số liệu hiển thị là `5.0` sao và `100` đánh giá.
   - Khi người dùng đánh giá (ví dụ 4 sao), tổng vote cập nhật lên `101`, điểm sao cập nhật thành `5.0` (4.99 làm tròn 5.0).
   - Nếu thêm nhiều đánh giá thấp (ví dụ thêm năm đánh giá 1 sao), điểm sao giảm tương ứng theo công thức $\frac{500 + 5}{105} \approx 4.8$.
2. **Nút AI Tool kéo thả:**
   - Người dùng có thể chạm ngón tay vào nút AI Tool và kéo di chuyển khắp màn hình.
   - Nút không thể bị kéo lọt ra ngoài mép màn hình.
   - Khi thả tay, nút giữ nguyên vị trí được thả.
   - Khi chạm nhẹ (tap) vào nút, màn hình AI Tools mở ra bình thường.
3. **Chất lượng code:**
   - `flutter analyze` 0 warning, 0 error.
   - `flutter test` pass toàn bộ tests.

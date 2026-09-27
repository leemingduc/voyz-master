# Thiết kế Kỹ thuật: Linh Vật Bé Tên Lửa AIVIVU & Hiệu Ứng Loading Đặc Trưng

**Ngày:** 2026-09-27  
**Nhánh:** `image-loading-effects`  
**Mục tiêu:**
1. Tạo widget linh vật đặc trưng: **"Bé tên lửa thám hiểm AIVIVU" (`AivivuRocketMascot`)** bay lượn trong vũ trụ với vệt lửa sao lấp lánh và hào quang gradient thương hiệu.
2. Xây dựng component **`AivivuLoadingIndicator`** thay thế hoàn toàn các vòng xoay `CircularProgressIndicator` đơn điệu trên các màn hình chính (`DestinationDetailScreen`, `DestinationPlanScreen`, `CulturalTipsScreen`, `ExploreScreen`).
3. Cải tiến hiệu ứng nạp ảnh **`DestinationImage`** với dấu ấn AIVIVU (biểu tượng tên lửa vũ trụ mini phát sáng + nhịp thở pulse + dòng chữ thông báo rõ ràng: "AIVIVU đang nạp ảnh điểm đến...").

---

## 1. Linh vật `AivivuRocketMascot`

### 1.1 Tạo hình bằng CustomPainter (Vector sắc nét mọi tỷ lệ)
- **Đầu và thân tên lửa:** Hình bầu dục cong mềm mại, phối màu trắng ngà và tím/hồng thương hiệu AIVIVU (`AppTheme.brandGradient`).
- **Kính chắn gió & Mắt cười:** Vòm kính màu cyan vũ trụ với cặp mắt cười vui tươi, phản chiếu tia sáng lấp lánh.
- **Cánh/Vây thám hiểm:** 2 cánh bên và cánh đuôi uốn cong thể thao, bo góc an toàn, viền gradient hồng tím.
- **Động cơ phản lực & Vệt stardust:** Miệng xả phản lực phun ngọn lửa vàng-hồng co giãn nhịp nhàng, bên dưới tỏa ra 3-4 hạt sao lấp lánh nhấp nhô theo chu kỳ.

### 1.2 Animation
- Điều khiển bởi `AnimationController` chu kỳ 1600ms (lặp lại vô tận):
  - Dịch chuyển trục Y: Bobbing `sin(progress * 2 * pi) * 6.0` tạo cảm giác bồng bềnh không trọng lực.
  - Nghiêng góc (Tilt): Nghiêng nhẹ từ -4 độ đến +4 độ theo nhịp bay.
  - Ngọn lửa và tia sao: Co giãn scale từ 0.8 đến 1.2.

---

## 2. Component `AivivuLoadingIndicator`

### 2.1 Cấu trúc Component
- Constructor:
  ```dart
  const AivivuLoadingIndicator({
    super.key,
    this.message,
    this.size = 80.0,
  });
  ```
- Hiển thị:
  - Phía trên: `AivivuRocketMascot(size: size)` đang bay lượn và tỏa sáng.
  - Phía dưới: Dòng thông điệp du lịch truyền cảm hứng (màu `Colors.white.withValues(alpha: 0.85)` hoặc tùy chỉnh `message`).
  - Vòng quỹ đạo stardust mỏng phát sáng nhẹ nhàng tạo chiều sâu không gian.

### 2.2 Vị trí áp dụng
- `DestinationDetailScreen`: Khi đang chờ AI tải chi tiết điểm đến.
- `DestinationPlanScreen`: Khi đang chờ AI lập kế hoạch lịch trình.
- `CulturalTipsScreen`: Khi đang chờ AI nạp mẹo văn hoá & lưu ý du lịch.
- `ExploreScreen`: Khi đang chờ tải danh sách điểm đến gợi ý.

---

## 3. Cải tiến `DestinationImage` với nét riêng AIVIVU

### 3.1 Giao diện Shimmer nạp ảnh
- Thay thế icon phong cảnh chung chung trong `ShimmerLoadingBox`:
  - Biểu tượng tên lửa thám hiểm AIVIVU mini hoặc biểu tượng máy ảnh vũ trụ phát sáng gradient (`AppTheme.cyan` và `AppTheme.primaryPink`).
  - Hiệu ứng nhịp thở phát sáng (opacity và scale pulse nhẹ nhàng).
  - Nhãn hiển thị mờ ở trung tâm:
    - Text: *"AIVIVU đang nạp ảnh..."*
    - Style: `fontSize: 11`, `letterSpacing: 0.5`, `color: Colors.white.withValues(alpha: 0.45)`.
- Khi ảnh hoàn tất tải: Hiệu ứng `fadeInDuration: Duration(milliseconds: 400)` đưa ảnh hiển thị rõ ràng, mượt mà.

---

## 4. Kiểm thử & Nghiệm thu
- Widget tests cho `AivivuRocketMascot`, `AivivuLoadingIndicator`, và `DestinationImage`.
- Chạy `flutter analyze` và `flutter test` đảm bảo 100% test pass.

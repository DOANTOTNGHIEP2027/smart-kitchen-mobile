# SMART KITCHEN MOBILE — DESIGN SYSTEM (HỆ QUY CHUẨN THIẾT KẾ UI/UX)

> **Tài liệu tham chiếu chuẩn hóa giao diện người dùng cho ứng dụng Flutter `smart-kitchen-mobile`**  
> *Được tổng hợp từ phân tích 20 màn hình Mockups (`ai-native/docs/design/frontend/mockups/*.html`) kết hợp bộ tri thức thiết kế chuyên sâu **UI/UX Pro Max** (Mobile / Material 3 Expressive & Soft UI Evolution).*

---

## 1. TRIẾT LÝ THIẾT KẾ (DESIGN PHILOSOPHY)

### 1.1. Phong cách chủ đạo: Soft Modern Kitchen
Ứng dụng quản lý nhà bếp thông minh, kho thực phẩm, công thức nấu ăn và dinh dưỡng gia đình đòi hỏi một phong cách giao diện mang lại cảm giác:
* **Ấm cúng & Tươi mới (Warmth & Freshness):** Truyền tải năng lượng tích cực của gian bếp gia đình và độ tươi ngon của nguyên liệu.
* **Mềm mại & Thoáng đãng (Soft & Airy):** Loại bỏ hoàn toàn cảm giác thô cứng, nặng nề của các bảng biểu quản lý kho truyền thống. Sử dụng không gian thở (white space) rộng rãi, các góc bo tròn hữu cơ và bóng đổ môi trường (ambient shadow) tinh tế.
* **Tập trung & Trực quan trên Mobile (Mobile-First Ergonomics):** Tối ưu hóa cho thao tác một tay khi đang nấu nướng hoặc dọn dẹp tủ lạnh: touch target lớn (tối thiểu 48dp), phân cấp thị giác rõ ràng, hạn chế tối đa số lần nhấn và phân tâm thị giác.

### 1.2. 5 Nguyên Tắc Bất Biến (Core Principles)
1. **Màu Cam Tươi Mới (#FF7A45):** Bám sát màu sắc nhận diện từ các mockup gốc (`--accent: #ff7a45`), kết hợp các sắc độ cam ấm bổ trợ để tạo chiều sâu thị giác.
2. **Tuyệt Đối Không Dùng Gradient (Strictly Solid Colors):** Không sử dụng `LinearGradient` hay dải màu chuyển tiếp. Toàn bộ nút bấm, thẻ bài, thanh công cụ, nền màn hình đều dùng màu phẳng (solid) kết hợp cùng hệ thống màu nền mềm (tonal surfaces) để đạt độ thanh thoát, hiện đại và cao cấp.
3. **Bo Góc Mềm Mại (Rounded Geometry):** Mọi thành phần đều có độ bo góc nhất quán: `8dp` (nhỏ/badge), `14-16dp` (input/button), `16-20dp` (card/dialog), `999dp` (dạng viên thuốc - pill cho chip/search bar/badge).
4. **Bố Cục Thoáng Đạt (Spacious 8-pt Grid):** Khoảng cách đệm (padding) trong card và màn hình tối thiểu `16dp`, khoảng cách giữa các khối `12 - 20dp`. Tránh nhồi nhét thông tin dày đặc.
5. **Form Mềm Mại & Thân Thiện (Polished Forms):** Thay thế các ô nhập thô ráp, góc cạnh bằng các trường nhập có nền sáng nhẹ (`#F7F7FA`), bo góc lớn `14-16dp`, viền hairline siêu mảnh và hiệu ứng viền cam ấm khi kích hoạt (focus).

---

## 2. HỆ THỐNG MÀU SẮC TOÀN DIỆN (COLOR SYSTEM)

Hệ thống màu này được trích xuất trực tiếp từ các biến CSS `:root` của 20 tệp mockups (`inventory-management.html`, `recipe-list-detail-screens.html`, `nutrition-summary-widget.html`, `auth-password-reset.html`...) và được tối ưu lại theo chuẩn độ tương phản WCAG AA/AAA của **UI/UX Pro Max**.

### 2.1. Bảng Màu Nhận Diện & Thương Hiệu (Brand Colors)

| Tên Token Flutter | Mã Hex | Giá trị Mockup gốc | Vai trò & Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| `primary` | `#FF7A45` | `--accent: #ff7a45` | Màu cam tươi chủ đạo (Nút bấm chính, icon đang chọn, link, chỉ báo tiến độ). |
| `primaryDark` | `#E65A20` | *(Tối ưu hóa UI Pro Max)* | Cam đậm dùng cho trạng thái nhấn giữ (Pressed), hover hoặc điểm nhấn tương phản cao. |
| `primaryContainer` | `#FFF2EA` | `--bg-soft: #fff4ec` | Nền cam phấn siêu nhạt (Soft Warm Peach). Dùng làm nền chip active, card nổi bật, icon container. |
| `primaryLight` | `#FFE4D6` | *(Bổ trợ)* | Nền viền cam nhạt, thanh chỉ báo bottom bar, badge highlight. |
| `onPrimary` | `#FFFFFF` | `#ffffff` | Màu chữ và biểu tượng nằm trên nền `primary`. |
| `onPrimaryContainer` | `#9A3412` | *(WCAG AAA 7.2:1)* | Màu chữ/icon nằm trên nền `primaryContainer` (đảm bảo độ đọc rõ ràng, không bị mờ). |

### 2.2. Bảng Màu Nền & Bề Mặt (Neutral & Surface Colors)

| Tên Token Flutter | Mã Hex | Giá trị Mockup gốc | Vai trò & Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| `background` | `#F8F9FA` | `--bg: #f2f2f5` *(Cải tiến)* | Nền Scaffold toàn ứng dụng. Sáng sủa, sạch sẽ, ấm áp hơn màu xám lạnh cũ. |
| `surface` | `#FFFFFF` | `--surface: #ffffff` | Bề mặt thẻ Card, Dialog, BottomSheet, thanh AppBar. |
| `surfaceSubtle` | `#F4F4F7` | `#fafafa` / `#eee` | Nền ô tìm kiếm, nền form input ở trạng thái nghỉ, phân đoạn tab. |
| `surfaceWarm` | `#FFFBF8` | `#fffaf7` | Nền card đánh giá sao (Rating card), thông báo ưu đãi ấm áp. |
| `borderSubtle` | `#EBEBEF` | `--border: #e5e5ea` | Đường viền hairline siêu mảnh (1px) cho Card, Divider, Input. Mềm mại, không sắc nét. |
| `borderFocus` | `#FF7A45` | *(Đồng bộ)* | Đường viền khi con trỏ đang nhập liệu trong ô Input. |
| `textPrimary` | `#1C1C1E` | `--text: #1c1c1e` | Văn bản chính: Tiêu đề màn hình, tên món ăn, tên thực phẩm (Tương phản cao > 13:1). |
| `textSecondary` | `#71717A` | `--muted: #8e8e93` *(Cải tiến)* | Văn bản phụ: Ngày hết hạn, mô tả phụ, hướng dẫn, đơn vị đo (Rõ nét và dễ đọc hơn). |
| `textDisabled` | `#A1A1AA` | `#c7c7cc` | Văn bản/icon ở trạng thái vô hiệu hóa. |

### 2.3. Bảng Màu Trạng Thái & Kho Hàng (Status & Inventory Lifecycle)

Các màu trạng thái được thiết kế theo cặp: **Màu chữ/viền đậm nét** + **Màu nền mềm (container)** để tạo ra các huy hiệu (badge/chip) thông tin trực quan, không gây chói mắt.

| Trạng thái | Token Chữ & Viền | Token Nền Container | Ý nghĩa & Vị trí áp dụng |
| :--- | :--- | :--- | :--- |
| **Tươi ngon / Còn hạn / Thành công** | `success`: `#22C55E` (`#34A853`) | `successContainer`: `#EAF7EE` | Thực phẩm còn nhiều hạn, công thức đủ nguyên liệu, thao tác lưu thành công. |
| **Sắp hết hạn / Cảnh báo / Ít đồ** | `warning`: `#D97706` (`#B58900`) | `warningContainer`: `#FEF7EA` | Thực phẩm còn 1-3 ngày hết hạn, nguyên liệu sắp hết, banner nhắc nhở. |
| **Hết hạn / Thiếu hàng / Lỗi** | `error`: `#EF4444` (`#E5484D`) | `errorContainer`: `#FDECEC` | Thực phẩm đã hết hạn, thiếu nguyên liệu nấu ăn, báo lỗi form nhập liệu. |
| **Thông tin / Chia sẻ / Gia đình** | `info`: `#2563EB` (`#2952CC`) | `infoContainer`: `#EFF6FF` | Banner thông tin kết nối, chia sẻ giỏ hàng với thành viên, đồng bộ Bluetooth. |
| **Xung đột / Góp ý gia đình** | `accentPurple`: `#7C3AED` | `purpleContainer`: `#F3E8FF` | Badge xung đột ý kiến bình chọn món ăn (`.badge-conflict` trong mockup). |

### 2.4. Bảng Màu Dinh Dưỡng Chuyên Biệt (Nutrition Compliance System)

Trích xuất trực tiếp từ component `nutrition-summary-widget.html`:

| Xếp loại dinh dưỡng | Token Màu | Token Container | Mô tả |
| :--- | :--- | :--- | :--- |
| **Xuất sắc (Excellent)** | `#2E7D32` | `#E8F5E9` | Chế độ ăn hoàn toàn đạt chỉ tiêu calo/chất xơ. |
| **Tốt (Good)** | `#1565C0` | `#E3F0FD` | Chế độ ăn ổn định, gần sát ngưỡng mục tiêu. |
| **Cần cải thiện (Needs Work)** | `#D97706` | `#FFF8E1` | Thiếu hụt đạm hoặc dư thừa đường/chất béo. |
| **Kém (Poor)** | `#C62828` | `#FDECEA` | Lệch chỉ tiêu dinh dưỡng nghiêm trọng. |
| **Chưa đủ dữ liệu (Unknown)** | `#64748B` | `#F1F5F9` | Ngày chưa nhập đủ nhật ký món ăn. |

---

## 3. QUY CHUẨN FORM & TRƯỜNG NHẬP LIỆU (POLISHED FORMS)

> *Khắc phục nhược điểm "form đang hơi thô ráp, góc cạnh" của các mockup cũ bằng giải pháp Modern Soft Input.*

### 3.1. Các vấn đề của Mockup cũ & Giải pháp UI/UX Pro Max

| Yếu tố | Mockup Cũ (Thô ráp) | Chuẩn Mới (Soft Modern Flutter) |
| :--- | :--- | :--- |
| **Nền ô nhập** | Nền trắng viền xám đậm hoặc xám xịt `#FAFAFA` | Nền kem xám siêu mềm `#F7F7FA`, khi focus chuyển sang `#FFFFFF` |
| **Bo góc** | Bo 8 - 10dp hơi cứng | Bo cong mềm mại **14 - 16dp** |
| **Đường viền** | Viền đen/xám đơn điệu 1px cứng ngắc | Trạng thái nghỉ: viền hairline siêu mảnh `#EBEBEF`. Khi Focus: viền cam tươi `#FF7A45` (1.5dp) |
| **Khoảng đệm (Padding)** | `padding: 10px 12px` (nhỏ, dễ bấm hụt) | `EdgeInsets.symmetric(horizontal: 16, vertical: 15)` (rộng rãi, chuẩn tay bấm) |
| **Chiều cao trường nhập** | ~40dp | Chuẩn công thái học mobile: **52 - 56dp** |
| **Phản hồi lỗi** | Chỉ hiện dòng chữ đỏ đơn điệu phía dưới | Nền chuyển sang `#FFF5F5`, viền đỏ san hô `#EF4444`, icon cảnh báo ở suffix |

### 3.2. Cấu trúc một Form Input chuẩn (Flutter Form Specification)

1. **Nhãn trường (Label):**
   * Đặt phía trên ô nhập (Top-aligned), font chữ `Nunito` hoặc System Sans, cỡ `13sp`, `FontWeight.w600`, màu `#1C1C1E`.
   * Đối với trường bắt buộc: Thêm dấu hoa thị cam `*` (`#FF7A45`).
2. **Khu vực nhập liệu (Field Body):**
   * Sử dụng `TextFormField` trong `Form` quản lý bởi `GlobalKey<FormState>`.
   * `Prefix Icon`: Đặt biểu tượng minh họa (ví dụ icon Email, Khóa, Thực phẩm) màu `#8E8E93`, khi focus chuyển sang `#FF7A45`.
   * `Suffix Icon`: Nút xóa nhanh (clear button) hoặc nút ẩn/hiện mật khẩu với vùng chạm tối thiểu `40x40dp`.
3. **Trợ giúp & Báo lỗi (Helper & Error Text):**
   * `helperText`: Font `12sp`, màu `#71717A`, cung cấp gợi ý ngắn gọn (VD: *"Hạn sử dụng ghi trên bao bì"*).
   * `errorText`: Font `12sp`, màu `#EF4444`, đi kèm biểu tượng chấm than tròn nhỏ, không làm đẩy giật khung hình khi xuất hiện (`errorMaxLines: 2`).
4. **Bàn phím Mobile:**
   * Bắt buộc cấu hình chính xác `keyboardType`: `TextInputType.emailAddress`, `TextInputType.numberWithOptions(decimal: true)`, `TextInputType.phone`...
   * Cấu hình `textInputAction`: `TextInputAction.next` giữa các ô, `TextInputAction.done` ở ô cuối cùng.

---

## 4. QUY CHUẨN THÀNH PHẦN (COMPONENT SPECIFICATIONS)

### 4.1. Nút Bấm (Buttons) — 100% Solid Color (Không Gradient)

Mockup ban đầu sử dụng `linear-gradient(135deg, #ff9d6e, #ff7a45)`. Theo yêu cầu thiết kế mới, **loại bỏ hoàn toàn gradient**, áp dụng màu solid với độ tương phản sắc sảo:

#### A. Primary Button (Nút hành động chính: Lưu kho, Bắt đầu nấu, Đăng nhập)
* **Màu nền:** Solid `#FF7A45` (Cam tươi mới).
* **Màu chữ & icon:** `#FFFFFF` (Font `15sp`, `FontWeight.w700`).
* **Bo góc:** `BorderRadius.circular(16)` hoặc Pill `BorderRadius.circular(999)`.
* **Chiều cao:** Cố định `52dp` (đảm bảo chuẩn chạm ngón tay).
* **Bóng đổ (Shadow):** Bóng cam mềm ambient `BoxShadow(color: Color(0x33FF7A45), blurRadius: 16, offset: Offset(0, 6))` — tạo cảm giác nút nổi mềm mại tự nhiên mà không cần đến gradient!
* **Trạng thái Disabled:** Nền `#F0F0F3`, chữ `#A1A1AA`, không có bóng đổ.
* **Trạng thái Loading:** Giữ nguyên nền cam, hiển thị `CircularProgressIndicator` trắng (size 20dp, strokeWidth 2.5).

#### B. Secondary / Tonal Button (Hành động phụ: Thêm mục, Huỷ, Xuất file)
* **Màu nền:** Solid `#FFF2EA` (Cam kem ấm).
* **Màu chữ & icon:** `#FF7A45` (Cam đậm, `FontWeight.w700`).
* **Bo góc:** `BorderRadius.circular(16)`.
* **Chiều cao:** `48 - 52dp`.
* **Bóng đổ:** Không đổ bóng (`elevation: 0`).

#### C. Outline Button (Hành động thứ cấp: Xem thêm, Bộ lọc)
* **Màu nền:** `#FFFFFF` hoặc trong suốt.
* **Đường viền:** `Border.all(color: Color(0xFFEBEBEF), width: 1.5)`.
* **Màu chữ:** `#1C1C1E` (`FontWeight.w600`).
* **Bo góc:** `BorderRadius.circular(14)`.

#### D. Destructive Button (Xóa thực phẩm, Đăng xuất, Bỏ kết nối)
* **Màu nền:** Nền phụ `#FDECEC` chữ `#EF4444` (hoặc Nền solid `#EF4444` chữ trắng khi cần cảnh báo tối đa).
* **Bo góc:** `BorderRadius.circular(14)`.

---

### 4.2. Thẻ Nội Dung (Cards) — Bo Góc & Mềm Mại

Khắc phục tình trạng các card trong mockup hiện tại đang có viền xám thô và phẳng lì:

#### A. Inventory Item Card (Thẻ thực phẩm trong tủ lạnh / kho)
* **Cấu trúc:**
  * Container nền `#FFFFFF`, bo góc `BorderRadius.circular(18)`.
  * Viền hairline siêu mảnh `Border.all(color: Color(0xFFF0EAE5), width: 1.0)`.
  * Đổ bóng môi trường: `BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 4))`.
  * Khoảng đệm trong (Padding): `14dp` hoặc `16dp`.
* **Bố cục nội bộ:**
  * Bên trái: Icon thực phẩm hoặc ảnh chụp đặt trong hộp tròn/bo góc `12dp` nền `#FFF2EA`.
  * Ở giữa: Tên thực phẩm (`15sp`, `FontWeight.w700`), vị trí bảo quản (Ngăn mát / Ngăn đông, `12sp`, `#71717A`).
  * Bên phải: Số lượng nổi bật (`14sp`, `FontWeight.w700`).
  * Dưới cùng: Dải Badge trạng thái hạn sử dụng (xanh/vàng/đỏ) dạng pill nhỏ gọn.

#### B. Recipe Card (Thẻ công thức nấu ăn - Dạng lưới 2 cột)
* **Cấu trúc:**
  * Nền trắng `#FFFFFF`, bo góc toàn bộ `BorderRadius.circular(16)`.
  * Ảnh minh họa món ăn: Chiếm chiều cao `110 - 130dp`, bo tròn 2 góc trên `BorderRadius.vertical(top: Radius.circular(16))`.
  * Nút "Trái tim yêu thích" (Favorite Heart): Nằm ở góc trên bên phải ảnh, nền trắng tròn `#FFFFFF` đục 90%, icon tim `#FF7A45`.
  * Thân thẻ (Card Body): Padding `12dp`. Tiêu đề món ăn tối đa 2 dòng (`13sp`, `FontWeight.w700`), thời gian nấu (`11sp`, `#71717A`), kèm theo hàng chip nhỏ (Độ khó, Tag calo).

#### C. Nutrition Summary Card (Thẻ tổng hợp dinh dưỡng)
* **Cấu trúc:**
  * Nền trắng `#FFFFFF`, bo góc `20dp`, padding `16dp`.
  * Đổ bóng `BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))`.
  * Không dùng các đường viền đen đậm ngăn cách, dùng `Divider` màu `#F0F0F4` hoặc khoảng trắng 16dp để chia nhóm calo - carb - protein - chất béo.

---

### 4.3. Huy Hiệu & Thẻ Lọc (Chips & Badges)

* **Status Badge (Hạn sử dụng):**
  * Dạng viên thuốc: `BorderRadius.circular(999)`.
  * Padding: `EdgeInsets.symmetric(horizontal: 10, vertical: 4)`.
  * Chữ: `11sp`, `FontWeight.w700`.
  * Có biểu tượng chấm tròn nhỏ (Dot indicator) hoặc icon nhỏ (3-4dp) trước chữ.
* **Filter Chips (Lọc món ăn, danh mục tủ lạnh):**
  * **Trạng thái chưa chọn:** Nền `#F4F4F7`, chữ `#71717A`, không viền.
  * **Trạng thái đã chọn (Active):** Nền `#FF7A45` chữ `#FFFFFF` (hoặc Nền `#FFF2EA` viền `#FF7A45` chữ `#FF7A45`).
  * Chiều cao chuẩn: `34 - 36dp`.

---

### 4.4. Thanh Điều Hướng (Navigation & App Shell)

* **Top App Bar:**
  * Nền trắng `#FFFFFF` hoặc trong suốt tệp với nền Scaffold (`#F8F9FA`).
  * Không đổ bóng cứng (`elevation: 0`).
  * Tiêu đề to rõ, mềm mại (`20sp`, `FontWeight.w700`), icon hành động (chuông thông báo, quét mã barcode) màu `#1C1C1E` với vùng chạm `44x44dp`.
* **Bottom Navigation Bar:**
  * Nền `#FFFFFF`, bo cong nhẹ góc trên `BorderRadius.vertical(top: Radius.circular(20))`.
  * Đổ bóng hắt lên trên nhẹ: `BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4))`.
  * Chiều cao: `65dp` + `MediaQuery.paddingOf(context).bottom` (Safe Area).
  * Mục đang chọn: Icon màu `#FF7A45`, có nền viên thuốc nhẹ `#FFF2EA` bao bọc icon (`NavigationBarTheme` của Material 3).

---

## 5. HỆ THỐNG KHOẢNG CÁCH & ĐỔ BÓNG (SPACING & ELEVATION)

### 5.1. Thước Đo 8-Point Grid Chuẩn Mobile

```
[4dp]  -- xs  : Khoảng cách giữa icon và chữ nhỏ, khoảng cách dot trạng thái.
[8dp]  -- sm  : Khoảng cách giữa các chip liền kề, padding nội bộ badge.
[12dp] -- md  : Khoảng cách giữa các dòng thông tin trong card.
[16dp] -- lg  : Khoảng cách đệm chuẩn (Screen edge padding, Card inner padding).
[20dp] -- xl  : Khoảng cách giữa các Card lớn, khoảng cách tiêu đề section.
[24dp] -- xxl : Khoảng cách giữa các khối chức năng chính trên màn hình.
[32dp] -- 3xl : Khoảng cách đầu trang (Header margin), đáy trang trước nút bấm.
```

### 5.2. Hệ Thống Bo Góc (Corner Radius)

```
Radius.xs   =  6.0dp   (Dành cho indicator nhỏ, tooltip mini)
Radius.sm   =  8.0dp   (Huy hiệu badge, tag nhỏ)
Radius.md   = 12.0dp   (Inner containers, ảnh thu nhỏ con)
Radius.lg   = 16.0dp   (Form Input fields, Nút bấm tiêu chuẩn)
Radius.xl   = 20.0dp   (Card chính, Dialog, Banner thông báo)
Radius.2xl  = 28.0dp   (Modal BottomSheet vuốt lên)
Radius.pill = 999.0dp  (Filter Chip, Search Bar, Primary Pill Button)
```

### 5.3. Hệ Thống Đổ Bóng Môi Trường (Soft Ambient Shadows)

Thay vì dùng gradient hay đổ bóng đen nặng nề, sử dụng độ tán xạ lớn (high blur), độ lệch nhỏ (low offset) và độ mờ cực thấp:

```dart
// Bóng siêu nhẹ cho Card thường
static const List<BoxShadow> cardShadow = [
  BoxShadow(
    color: Color(0x08000000), // Độ mờ 3% đen
    blurRadius: 14,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];

// Bóng ấm áp cho Nút Primary hoặc Thẻ đang chọn (Floating Accent Shadow)
static const List<BoxShadow> primaryButtonShadow = [
  BoxShadow(
    color: Color(0x2EFF7A45), // Độ mờ 18% cam nhận diện
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  ),
];

// Bóng cho Modal BottomSheet / Floating Bar
static const List<BoxShadow> modalShadow = [
  BoxShadow(
    color: Color(0x12000000), // Độ mờ 7%
    blurRadius: 24,
    offset: Offset(0, -6),
    spreadRadius: 0,
  ),
];
```

---

## 6. HỆ THỐNG TYPOGRAPHY (CHỮ VIẾT TRÊN FLUTTER)

Khuyến nghị sử dụng bộ font **Nunito** (hoặc **Plus Jakarta Sans**) từ Google Fonts để tạo nét bo tròn thân thiện, hiện đại, hỗ trợ tiếng Việt hoàn hảo.

| Kiểu chữ Flutter | Size (sp) | Trọng lượng (Weight) | Chiều cao dòng (Height) | Ứng dụng |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 28 | `FontWeight.w800` | 1.25 | Tiêu đề Onboarding, Chào buổi sáng trang chủ |
| `headlineMedium` | 22 | `FontWeight.w700` | 1.30 | Tiêu đề màn hình chính (Kho thực phẩm, Công thức) |
| `titleLarge` | 18 | `FontWeight.w700` | 1.35 | Tiêu đề nhóm (Ngăn mát, Bữa trưa, Dinh dưỡng tuần) |
| `titleMedium` | 15 | `FontWeight.w600` | 1.40 | Tên thực phẩm, tên món ăn trên Card |
| `bodyLarge` | 15 | `FontWeight.w400` | 1.50 | Mô tả công thức, văn bản hướng dẫn chi tiết |
| `bodyMedium` | 13 | `FontWeight.w400` | 1.45 | Mô tả phụ, vị trí tủ, định lượng nguyên liệu |
| `labelLarge` | 14 | `FontWeight.w700` | 1.20 | Chữ trên nút bấm (Buttons), Tab Bar |
| `labelSmall` | 11 | `FontWeight.w700` | 1.20 | Nhãn Huy hiệu (Badges), Trạng thái hết hạn, Tag calo |

> **Lưu ý khả năng tiếp cận (Accessibility):** Luôn dùng `MediaQuery.textScalerOf(context)` hoặc cho phép chữ co giãn tự nhiên, không cố định cứng chiều cao vùng chứa (`height`) chứa văn bản để tránh lỗi vỡ layout khi người dùng tăng cỡ chữ hệ điều hành.

---

## 7. MÃ NGUỒN KHỞI TẠO FLUTTER THEME ĐỒNG BỘ

Dưới đây là các đoạn mã nguồn hoàn chỉnh sẵn sàng để bạn tích hợp và đồng bộ vào thư mục `lib/constants/` của dự án `smart-kitchen-mobile` khi bước vào giai đoạn refactor:

### 7.1. Cấu hình Màu sắc Mới (`lib/constants/app_colors.dart`)

```dart
import 'package:flutter/material.dart';

/// Bảng màu chuẩn hóa Smart Kitchen — 100% Solid Color, No Gradient.
/// Bám sát mockups với điểm nhấn Cam tươi mới và phong cách Soft Modern.
abstract class AppColors {
  // Brand Primary (Cam tươi mới)
  static const Color primary = Color(0xFFFF7A45);
  static const Color primaryDark = Color(0xFFE65A20);
  static const Color primaryContainer = Color(0xFFFFF2EA);
  static const Color primaryLight = Color(0xFFFFE4D6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF9A3412);

  // Background & Surface
  static const Color background = Color(0xFFF8F9FA); // Sáng, ấm, thoáng đãng
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF4F4F7);
  static const Color surfaceWarm = Color(0xFFFFFBF8);

  // Borders & Dividers
  static const Color border = Color(0xFFEBEBEF); // Viền hairline siêu mảnh
  static const Color borderFocused = Color(0xFFFF7A45);

  // Typography
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFFA1A1AA);

  // Semantic Status (Trạng thái hạn dùng & hệ thống)
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFEAF7EE);
  static const Color onSuccessContainer = Color(0xFF15803D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF7EA);
  static const Color onWarningContainer = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFDECEC);
  static const Color onErrorContainer = Color(0xFFB91C1C);

  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFEFF6FF);

  // Nutrition Compliance (Theo widget dinh dưỡng)
  static const Color nutritionExcellent = Color(0xFF2E7D32);
  static const Color nutritionGood = Color(0xFF1565C0);
  static const Color nutritionNeeds = Color(0xFFD97706);
  static const Color nutritionPoor = Color(0xFFC62828);

  // Soft Ambient Shadows
  static const Color shadowColor = Color(0x08000000);
  static const Color primaryShadowColor = Color(0x2EFF7A45);
}
```

### 7.2. Cấu hình Theme Toàn Ứng Dụng (`lib/constants/app_theme.dart`)

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';

abstract class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      
      // Card Theme bo tròn mềm mại, không viền đen thô
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),

      // Input Decoration Theme hiện đại, rộng rãi, không thô cứng
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // Elevated Button Theme (Solid Cam, No Gradient)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Navigation Bar Material 3
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
```

---

## 8. CHECKLIST NGHIỆM THU THIẾT KẾ (DESIGN REVIEW CHECKLIST)

Khi tiến hành cập nhật từng màn hình, hãy kiểm tra danh sách sau để đảm bảo tuân thủ thiết kế:

- [ ] **Không sử dụng Gradient:** Toàn bộ button, header, card, badge đều sử dụng Solid Color.
- [ ] **Đúng mã màu Cam chủ đạo:** Sử dụng `#FF7A45` cho Action chính và `#FFF2EA` cho nền phụ.
- [ ] **Màu nền ứng dụng:** Nền toàn màn hình là `#F8F9FA` (thoáng mát, không dùng màu xám xịt `#f2f2f5`).
- [ ] **Bo góc nhất quán:** Card có bo góc tối thiểu `16dp`, Input fields bo `16dp`, Chips/Badges bo viên thuốc `999dp`.
- [ ] **Touch Target:** Tất cả icon bấm được, checkbox, nút bấm đều đạt kích thước tối thiểu `48 x 48dp`.
- [ ] **Trạng thái hết hạn trực quan:** Dùng cặp màu chữ đậm + nền container pastel cho các trạng thái Tươi (Xanh), Sắp hết hạn (Vàng/Cam), Hết hạn (Đỏ).
- [ ] **Không viền dày:** Không sử dụng `border` đen hoặc xám dày > 1.0dp; ưu tiên bóng ambient nhẹ hoặc hairline `#EBEBEF`.
- [ ] **Khoảng cách thoáng đãng:** Giữ khoảng cách tối thiểu `16dp` từ mép màn hình và `12 - 16dp` giữa các thành phần liền kề.

---
*Tài liệu này là nguồn sự thật duy nhất (Single Source of Truth) phục vụ việc tái thiết kế giao diện cho toàn bộ dự án `smart-kitchen-mobile`.*


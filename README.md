# SmartCheck HHC – app chấm công (Hoàng Hùng Cường)

Bài kiểm tra Lập trình di động, Đề 2: app chấm công nhân viên. App Flutter này **dùng chung backend đã deploy**
(xem `../API.md`), giao diện và mã nguồn viết riêng.

- Backend: `https://vupham309-001-site1.etempurl.com` (Swagger: `/swagger`). Đổi bằng
  `--dart-define=BASE_URL=https://...`.
- Application ID: `com.hoanghungcuong.smartcheck`. Tối thiểu Android 7.0 (API 24).
- Host miễn phí "ngủ" khi nhàn rỗi nên **request đầu có thể chậm 10–30 giây** (timeout đặt 45 giây).

## Chạy

```bash
flutter pub get
flutter run                      # máy thật hoặc máy ảo Android
flutter test                     # 16 test
flutter build apk --release
```

Camera, GPS và quét QR cần **máy thật** (hoặc máy ảo có camera/GPS giả lập).

## Chức năng

| Mục đề | Nội dung |
|---|---|
| Đăng ký | Email + mật khẩu + họ tên, server gửi mã 6 số về email, nhập đúng mới vào app. Quên mật khẩu: nhận mã qua email rồi đặt mật khẩu mới. |
| Đăng nhập 2 lớp | Email + mật khẩu, sau đó **Email OTP** 6 số (sống 5 phút, đếm ngược, gửi lại sau 30 giây). |
| Phân quyền | Admin → trang quản trị (Drawer + lưới chức năng); Manager → các tab QR / chấm công / duyệt phép / bảng công / cảnh báo; Employee → thanh điều hướng dưới (Hôm nay, Lịch sử, Nghỉ phép, Cá nhân). Server kiểm tra quyền bằng JWT, không chỉ ẩn nút. |
| CRUD | Nhân viên (tìm kiếm, phân trang, khoá/mở, gỡ ràng buộc máy), phòng ban, ca làm việc, địa điểm (chọn toạ độ trên bản đồ + bán kính), đơn nghỉ phép (tạo/sửa/huỷ + duyệt), cảnh báo gian lận (xem/xử lý/xoá), chấm công (vào/ra, lịch sử, bảng công tháng). |
| (e) Quét QR | Manager/Admin mở màn mã QR của một địa điểm, mã tự đổi mỗi 30 giây. Nhân viên quét bằng camera (ML Kit Barcode) và gửi nguyên chuỗi lên server. |
| (b) Vị trí | GPS (geolocator) + bản đồ OpenStreetMap với vòng bán kính, hiện khoảng cách trước khi gửi; Admin/Manager xem bản đồ nơi mỗi người đã chấm công. |
| (a) Khuôn mặt | Camera trước + ML Kit Face Detection chạy trên máy: thử thách ngẫu nhiên 2 trong 3 động tác **mỉm cười / nghiêng đầu / ngẩng đầu**. Đây là xác thực "người thật" (liveness), **chưa nhận dạng ai** (không có vector khuôn mặt). |

Chống gian lận do server quyết định; app gửi đủ dữ liệu: cờ vị trí giả lập, độ chính xác GPS, mã máy cố định
(sinh một lần, lưu trong kho bảo mật, không đổi khi đăng xuất), kết quả khuôn mặt.

## Cấu trúc

```
lib/
  main.dart               khởi động, giữ phiên, về màn đăng nhập khi token hết hạn
  app/theme.dart          màu (xanh chàm + vàng hổ phách) và theme Material 3
  core/                   api.dart (địa chỉ, lỗi), session.dart, format.dart, liveness.dart (thuật toán khuôn mặt)
  models/                 dữ liệu trả về từ API
  services/               mỗi nhóm API một file (api_client.dart là bộ gọi HTTP chung)
  widgets/                widget dùng chung, khung đăng nhập, bản đồ, camera
  screens/                các màn hình
test/                     liveness, parse dữ liệu, màn đăng nhập
```

## Chưa làm / hạn chế

- **Chưa có đăng nhập Google** (đề yêu cầu "đăng ký/đăng nhập bằng bên thứ ba"): backend kiểm tra `idToken` theo
  OAuth client của dự án gốc, cần chủ dự án đăng ký thêm mã SHA-1 và package `com.hoanghungcuong.smartcheck`
  mới dùng được. Hiện chỉ có đăng ký bằng email.
- Chưa có SMS OTP (chỉ Email OTP). Chưa nhận dạng/so khớp khuôn mặt. Chưa chia sẻ vị trí theo thời gian thực.
- Chưa xuất bảng công ra Excel/PDF. Chưa cấu hình iOS (thư mục `ios/` chưa được tạo).
- Quét QR, xác thực khuôn mặt và chấm công thật chưa được chạy trên điện thoại thật khi viết code này; phần đã
  kiểm tra tự động là phân tích tĩnh, test thuật toán/dữ liệu và việc build.
- Quản lý có thể xem QR/bảng công nhưng tài khoản mới đăng ký luôn là Employee: muốn thử Manager/Admin cần
  chủ dự án nâng quyền.

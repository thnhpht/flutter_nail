# Tính năng Hóa đơn Thanh toán

## Tổng quan

Tính năng hóa đơn thanh toán cho phép tạo và quản lý hóa đơn tự động khi tạo đơn hàng mới. Hóa đơn được thiết kế đẹp mắt và chuyên nghiệp với đầy đủ thông tin cần thiết.

## Các tính năng chính

### 1. Tạo hóa đơn tự động

- Khi tạo đơn hàng thành công, hệ thống sẽ tự động hiển thị hóa đơn
- Hóa đơn chứa đầy đủ thông tin:
  - Thông tin salon
  - Mã hóa đơn và ngày tạo
  - Thông tin khách hàng
  - Thông tin nhân viên phục vụ
  - Chi tiết các dịch vụ đã sử dụng
  - Tổng tiền thanh toán

### 2. Quản lý hóa đơn

- Màn hình quản lý hóa đơn cho phép:
  - Xem danh sách tất cả hóa đơn đã tạo
  - Tìm kiếm hóa đơn theo tên khách hàng, số điện thoại, nhân viên
  - Thống kê tổng số hóa đơn và doanh thu
  - Xem lại hóa đơn bất kỳ lúc nào

### 3. Thiết kế hóa đơn

- Giao diện đẹp mắt với gradient màu sắc
- Layout chuyên nghiệp và dễ đọc
- Responsive design cho các kích thước màn hình khác nhau
- Thông tin được sắp xếp logic và rõ ràng

### 4. Các tính năng bổ sung

- **Chia sẻ hóa đơn**: Gửi hóa đơn qua email, tin nhắn
- **In hóa đơn**: In trực tiếp hoặc xuất PDF
- **Lưu hóa đơn**: Lưu vào thiết bị để xem offline

## Cấu hình Salon

### File cấu hình: `lib/config/salon_config.dart`

### Tùy chỉnh thông tin salon

1. Mở file `lib/config/salon_config.dart`
2. Thay đổi các thông tin cần thiết:
   - Tên salon
   - Địa chỉ
   - Số điện thoại
   - Email, website
   - Tiền tệ
   - Nội dung footer

## Cách sử dụng

### 1. Tạo hóa đơn

1. Vào màn hình "Tạo đơn hàng"
2. Nhập thông tin khách hàng
3. Chọn nhân viên phục vụ
4. Chọn danh mục và dịch vụ
5. Nhấn "Tạo đơn hàng"
6. Hóa đơn sẽ tự động hiển thị

### 2. Quản lý hóa đơn

1. Vào màn hình "Hóa đơn" từ menu chính
2. Xem danh sách hóa đơn
3. Sử dụng thanh tìm kiếm để lọc hóa đơn
4. Nhấn vào hóa đơn để xem chi tiết

### 3. Thao tác với hóa đơn

- **Xem**: Nhấn vào hóa đơn để xem chi tiết
- **Chia sẻ**: Nhấn nút "Chia sẻ" trong hóa đơn
- **In**: Nhấn nút "In" để in hóa đơn
- **Lưu**: Nhấn nút "Lưu" để lưu hóa đơn

## Cấu trúc file

```
lib/
├── screens/
│   ├── order_screen.dart      # Màn hình tạo đơn hàng
│   └── bills_screen.dart      # Màn hình quản lý hóa đơn
├── ui/
│   └── bill_helper.dart       # Helper class cho hóa đơn
├── config/
│   └── salon_config.dart      # Cấu hình thông tin salon
└── models.dart                # Model dữ liệu
```

## Tính năng nâng cao (Đang phát triển)

### 1. Xuất PDF

- Tạo file PDF từ hóa đơn
- Gửi PDF qua email
- Lưu PDF vào thiết bị

### 2. QR Code thanh toán

- Tạo mã QR cho thanh toán online
- Tích hợp với các cổng thanh toán

### 3. Template hóa đơn

- Nhiều mẫu hóa đơn khác nhau
- Tùy chỉnh màu sắc và layout

### 4. Báo cáo doanh thu

- Thống kê doanh thu theo thời gian
- Biểu đồ và báo cáo chi tiết

## Lưu ý kỹ thuật

### 1. Performance

- Hóa đơn được render với RepaintBoundary để tối ưu hiệu suất
- Sử dụng AnimatedSwitcher cho chuyển đổi mượt mà

### 2. Responsive Design

- Hóa đơn tự động điều chỉnh theo kích thước màn hình
- Tối ưu cho cả mobile và tablet

### 3. Data Management

- Dữ liệu hóa đơn được lưu trữ trong database
- Đồng bộ với backend API

## Troubleshooting

### Lỗi thường gặp

1. **Hóa đơn không hiển thị sau khi tạo đơn hàng**

   - Kiểm tra kết nối API
   - Đảm bảo đơn hàng được tạo thành công

2. **Thông tin salon không đúng**

   - Kiểm tra file `salon_config.dart`
   - Cập nhật thông tin cần thiết

3. **Hóa đơn hiển thị sai định dạng**
   - Kiểm tra cấu hình currency
   - Đảm bảo dữ liệu dịch vụ đầy đủ

## Hỗ trợ

Nếu gặp vấn đề với tính năng hóa đơn, vui lòng:

1. Kiểm tra log lỗi
2. Xác nhận cấu hình đúng
3. Liên hệ team phát triển

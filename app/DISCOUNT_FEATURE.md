# Tính năng Giảm giá (Discount)

## Tổng quan

Tính năng giảm giá cho phép người dùng áp dụng phần trăm giảm giá cho hóa đơn khi tạo đơn hàng mới. Tính năng này giúp tăng tính linh hoạt trong việc quản lý giá cả và khuyến mãi.

## Các tính năng chính

### 1. Nhập giảm giá

- Trường nhập giảm giá xuất hiện khi đã chọn ít nhất một dịch vụ
- Cho phép nhập phần trăm giảm giá từ 0% đến 100%
- Mặc định là 0% (không giảm giá)
- Hiển thị số tiền tiết kiệm ngay lập tức khi nhập

### 2. Tính toán tự động

- Tổng tiền gốc: Tổng giá trị các dịch vụ đã chọn
- Số tiền giảm: Tổng tiền gốc × Phần trăm giảm giá
- Tổng tiền thanh toán: Tổng tiền gốc - Số tiền giảm

### 3. Hiển thị trong hóa đơn

- Hóa đơn hiển thị đầy đủ thông tin:
  - Tổng tiền gốc
  - Phần trăm giảm giá (nếu có)
  - Số tiền giảm (nếu có)
  - Tổng tiền thanh toán

### 4. Quản lý hóa đơn

- Danh sách hóa đơn hiển thị thông tin giảm giá
- Thống kê doanh thu tính theo tổng tiền thanh toán thực tế

## Cách sử dụng

### 1. Tạo đơn hàng với giảm giá

1. Vào màn hình "Tạo đơn mới"
2. Nhập thông tin khách hàng và nhân viên
3. Chọn danh mục và dịch vụ
4. Trong phần "Dịch vụ", sẽ xuất hiện trường "Giảm giá"
5. Nhập phần trăm giảm giá (ví dụ: 10, 25, 50)
6. Hệ thống tự động tính toán và hiển thị:
   - Số tiền tiết kiệm
   - Tổng tiền gốc
   - Tổng tiền thanh toán
7. Nhấn "Tạo đơn" để hoàn tất

### 2. Xem hóa đơn với giảm giá

1. Sau khi tạo đơn, hóa đơn sẽ hiển thị với thông tin giảm giá
2. Vào màn hình "Hóa đơn" để xem lại
3. Hóa đơn hiển thị chi tiết:
   - Tổng tiền gốc
   - Giảm giá (nếu có)
   - Tổng tiền thanh toán

## Giao diện

### Trường nhập giảm giá

- Vị trí: Trong phần "Dịch vụ", sau danh sách dịch vụ đã chọn
- Thiết kế: Container với icon giảm giá và input field
- Validation: Chỉ cho phép số từ 0-100
- Hiển thị: Chỉ xuất hiện khi có dịch vụ được chọn

### Hiển thị tổng tiền

- Tổng tiền gốc: Giá trị ban đầu
- Giảm giá: Hiển thị phần trăm và số tiền (nếu có)
- Tổng tiền thanh toán: Giá trị cuối cùng

### Hóa đơn

- Layout: Column layout với thông tin chi tiết
- Màu sắc: Gradient xanh dương
- Typography: Font size khác nhau cho từng loại thông tin

## Lưu ý kỹ thuật

### 1. Database

- Thêm trường `DiscountPercent` vào bảng `Order`
- Kiểu dữ liệu: `double` với giá trị mặc định 0.0
- Migration: `AddDiscountPercentToOrder`

### 2. Model

- Cập nhật model `Order` trong Flutter
- Thêm trường `discountPercent` với giá trị mặc định 0.0
- Cập nhật serialization/deserialization

### 3. UI/UX

- Validation real-time cho trường giảm giá
- Auto-format số tiền tiết kiệm
- Responsive design cho các kích thước màn hình

### 4. Tính toán

- Tổng tiền gốc: `sum(service.price)`
- Số tiền giảm: `totalPrice * discountPercent / 100`
- Tổng tiền thanh toán: `totalPrice * (1 - discountPercent / 100)`

## Ví dụ sử dụng

### Ví dụ 1: Giảm giá 10%

- Dịch vụ: Nail art (200,000 VNĐ) + Gel polish (150,000 VNĐ)
- Tổng tiền gốc: 350,000 VNĐ
- Giảm giá: 10%
- Số tiền giảm: 35,000 VNĐ
- Tổng tiền thanh toán: 315,000 VNĐ

### Ví dụ 2: Giảm giá 50%

- Dịch vụ: Full set (500,000 VNĐ)
- Tổng tiền gốc: 500,000 VNĐ
- Giảm giá: 50%
- Số tiền giảm: 250,000 VNĐ
- Tổng tiền thanh toán: 250,000 VNĐ

## Troubleshooting

### 1. Lỗi validation

- **Lỗi**: "Giảm giá phải từ 0-100%"
- **Giải pháp**: Kiểm tra lại giá trị nhập vào, đảm bảo từ 0-100

### 2. Không hiển thị trường giảm giá

- **Nguyên nhân**: Chưa chọn dịch vụ nào
- **Giải pháp**: Chọn ít nhất một dịch vụ

### 3. Tính toán sai

- **Nguyên nhân**: Có thể do lỗi logic
- **Giải pháp**: Kiểm tra lại công thức tính toán

## Tính năng tương lai

### 1. Mã giảm giá

- Tạo và quản lý mã giảm giá
- Áp dụng mã giảm giá thay vì nhập phần trăm

### 2. Giảm giá theo khách hàng

- Giảm giá tự động cho khách hàng VIP
- Lịch sử giảm giá của khách hàng

### 3. Báo cáo giảm giá

- Thống kê tổng số tiền giảm giá
- Báo cáo hiệu quả khuyến mãi

### 4. Giảm giá theo thời gian

- Giảm giá theo giờ thấp điểm
- Khuyến mãi theo ngày trong tuần

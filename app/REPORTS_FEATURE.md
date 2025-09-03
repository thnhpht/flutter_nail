# Tính Năng Báo Cáo Doanh Thu

## Tổng Quan

Tính năng báo cáo doanh thu cung cấp một giao diện toàn diện để theo dõi và phân tích hiệu suất kinh doanh của salon nail. Người dùng có thể lọc dữ liệu theo nhiều tiêu chí khác nhau và xem các thống kê chi tiết.

## Các Tính Năng Chính

### 1. Bộ Lọc Thông Minh

- **Tìm kiếm**: Tìm kiếm theo tên khách hàng, số điện thoại, nhân viên hoặc dịch vụ
- **Lọc theo thời gian**: Chọn khoảng thời gian cụ thể để xem báo cáo
- **Lọc theo nhân viên**: Xem báo cáo cho một nhân viên cụ thể hoặc tất cả nhân viên

### 2. Thống Kê Tổng Quan

- **Tổng doanh thu**: Hiển thị tổng doanh thu trong khoảng thời gian đã chọn
- **Số lượng đơn hàng**: Tổng số đơn hàng đã thực hiện
- **Giá trị trung bình/đơn**: Doanh thu trung bình trên mỗi đơn hàng
- **Số lượng nhân viên**: Số nhân viên tham gia (1 nếu đã lọc theo nhân viên cụ thể)

### 3. Biểu Đồ Doanh Thu Theo Nhân Viên

- Hiển thị top 5 nhân viên có doanh thu cao nhất
- Thông tin chi tiết:
  - Tên nhân viên
  - Số lượng đơn hàng đã thực hiện
  - Tổng doanh thu
  - Phần trăm đóng góp vào tổng doanh thu

### 4. Danh Sách Đơn Hàng Chi Tiết

- Hiển thị tất cả đơn hàng phù hợp với bộ lọc
- Thông tin đầy đủ cho mỗi đơn hàng:
  - Thông tin khách hàng (tên, số điện thoại)
  - Danh sách nhân viên thực hiện
  - Danh sách dịch vụ đã sử dụng
  - Tổng tiền và thời gian tạo đơn
  - Thông tin giảm giá (nếu có)

## Cách Sử Dụng

### Truy Cập Màn Hình Báo Cáo

1. Mở ứng dụng Nail Manager
2. Từ màn hình chính, nhấn vào card "Báo cáo" với biểu tượng analytics
3. Màn hình báo cáo sẽ hiển thị với dữ liệu mặc định (30 ngày gần nhất)

### Sử Dụng Bộ Lọc

1. **Tìm kiếm**: Nhập từ khóa vào ô tìm kiếm để lọc đơn hàng
2. **Chọn khoảng thời gian**:
   - Nhấn vào nút "Chọn khoảng thời gian"
   - Chọn ngày bắt đầu và kết thúc
   - Nhấn "OK" để áp dụng
3. **Chọn nhân viên**:
   - Chọn từ dropdown "Chọn nhân viên"
   - Chọn "Tất cả nhân viên" để xem báo cáo tổng hợp

### Xem Thống Kê

- Các thẻ thống kê sẽ tự động cập nhật khi thay đổi bộ lọc
- Biểu đồ nhân viên chỉ hiển thị khi có dữ liệu doanh thu
- Danh sách đơn hàng được sắp xếp theo thời gian mới nhất

### Làm Mới Dữ Liệu

- Nhấn vào biểu tượng refresh ở góc trên bên phải để tải lại dữ liệu mới nhất

## Tính Năng Kỹ Thuật

### Hiệu Suất

- Dữ liệu được lọc và tính toán trên client-side để đảm bảo tốc độ
- Chỉ tải dữ liệu cần thiết từ server
- Caching thông minh để giảm số lượng API calls

### Tính Chính Xác

- Doanh thu được chia đều khi một đơn hàng có nhiều nhân viên thực hiện
- Tính toán phần trăm dựa trên tổng doanh thu thực tế
- Xử lý các trường hợp đặc biệt (giảm giá, đơn hàng trống)

### Giao Diện

- Thiết kế responsive và thân thiện với người dùng
- Sử dụng design system nhất quán với các màn hình khác
- Hiển thị loading state khi đang tải dữ liệu
- Thông báo lỗi rõ ràng khi có vấn đề

## Cấu Trúc Code

### Files Chính

- `lib/screens/reports_screen.dart`: Màn hình báo cáo chính
- `lib/main.dart`: Thêm navigation đến màn hình báo cáo

### Models Sử Dụng

- `Order`: Dữ liệu đơn hàng
- `Employee`: Dữ liệu nhân viên

### Dependencies

- `intl`: Định dạng tiền tệ và ngày tháng
- `flutter/material.dart`: UI components

## Tương Lai

### Tính Năng Dự Kiến

- Export báo cáo ra PDF/Excel
- Biểu đồ tròn cho phân bố doanh thu
- So sánh doanh thu theo tháng/quý/năm
- Thống kê dịch vụ bán chạy nhất
- Dashboard với các KPI quan trọng

### Cải Tiến

- Thêm biểu đồ đường cho xu hướng doanh thu
- Filter theo danh mục dịch vụ
- Thống kê khách hàng VIP
- Báo cáo theo ca làm việc

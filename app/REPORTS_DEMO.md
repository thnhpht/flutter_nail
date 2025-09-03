# Demo Giao Diện Báo Cáo Doanh Thu

## Màn Hình Chính

```
┌─────────────────────────────────────────────────────────────┐
│                    Báo Cáo Doanh Thu                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Bộ Lọc                                                  │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 🔍 Tìm kiếm...                                      │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 📅 01/12/2024 - 31/12/2024                    [×]  │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 👤 Chọn nhân viên: Tất cả nhân viên ▼              │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────┐ │
│  │ 💰          │  │ 📄          │  │ 📊          │  │ 👥  │ │
│  │ Tổng Doanh  │  │ Số Đơn      │  │ Giá Trị TB  │  │ Nhân│ │
│  │ Thu         │  │ Hàng        │  │ /Đơn        │  │ Viên│ │
│  │ 15,500,000₫ │  │ 45          │  │ 344,444₫    │  │ 5   │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Doanh Thu Theo Nhân Viên                                │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 👤 Nguyễn Thị A    │ 5 đơn hàng │ 4,500,000₫ │ 29% │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 👤 Trần Văn B      │ 8 đơn hàng │ 3,800,000₫ │ 25% │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 👤 Lê Thị C        │ 6 đơn hàng │ 2,900,000₫ │ 19% │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 📋 Danh Sách Đơn Hàng                                   │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Nguyễn Văn Khách   0123456789                       │ │
│  │ │ 👤 Nhân viên: Nguyễn Thị A                          │ │
│  │ │ 💅 Dịch vụ: Sơn gel, Đắp bột                        │ │
│  │ │ 💰 350,000₫                    📅 25/12/2024 14:30 │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ Trần Thị Khách     0987654321                       │ │
│  │ │ 👤 Nhân viên: Trần Văn B                            │ │
│  │ │ 💅 Dịch vụ: Massage chân, Đắp bột                   │ │
│  │ │ 💰 450,000₫                    📅 25/12/2024 15:45 │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Các Tính Năng Chính

### 1. Bộ Lọc Thông Minh

- **Tìm kiếm**: Tìm theo tên khách hàng, số điện thoại, nhân viên, dịch vụ
- **Lọc thời gian**: Chọn khoảng thời gian cụ thể
- **Lọc nhân viên**: Xem báo cáo cho nhân viên cụ thể hoặc tất cả

### 2. Thống Kê Tổng Quan

- **Tổng doanh thu**: Hiển thị tổng tiền trong khoảng thời gian
- **Số đơn hàng**: Tổng số đơn đã thực hiện
- **Giá trị TB/đơn**: Doanh thu trung bình mỗi đơn
- **Số nhân viên**: Số lượng nhân viên tham gia

### 3. Biểu Đồ Nhân Viên

- Top 5 nhân viên có doanh thu cao nhất
- Hiển thị: tên, số đơn hàng, doanh thu, phần trăm
- Sắp xếp theo doanh thu giảm dần

### 4. Danh Sách Chi Tiết

- Thông tin đầy đủ mỗi đơn hàng
- Sắp xếp theo thời gian mới nhất
- Hiển thị giảm giá nếu có

## Màu Sắc và Thiết Kế

### Màu Chủ Đạo

- **Primary**: Gradient từ #667eea đến #764ba2
- **Success**: #4CAF50 (doanh thu)
- **Info**: #2196F3 (số đơn hàng)
- **Warning**: #FF9800 (giá trị TB)
- **Secondary**: #9C27B0 (nhân viên)

### Typography

- **Heading**: 18px, Bold
- **Body**: 14px, Regular
- **Caption**: 12px, Regular
- **Button**: 16px, Medium

### Spacing

- **XS**: 8px
- **S**: 12px
- **M**: 16px
- **L**: 20px
- **XL**: 24px

## Responsive Design

### Desktop (1200px+)

- 4 thẻ thống kê trên một hàng
- Biểu đồ nhân viên hiển thị đầy đủ
- Danh sách đơn hàng 2 cột

### Tablet (768px - 1199px)

- 2 thẻ thống kê trên một hàng
- Biểu đồ nhân viên thu gọn
- Danh sách đơn hàng 1 cột

### Mobile (< 768px)

- 1 thẻ thống kê trên một hàng
- Biểu đồ nhân viên dạng list
- Danh sách đơn hàng scroll dọc

## Tương Tác Người Dùng

### Gestures

- **Tap**: Chọn bộ lọc, xem chi tiết
- **Swipe**: Cuộn danh sách đơn hàng
- **Long Press**: Xem thông tin chi tiết đơn hàng

### Animations

- **Fade In**: Khi tải dữ liệu
- **Slide Up**: Khi hiển thị bộ lọc
- **Scale**: Khi tap vào thẻ thống kê
- **Loading**: Spinner khi đang tải

### Feedback

- **Success**: Màu xanh khi lọc thành công
- **Error**: Màu đỏ khi có lỗi
- **Warning**: Màu cam khi không có dữ liệu
- **Info**: Màu xanh dương cho thông tin

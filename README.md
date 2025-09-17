# Nail Manager - Hệ thống Quản lý Salon Nail (Flutter + .NET)

## Tổng quan

Nail Manager là một hệ thống quản lý salon nail toàn diện với kiến trúc multi-tenant, cho phép mỗi salon có database riêng biệt. Hệ thống bao gồm backend .NET Web API và frontend Flutter app hỗ trợ đa nền tảng.

## Tính năng chính

### 🎯 Quản lý cốt lõi

- **Khách hàng**: Thêm, sửa, xóa thông tin khách hàng
- **Nhân viên**: Quản lý nhân viên và phân quyền (chủ salon/nhân viên)
- **Danh mục & Dịch vụ**: Tổ chức dịch vụ theo danh mục với hình ảnh
- **Đơn hàng**: Tạo đơn hàng với nhiều dịch vụ và nhân viên

### 💰 Thanh toán & Báo cáo

- **Hóa đơn tự động**: Tạo hóa đơn đẹp mắt khi hoàn thành đơn hàng
- **Giảm giá**: Áp dụng phần trăm giảm giá linh hoạt
- **Báo cáo doanh thu**: Thống kê theo thời gian và nhân viên
- **Dashboard**: Tổng quan doanh thu hàng ngày

### 🏪 Thông tin Salon

- **Cấu hình salon**: Logo, thông tin liên hệ, mạng xã hội
- **QR Code**: Tạo mã QR cho thông tin salon
- **Responsive**: Tối ưu cho mọi kích thước màn hình

## Yêu cầu hệ thống

- **Flutter SDK**: ≥3.3.0 (kiểm tra: `flutter --version`)
- **.NET SDK**: 8.0 (kiểm tra: `dotnet --info`)
- **SQL Server**: Local hoặc Azure SQL Database
- **macOS/Windows/Linux**: Hỗ trợ đa nền tảng

## Cài đặt và Chạy

### Backend (.NET Web API)

```bash
cd backend/NailApi
dotnet restore
dotnet run
dotnet publish -c Release -o ./publish
```

### Frontend (Flutter App)

```bash
cd app
flutter pub get
```

**Chạy trên các nền tảng:**

```bash
# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5088/api

# iOS Simulator
flutter run -d ios --dart-define=API_BASE_URL=http://127.0.0.1:5088/api

# Android Emulator
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5088/api

# Windows
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5088/api

# macOS
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:5088/api
```

## Kiến trúc hệ thống

### Backend API Endpoints

#### Authentication

- `POST /api/auth/check-email` - Kiểm tra email tồn tại
- `POST /api/auth/login` - Đăng nhập hoặc tạo tài khoản mới

#### Business Logic (yêu cầu JWT token)

- `GET/POST/PUT/DELETE /api/customers` - Quản lý khách hàng
- `GET/POST/PUT/DELETE /api/employees` - Quản lý nhân viên
- `GET/POST/PUT/DELETE /api/categories` - Quản lý danh mục
- `GET/POST/PUT/DELETE /api/services` - Quản lý dịch vụ
- `GET/POST/PUT/DELETE /api/orders` - Quản lý đơn hàng
- `GET/POST/PUT /api/information` - Thông tin salon
- `GET /api/dashboard/today-stats` - Thống kê hôm nay

### Database Architecture

#### NailAdmin Database

- Lưu trữ thông tin đăng nhập của tất cả salon
- Bảng `User`: Email, Password (hash+salt), UserLogin, PasswordLogin

#### Dynamic Databases

- Mỗi salon có database riêng với tên = email đăng ký
- Tự động tạo khi đăng ký lần đầu
- Bao gồm: Customers, Employees, Categories, Services, Orders, Information

### Frontend Structure

```
app/
├── lib/
│   ├── screens/           # Các màn hình chính
│   │   ├── login_screen.dart
│   │   ├── customers_screen.dart
│   │   ├── employees_screen.dart
│   │   ├── categories_screen.dart
│   │   ├── services_screen.dart
│   │   ├── order_screen.dart
│   │   ├── bills_screen.dart
│   │   ├── reports_screen.dart
│   │   └── salon_info_screen.dart
│   ├── ui/                # UI components
│   ├── config/            # Cấu hình
│   ├── models.dart        # Data models
│   └── api_client.dart    # API integration
└── assets/               # Icons, fonts, images
```

## Tính năng nâng cao

### JWT Authentication

- Token-based authentication với thời hạn 120 phút
- Tự động refresh khi cần thiết
- Bảo mật với SHA256 hash + salt

### Multi-tenant Architecture

- Mỗi salon có database riêng biệt
- Tự động tạo SQL Server login và user
- Cấp quyền `db_owner` cho user salon

### Cross-platform Support

- **Mobile**: iOS, Android
- **Desktop**: Windows, macOS, Linux
- **Web**: Chrome, Firefox, Safari, Edge

## Tài liệu chi tiết

- [LOGIN_FEATURE_README.md](LOGIN_FEATURE_README.md) - Tính năng đăng nhập và JWT
- [app/BILL_FEATURES.md](app/BILL_FEATURES.md) - Hệ thống hóa đơn
- [app/REPORTS_FEATURE.md](app/REPORTS_FEATURE.md) - Báo cáo doanh thu
- [app/DISCOUNT_FEATURE.md](app/DISCOUNT_FEATURE.md) - Tính năng giảm giá
- [KEYBOARD_OVERLAY_SOLUTION.md](KEYBOARD_OVERLAY_SOLUTION.md) - Xử lý bàn phím

## Troubleshooting

### Lỗi thường gặp

1. **Backend không khởi động**

   - Kiểm tra SQL Server đang chạy
   - Xem connection string trong `appsettings.json`
   - Chạy `dotnet ef database update`

2. **Flutter app không kết nối API**

   - Kiểm tra `API_BASE_URL` đúng với platform
   - iOS Simulator: dùng `127.0.0.1`
   - Android Emulator: dùng `10.0.2.2`
   - Thiết bị thật: dùng IP máy tính trong cùng mạng

3. **Lỗi đăng nhập**
   - Kiểm tra database `NailAdmin` tồn tại
   - Xem log backend console
   - Thử các debug endpoints trong `AuthController`

### Debug Tools

- **Backend logs**: Console output khi chạy `dotnet run`
- **Flutter debug**: `flutter run` với log chi tiết
- **API testing**: Swagger UI tại `/swagger`
- **Database**: SQL Server Management Studio

## Licens

Dự án này được phát triển cho mục đích quản lý salon nail chuyên nghiệp.

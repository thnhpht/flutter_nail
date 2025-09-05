# Tính năng Login và Tạo Database Động (Phiên bản JWT)

## Tổng quan

Tính năng này cho phép người dùng đăng nhập vào hệ thống với khả năng tạo database động dựa trên email. Khi người dùng đăng nhập lần đầu, hệ thống sẽ tự động tạo một database mới với tên là đầy đủ email (thay vì chỉ phần trước @ như phiên bản cũ).

## Các thay đổi chính so với phiên bản cũ

### 1. **JWT Authentication**

- ✅ Thay thế GUID token bằng JWT token
- ✅ Sử dụng `System.IdentityModel.Tokens.Jwt` package
- ✅ Token chứa thông tin email và userLogin
- ✅ Tất cả API calls đều sử dụng JWT Bearer token

### 2. **Flushbar thay vì SnackBar**

- ✅ Sử dụng `another_flushbar` package thay vì SnackBar
- ✅ Giao diện thông báo đẹp hơn và nhất quán với các màn hình khác
- ✅ Hiển thị icon và title phù hợp với từng loại thông báo
- ✅ Sử dụng hàm `showFlushbar` nhất quán với các giao diện khác

### 3. **Tên Database đầy đủ email**

- ✅ Thay vì `salon@example.com` → database `salon`
- ✅ Bây giờ `salon@example.com` → database `salon_example_com`
- ✅ Thay thế `@` và `.` bằng `_` để tạo tên database hợp lệ

### 4. **Tạo User có quyền đăng nhập Database**

- ✅ Khi tạo tài khoản mới, hệ thống tự động tạo SQL Server login
- ✅ Tạo user trong database mới với quyền `db_owner`
- ✅ User có thể đăng nhập trực tiếp vào database của mình

### 6. **Mã hóa mật khẩu bảo mật**

- ✅ Sử dụng SHA256 hash với salt ngẫu nhiên 16 bytes
- ✅ Mã hóa cả password đăng nhập và password database
- ✅ Bảo mật cao, không thể reverse engineer password

### 5. **Nút thay đổi theo trạng thái**

- ✅ Bước 1 (Email): "Kết nối"
- ✅ Bước 2A (Đăng nhập): "Đăng nhập"
- ✅ Bước 2B (Tạo tài khoản): "Đăng ký"

### 7. **Giao diện gọn gàng**

- ✅ Xóa phần hiển thị "Database: email" để giao diện đẹp hơn
- ✅ Tập trung vào các thông tin cần thiết cho người dùng

### 8. **Thông báo lỗi thân thiện**

- ✅ Thay thế lỗi API kỹ thuật bằng thông báo dễ hiểu
- ✅ Phân loại lỗi rõ ràng: validation, authentication, network
- ✅ Hướng dẫn cụ thể cho người dùng khi gặp lỗi

## Kiến trúc Database

### 1. Database NailAdmin

- **Mục đích**: Lưu trữ thông tin đăng nhập của tất cả User
- **Bảng**: `User` với các field:
  - `Email` (Primary Key)
  - `Password`
  - `UserLogin` (tên đăng nhập database)
  - `PasswordLogin` (mật khẩu database)
  - `CreatedAt`

### 2. Database Động

- **Tên**: Đầy đủ email (thay thế @ và . bằng \_)
- **Ví dụ**: `salon@example.com` → database `salon_example_com`
- **Mục đích**: Lưu trữ dữ liệu business logic riêng biệt cho mỗi user
- **Bảng**: Customers, Employees, Categories, Services, Orders
- **User**: Tự động tạo user với quyền `db_owner`

## Cách hoạt động mới

### 1. Bước 1: Kiểm tra Email

- Người dùng nhập email (ví dụ: `salon@example.com`)
- Nhấn nút "Kết nối"
- Hệ thống kiểm tra trong database `NailAdmin` bảng `User` xem email đã tồn tại chưa

### 2. Bước 2A: Email đã tồn tại (Đăng nhập)

- Hiển thị form nhập mật khẩu và thông tin database
- Người dùng nhập:
  - Mật khẩu
  - Tên đăng nhập database (UserLogin)
  - Mật khẩu database (PasswordLogin)
- Hệ thống kiểm tra thông tin và cho phép đăng nhập
- **Trả về JWT token** thay vì GUID

### 2. Bước 2B: Email chưa tồn tại (Tạo tài khoản mới)

- Hiển thị form tạo tài khoản mới
- Người dùng nhập:
  - Mật khẩu mới
  - Tên đăng nhập database (UserLogin)
  - Mật khẩu database (PasswordLogin)
- Hệ thống lưu thông tin vào bảng `User`
- **Tự động tạo database động** với tên đầy đủ email
- **Tự động tạo SQL Server login** và user với quyền `db_owner`
- **Tự động tạo các bảng** cần thiết trong database mới
- **Trả về JWT token** thay vì GUID

## Cấu trúc Backend

### Models

- `User`: Lưu thông tin người dùng (Email, Password, UserLogin, PasswordLogin)
- `CheckEmailRequest`: Dữ liệu gửi để kiểm tra email
- `CheckEmailResponse`: Kết quả kiểm tra email
- `LoginRequest`: Dữ liệu đăng nhập hoặc tạo tài khoản
- `Customer`, `Employee`, `Category`, `Service`, `Order`: Models cho business logic

### Controllers

- `AuthController`: Xử lý kiểm tra email, đăng nhập và tạo database động
- `CustomersController`: Quản lý khách hàng (sử dụng JWT authentication)
- `EmployeesController`: Quản lý nhân viên (sử dụng JWT authentication)
- `CategoriesController`: Quản lý danh mục (sử dụng JWT authentication)
- `ServicesController`: Quản lý dịch vụ (sử dụng JWT authentication)
- `OrdersController`: Quản lý đơn hàng (sử dụng JWT authentication)

### Services

- `DatabaseService`: Quản lý kết nối database động
- `JwtService`: Tạo và xác thực JWT token
- `PasswordService`: Mã hóa và xác thực mật khẩu bằng hash + salt

### Database Contexts

- `AppDbContext`: Kết nối database NailAdmin (chỉ chứa bảng User)
- `DynamicDbContext`: Kết nối database động (chứa các bảng business logic)

## Cấu trúc Frontend

### Screens

- `LoginScreen`: Màn hình đăng nhập với 3 bước (Email → Password → Database Info)

### API Client

- Phương thức `checkEmail()` để kiểm tra email
- Phương thức `login()` để đăng nhập hoặc tạo tài khoản
- Tất cả các methods business đều gửi JWT token trong Authorization header
- Lưu trữ thông tin đăng nhập bằng `SharedPreferences`

## Cách sử dụng

### 1. Chạy Backend

```bash
cd backend/NailApi
dotnet run
```

### 2. Chạy Flutter App

```bash
cd app
flutter run
```

### 3. Quy trình đăng nhập

#### Bước 1: Kiểm tra Email

- Nhập email (ví dụ: `mysalon@gmail.com`)
- Nhấn "Kết nối"
- Hệ thống kiểm tra email trong database NailAdmin

#### Bước 2A: Đăng nhập (nếu email đã tồn tại)

- Nhập mật khẩu
- Nhập tên đăng nhập database (ví dụ: `sa`)
- Nhập mật khẩu database
- Nhấn "Đăng nhập"
- **Hệ thống trả về JWT token**

#### Bước 2B: Tạo tài khoản (nếu email chưa tồn tại)

- Nhập mật khẩu mới (tối thiểu 6 ký tự)
- Nhập tên đăng nhập database
- Nhập mật khẩu database
- Nhấn "Đăng ký"
- **Hệ thống tự động tạo database `mysalon_gmail_com` và các bảng cần thiết**
- **Tự động tạo SQL Server login và user với quyền `db_owner`**
- **Trả về JWT token**

### 4. Kết quả

- Nếu thành công: Chuyển đến màn hình chính của ứng dụng
- Nếu thất bại: Hiển thị thông báo lỗi bằng Flushbar

## Lưu ý quan trọng

### Bảo mật

- ✅ Sử dụng JWT token thay vì GUID
- ✅ Token có thời hạn (120 phút theo mặc định)
- ✅ Tất cả API calls đều yêu cầu authentication
- ✅ **Mã hóa mật khẩu bằng SHA256 hash + salt ngẫu nhiên**
- ✅ **Mã hóa cả password đăng nhập và password database**
- ✅ Bảo mật cao, không thể reverse engineer password

### Database

- ✅ Đảm bảo database `NailAdmin` tồn tại
- ✅ Bảng `User` được tạo với đúng cấu trúc
- ✅ Kiểm tra connection string trong `appsettings.json`
- ✅ User SQL Server cần có quyền tạo database và user
- ✅ Tự động tạo user với quyền `db_owner` trong database mới

### Flutter

- ✅ Cài đặt `another_flushbar` package
- ✅ Sử dụng JWT token trong tất cả API calls
- ✅ Kiểm tra quyền truy cập storage trên mobile

## Troubleshooting

### Lỗi kiểm tra email

- Kiểm tra API endpoint `/auth/check-email`
- Kiểm tra kết nối database `NailAdmin`
- Xem log trong console

### Lỗi đăng nhập

- Kiểm tra API endpoint `/auth/login`
- Kiểm tra format dữ liệu gửi
- Xem response từ server
- Kiểm tra JWT configuration trong `appsettings.json`
- **Lưu ý**: Password đã được hash, không thể so sánh trực tiếp

### Lỗi tạo database động

- Kiểm tra quyền của user SQL Server
- Kiểm tra connection string master database
- Xem log trong console
- Kiểm tra việc tạo login và user

### Lỗi JWT Authentication

- Kiểm tra JWT key trong `appsettings.json`
- Kiểm tra JWT middleware trong `Program.cs`
- Xem log authentication

### Lỗi Flutter

- Chạy `flutter clean` và `flutter pub get`
- Kiểm tra import statements
- Xem console log

### Debug và Kiểm tra

Để debug các vấn đề, sử dụng các endpoint sau:

1. **Test Hash Function**: `GET /api/auth/test-hash`

   - Kiểm tra việc hash và verify password
   - Trả về thông tin chi tiết về quá trình hash

2. **Debug Users**: `GET /api/auth/debug/users`

   - Xem danh sách users trong database
   - Kiểm tra password hash đã được lưu trữ

3. **Check Database**: `GET /api/auth/debug/check-database/{databaseName}`

   - Kiểm tra database có tồn tại không
   - Xem danh sách các bảng đã được tạo
   - Kiểm tra số lượng bảng

4. **Check Login**: `GET /api/auth/debug/check-login/{loginName}`

   - Kiểm tra login có tồn tại trong SQL Server Security không
   - Xem thông tin chi tiết về login (type, disabled, create date)
   - Xác nhận login đã được tạo đúng cách

5. **Database Status**: `GET /api/auth/debug/database-status`

   - Kiểm tra trạng thái kết nối database chính
   - Xem migrations và connection string

6. **Fix Database Permissions**: `POST /api/auth/debug/fix-permissions/{databaseName}`

   - Sửa quyền cho user trong database cụ thể
   - Cấp đầy đủ quyền tạo, xóa, sửa bảng
   - Thử tạo lại các bảng sau khi sửa quyền

7. **Create Strong Login**: `POST /api/auth/debug/create-strong-login`

   - Tạo login với mật khẩu mạnh để tránh Windows password policy
   - Tự động tạo mật khẩu mạnh từ mật khẩu gốc
   - Cập nhật mật khẩu trong database NailAdmin

8. **Console Logs**: Kiểm tra console của backend để xem log chi tiết
   - Log khi tạo user mới
   - Log khi verify password
   - Log khi đăng nhập
   - Log khi tạo database và bảng
   - Log quyền của user mới
   - Log chi tiết các quyền được cấp
   - Log test quyền tạo bảng
   - Log fallback sang user sa nếu cần thiết
   - Log tạo login trong SQL Server Security
   - Log kiểm tra và cấp quyền db_owner
   - Log xác nhận quyền đã được cấp

## Tính năng mở rộng

### JWT Authentication

- ✅ Thay thế GUID bằng JWT token
- ✅ Thêm refresh token
- ✅ Xử lý token expiration

### Role-based Access

- Phân quyền người dùng
- Kiểm soát truy cập database
- Audit log

### Multi-tenant

- Hỗ trợ nhiều database
- Chia sẻ tài nguyên
- Backup và restore

## Thay đổi so với phiên bản cũ

### Backend

- ✅ **JWT Authentication**: Thay thế GUID bằng JWT token
- ✅ **Tên database đầy đủ**: Sử dụng đầy đủ email thay vì phần trước @
- ✅ **Tự động tạo user**: Với quyền `db_owner` trong database mới
- ✅ **Tất cả controllers**: Sử dụng JWT authentication
- ✅ **Models**: Cập nhật ID từ Guid sang string
- ✅ **Mã hóa mật khẩu**: Sử dụng SHA256 hash + salt cho tất cả password

### Frontend

- ✅ **Flushbar**: Thay thế SnackBar bằng Flushbar
- ✅ **showFlushbar**: Sử dụng hàm nhất quán với các giao diện khác
- ✅ **JWT token**: Lưu trữ và sử dụng JWT token
- ✅ **Flow đăng nhập 3 bước**: Email → Password → Database Info
- ✅ **Nút thay đổi**: "Kết nối" → "Đăng nhập" → "Đăng ký"
- ✅ **Giao diện thân thiện**: Với người dùng
- ✅ **Giao diện gọn gàng**: Xóa phần hiển thị database name
- ✅ **Thông báo lỗi thân thiện**: Thay thế lỗi API bằng thông báo dễ hiểu

## Ưu điểm của kiến trúc mới

1. **Bảo mật cao**: JWT token thay vì GUID
2. **Mã hóa mật khẩu**: SHA256 hash + salt, không thể reverse engineer
3. **Tách biệt dữ liệu**: Mỗi user có database riêng
4. **Quyền truy cập**: User có quyền đăng nhập trực tiếp vào database
5. **Dễ mở rộng**: Có thể thêm nhiều database
6. **Quản lý đơn giản**: Mỗi database độc lập
7. **Backup dễ dàng**: Có thể backup từng database riêng biệt
8. **Giao diện nhất quán**: Sử dụng Flushbar thay vì SnackBar
9. **showFlushbar nhất quán**: Sử dụng cùng pattern với các giao diện khác
10. **Giao diện gọn gàng**: Không hiển thị thông tin kỹ thuật không cần thiết
11. **Thông báo lỗi thân thiện**: Người dùng dễ hiểu và biết cách khắc phục

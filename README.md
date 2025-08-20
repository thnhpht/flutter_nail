# Nail Management App (Flutter + .NET)

## Yêu cầu cài đặt (macOS)

- Flutter SDK: tải và thêm `flutter/bin` vào PATH. Kiểm tra: `flutter --version`
- .NET SDK 8: cài từ Microsoft. Kiểm tra: `dotnet --info`

## Backend (.NET Web API)

Thư mục: `backend/NailApi`

- Cài packages: `dotnet restore`
- Chạy: `dotnet run`
- API mặc định chạy tại: `http://localhost:5088` (Swagger: `/swagger`)

Bảng dữ liệu (SQLite `nail.db`):

- Customers: khoá chính là `PhoneNumber`
- Employees, Categories, CategoryItems (quan hệ 1-n giữa Category và CategoryItems)

## Flutter app

Thư mục: `app`

- Cài deps: `flutter pub get`
- Chạy debug (web/mobile):
  - Web: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5088/api`
  - iOS Simulator: `flutter run -d ios --dart-define=API_BASE_URL=http://127.0.0.1:5088/api`
  - Android Emulator: `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5088/api`

Ghi chú: Với iOS simulator dùng `127.0.0.1` thay vì `localhost`. Với Android emulator dùng `10.0.2.2`.

## Cấu trúc backend API

- `api/customers`
- `api/employees`
- `api/categories` và `api/categories/{categoryId}/items`

## Troubleshooting

- Nếu Flutter/.NET chưa có sẵn lệnh: hãy cài SDK tương ứng và mở terminal mới.
- Nếu app không gọi được API trên thiết bị thật: thay `API_BASE_URL` bằng IP máy tính trong cùng mạng.

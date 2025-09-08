# Platform Detection & API Configuration

## Tổng quan

Ứng dụng Flutter này đã được cấu hình để tự động detect platform và chọn URL API phù hợp cho từng môi trường.

## Cách hoạt động

### 1. Auto Platform Detection

File `lib/config/api_config.dart` chứa logic detect platform:

- **Android Emulator**: `http://10.0.2.2:5088/api`
- **iOS Simulator**: `http://localhost:5088/api`
- **Web**: `http://localhost:5088/api`
- **Desktop (Windows/Linux/macOS)**: `http://localhost:5088/api`

### 2. Environment Variable Override

Bạn có thể override URL bằng environment variable:

```bash
# Chạy với URL tùy chỉnh
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5088/api
```

### 3. Debug Information

Trong debug mode, ứng dụng sẽ hiển thị:

- Platform hiện tại
- API URL đang sử dụng

## Cách sử dụng

### Chạy trên Android Emulator

```bash
cd app
flutter run
```

Ứng dụng sẽ tự động sử dụng `http://10.0.2.2:5088/api`

### Chạy trên iOS Simulator

```bash
cd app
flutter run
```

Ứng dụng sẽ tự động sử dụng `http://localhost:5088/api`

### Chạy trên Web

```bash
cd app
flutter run -d chrome
```

Ứng dụng sẽ tự động sử dụng `http://localhost:5088/api`

### Chạy với URL tùy chỉnh

```bash
# Sử dụng IP thực của máy
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5088/api

# Sử dụng server remote
flutter run --dart-define=API_BASE_URL=https://your-server.com/api
```

## Troubleshooting

### Lỗi "Không thể kết nối đến máy chủ"

1. **Kiểm tra backend server có chạy không:**

   ```bash
   cd backend/NailApi
   dotnet run
   ```

2. **Kiểm tra URL trong debug overlay:**

   - Mở ứng dụng và xem debug info ở góc trên bên phải
   - Đảm bảo URL đúng với platform

3. **Test kết nối từ browser:**

   - Android Emulator: `http://10.0.2.2:5088/api`
   - iOS/Web/Desktop: `http://localhost:5088/api`

4. **Kiểm tra firewall:**
   - Đảm bảo port 5088 không bị chặn

### Thay đổi IP cho Android Emulator

Nếu `10.0.2.2` không hoạt động, thử:

1. Tìm IP thực của máy:

   ```bash
   # macOS/Linux
   ifconfig | grep "inet "

   # Windows
   ipconfig
   ```

2. Sử dụng IP thực:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5088/api
   ```

## Cấu trúc Code

```
lib/
├── config/
│   └── api_config.dart          # Platform detection logic
├── main.dart                    # Sử dụng ApiConfig.baseUrl
└── ...
```

### ApiConfig Class

```dart
class ApiConfig {
  static String get baseUrl {
    // Auto-detect platform và trả về URL phù hợp
  }

  static String get platformInfo {
    // Trả về tên platform hiện tại
  }
}
```

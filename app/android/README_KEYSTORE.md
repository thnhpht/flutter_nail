# Hướng dẫn tạo keystore và build APK release

## Bước 1: Tạo keystore

Chạy lệnh sau để tạo keystore mới:

```bash
cd /Users/thnhpht/Documents/Workspace/LMS/flutter_nail/app/android && export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" && keytool -genkey -v -keystore keystore/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fshopapp -storepass 123456 -keypass 123456 -dname "CN=FShop, OU=Development, O=Your Company, L=City, S=State, C=VN"
```

**Lưu ý:**

- Thay thế `release-key` bằng alias bạn muốn
- Nhập password mạnh cho keystore và key (ghi nhớ để điền vào key.properties)
- Điền thông tin cá nhân khi được hỏi

## Bước 2: Cập nhật file key.properties

Mở file `android/key.properties` và thay thế các giá trị:

```properties
storeFile=../keystore/release-key.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=release-key
keyPassword=YOUR_KEY_PASSWORD
```

## Bước 3: Build APK release

```bash
cd /Users/thnhpht/Documents/Workspace/LMS/flutter_nail/app
flutter build apk --release
```

APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

## Bước 4: Build App Bundle (khuyến nghị cho Google Play)

```bash
flutter build appbundle --release
```

App Bundle sẽ được tạo tại: `build/app/outputs/bundle/release/app-release.aab`

## Lưu ý bảo mật

- **KHÔNG** commit file `key.properties` và keystore vào git
- Thêm vào `.gitignore`:
  ```
  android/key.properties
  android/keystore/
  ```
- Backup keystore ở nơi an toàn
- Sử dụng cùng keystore cho tất cả các phiên bản release của app

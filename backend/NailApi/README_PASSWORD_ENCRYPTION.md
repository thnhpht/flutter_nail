# Hướng dẫn mã hóa Password trong NailApi

## Tổng quan

Hệ thống hiện tại sử dụng 2 phương pháp bảo mật khác nhau cho password:

1. **Password** (để đăng nhập ứng dụng): Sử dụng SHA256 + Salt (one-way hashing)
2. **PasswordLogin** (để kết nối database): Sử dụng AES encryption (two-way encryption)

## Cách hoạt động

### 1. Password (SHA256 + Salt)

- **Mục đích**: Xác thực đăng nhập ứng dụng
- **Đặc điểm**: Không thể giải mã ngược lại
- **Sử dụng**: `HashPassword()` và `VerifyPassword()`

### 2. PasswordLogin (AES Encryption)

- **Mục đích**: Lưu trữ thông tin kết nối database
- **Đặc điểm**: Có thể giải mã để sử dụng
- **Sử dụng**: `EncryptPasswordLogin()` và `DecryptPasswordLogin()`

## Cấu hình

### Encryption Keys

Thêm vào `appsettings.json`:

```json
{
  "Encryption": {
    "Key": "YourSuperSecretKey12345678901234567890123456789012",
    "IV": "YourIVKey12345678"
  }
}
```

**Lưu ý quan trọng:**

- Key phải có độ dài 32 bytes (256 bits)
- IV phải có độ dài 16 bytes (128 bits)
- **KHÔNG BAO GIỜ** commit encryption keys vào source code
- Sử dụng User Secrets hoặc Environment Variables trong production

### Sử dụng User Secrets (Development)

```bash
dotnet user-secrets set "Encryption:Key" "YourSuperSecretKey12345678901234567890123456789012"
dotnet user-secrets set "Encryption:IV" "YourIVKey12345678"
```

### Sử dụng Environment Variables (Production)

```bash
export Encryption__Key="YourSuperSecretKey12345678901234567890123456789012"
export Encryption__IV="YourIVKey12345678"
```

## Bảo mật

### 1. Key Management

- Sử dụng Azure Key Vault hoặc AWS KMS trong production
- Rotate keys định kỳ
- Không lưu keys trong database

### 2. Salt Generation

- Salt được tạo ngẫu nhiên cho mỗi password
- Salt được lưu cùng với hash

### 3. Encryption Algorithm

- AES-256-CBC cho PasswordLogin
- SHA256 cho Password

## Migration từ plain text

Nếu bạn đã có dữ liệu cũ với PasswordLogin dưới dạng plain text:

1. Tạo migration để mã hóa dữ liệu cũ
2. Sử dụng `EncryptPasswordLogin()` để mã hóa
3. Cập nhật database

## Ví dụ sử dụng

```csharp
// Mã hóa password
var encryptedPassword = _passwordService.EncryptPasswordLogin("MyPassword123!");

// Giải mã password
var decryptedPassword = _passwordService.DecryptPasswordLogin(encryptedPassword);

// Hash password (không thể giải mã)
var hashedPassword = _passwordService.HashPassword("MyPassword123!");

// Verify password
var isValid = _passwordService.VerifyPassword("MyPassword123!", hashedPassword);
```

## Lưu ý bảo mật

1. **KHÔNG BAO GIỜ** log password dưới bất kỳ hình thức nào
2. Sử dụng HTTPS trong production
3. Implement rate limiting cho login attempts
4. Sử dụng strong password policy
5. Regular security audits

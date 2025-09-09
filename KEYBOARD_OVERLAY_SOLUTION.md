# Giải pháp xử lý bàn phím che khuất popup

## Vấn đề

Khi người dùng nhập liệu trong các popup dialog (thêm/chỉnh sửa khách hàng, nhân viên, dịch vụ, danh mục), bàn phím điện thoại hiện lên có thể che khuất các trường input và nút bấm, gây khó khăn cho việc sử dụng.

## Giải pháp đã implement

### 1. Thêm constraints cho dialog container

```dart
Container(
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.8, // 80% chiều cao màn hình
    maxWidth: MediaQuery.of(context).size.width * 0.9,   // 90% chiều rộng màn hình
  ),
  // ... các thuộc tính khác
)
```

### 2. Sử dụng Flexible và SingleChildScrollView

Thay thế `Padding` bằng `Flexible` + `SingleChildScrollView` cho phần content:

```dart
// Trước
Padding(
  padding: const EdgeInsets.all(24),
  child: Form(
    child: Column(
      children: [
        // Các trường input
      ],
    ),
  ),
),

// Sau
Flexible(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      child: Column(
        children: [
          // Các trường input
        ],
      ),
    ),
  ),
),
```

## Các file đã được sửa đổi

1. **customers_screen.dart**

   - `_showAddDialog()` - Dialog thêm khách hàng
   - `_showEditDialog()` - Dialog chỉnh sửa khách hàng

2. **employees_screen.dart**

   - `_showAddDialog()` - Dialog thêm nhân viên
   - `_showEditDialog()` - Dialog chỉnh sửa nhân viên

3. **services_screen.dart**

   - `_showAddDialog()` - Dialog thêm dịch vụ
   - `_showEditDialog()` - Dialog chỉnh sửa dịch vụ

4. **categories_screen.dart**
   - `_showAddDialog()` - Dialog thêm danh mục
   - `_showEditDialog()` - Dialog chỉnh sửa danh mục

## Lợi ích của giải pháp

1. **Responsive**: Dialog tự động điều chỉnh kích thước theo màn hình
2. **Scrollable**: Người dùng có thể scroll khi nội dung vượt quá chiều cao có sẵn
3. **Keyboard-friendly**: Bàn phím không che khuất nội dung quan trọng
4. **Consistent**: Áp dụng thống nhất cho tất cả dialog trong ứng dụng

## Cách hoạt động

1. **Constraints**: Giới hạn kích thước dialog tối đa 80% chiều cao và 90% chiều rộng màn hình
2. **Flexible**: Cho phép dialog co giãn linh hoạt trong không gian có sẵn
3. **SingleChildScrollView**: Cho phép scroll nội dung khi cần thiết
4. **MediaQuery**: Sử dụng kích thước màn hình thực tế để tính toán

## Test cases

Để kiểm tra giải pháp hoạt động:

1. Mở bất kỳ màn hình nào có popup (Khách hàng, Nhân viên, Dịch vụ, Danh mục)
2. Nhấn nút "Thêm" hoặc "Chỉnh sửa"
3. Nhấn vào trường input để hiện bàn phím
4. Kiểm tra:
   - Dialog không bị che khuất hoàn toàn
   - Có thể scroll để xem tất cả nội dung
   - Nút "Lưu" và "Hủy" vẫn có thể truy cập được
   - Dialog tự động điều chỉnh kích thước phù hợp

## Lưu ý

- Giải pháp này tương thích với tất cả kích thước màn hình
- Không ảnh hưởng đến chức năng hiện có
- Có thể áp dụng cho các dialog mới trong tương lai

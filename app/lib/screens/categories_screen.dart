import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

enum MessageType { success, error, warning, info }

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = widget.api.getCategories();
  String _search = '';
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  // Helper method to save image permanently
  Future<String?> _saveImagePermanently(XFile imageFile) async {
    try {
      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDocDir.path, 'category_images');
      
      // Create images directory if it doesn't exist
      final Directory imagesDirectory = Directory(imagesDir);
      if (!await imagesDirectory.exists()) {
        await imagesDirectory.create(recursive: true);
      }
      
      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String newPath = path.join(imagesDir, fileName);
      
      // Copy file to permanent location
      await imageFile.saveTo(newPath);
      
      // Return relative path for storage
      return 'category_images/$fileName';
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Helper method to get image provider for dialog
  ImageProvider? _getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('/')) {
      return FileImage(File(imageUrl));
    } else {
      // For relative paths, we'll handle this in the widget itself
      return null;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getCategories();
    });
  }

  void showFlushbar(String message, {MessageType type = MessageType.info}) {
    Color backgroundColor;
    Icon icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green;
        icon = const Icon(Icons.check_circle, color: Colors.white);
        break;
      case MessageType.error:
        backgroundColor = Colors.red;
        icon = const Icon(Icons.error, color: Colors.white);
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange;
        icon = const Icon(Icons.warning, color: Colors.white);
        break;
      case MessageType.info:
      default:
        backgroundColor = Colors.blue;
        icon = const Icon(Icons.info, color: Colors.white);
        break;
    }

    Flushbar(
      message: message,
      backgroundColor: backgroundColor,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      duration: const Duration(seconds: 3),
      messageColor: Colors.white,
      icon: icon,
    ).show(context);
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    String? imageUrl;
    XFile? pickedImage;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.category, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm danh mục',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tạo danh mục dịch vụ mới',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery);
                          if (img != null) {
                            setState(() {
                              pickedImage = img;
                              imageUrl = img.path;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[50],
                            backgroundImage: _getImageProvider(imageUrl),
                            child: imageUrl == null || imageUrl!.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 32, color: AppTheme.primaryStart),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thêm ảnh',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryStart,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Tên danh mục',
                                  prefixIcon: Icon(Icons.category, color: AppTheme.primaryStart),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên danh mục';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            'Huỷ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryStart.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Lưu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        showFlushbar('Tên danh mục không được để trống', type: MessageType.warning);
        return;
      }
      try {
        String? savedImagePath;
        if (pickedImage != null) {
          savedImagePath = await _saveImagePermanently(pickedImage!);
          if (savedImagePath == null) {
            showFlushbar('Lỗi khi lưu ảnh', type: MessageType.error);
            return;
          }
        }
        
        await widget.api.createCategory(
          name,
          image: savedImagePath,
        );
        await _reload();
        showFlushbar('Thêm danh mục thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi khi thêm danh mục', type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Category c) async {
    final nameCtrl = TextEditingController(text: c.name);

    String? imageUrl = c.image;
    XFile? pickedImage;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chỉnh sửa danh mục',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cập nhật thông tin danh mục',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery);
                          if (img != null) {
                            setState(() {
                              pickedImage = img;
                              imageUrl = img.path;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[50],
                            backgroundImage: _getImageProvider(imageUrl),
                            child: imageUrl == null || imageUrl!.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 32, color: AppTheme.primaryStart),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thay đổi ảnh',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryStart,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _editFormKey,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Tên danh mục',
                                  prefixIcon: Icon(Icons.category, color: AppTheme.primaryStart),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên danh mục';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            'Huỷ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryStart.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_editFormKey.currentState!.validate()) {
                                Navigator.pop(context, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Lưu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        showFlushbar('Tên danh mục không được để trống', type: MessageType.warning);
        return;
      }
      try {
        String? finalImagePath = imageUrl;
        if (pickedImage != null) {
          finalImagePath = await _saveImagePermanently(pickedImage!);
          if (finalImagePath == null) {
            showFlushbar('Lỗi khi lưu ảnh', type: MessageType.error);
            return;
          }
        }
        
        await widget.api.updateCategory(Category(
          id: c.id,
          name: name,
          items: c.items,
          image: finalImagePath,
        ));
        await _reload();
        showFlushbar('Thay đổi thông tin danh mục thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi thay đổi thông tin danh mục', type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Category c) async {
    try {
      await widget.api.deleteCategory(c.id);
      await _reload();
      showFlushbar('Xóa danh mục thành công', type: MessageType.success);
    } catch (e) {
      showFlushbar('Lỗi khi xóa danh mục', type: MessageType.error);
    }
  }

  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a local file path or network URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      // Local file path - handle both absolute and relative paths
      if (imageUrl.startsWith('/')) {
        // Absolute path
        return Image.file(File(imageUrl), fit: BoxFit.cover);
      } else {
        // Relative path - use FutureBuilder to handle async operation
        return FutureBuilder<Directory>(
          future: getApplicationDocumentsDirectory(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final String fullPath = path.join(snapshot.data!.path, imageUrl);
              return Image.file(File(fullPath), fit: BoxFit.cover);
            }
            return Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.controlHeight / 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryStart.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppWidgets.gradientHeader(
                  icon: Icons.category,
                  title: 'Danh mục',
                  subtitle: 'Danh sách danh mục dịch vụ',
                  fullWidth: true,
                ),
                                  const SizedBox(height: 24),
                  SizedBox(
                    height: AppTheme.controlHeight,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: AppTheme.inputDecoration(
                        label: 'Tìm kiếm danh mục...',
                        prefixIcon: Icons.search,
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300, // Đảm bảo có chiều cao cố định
                  child: FutureBuilder<List<Category>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        showFlushbar('Lỗi tải danh sách danh mục', type: MessageType.error);
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(
                            children: [
                              const SizedBox(height: 200),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Không thể tải danh sách danh mục',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vui lòng kiểm tra kết nối mạng hoặc thử lại',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _reload,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final data = snapshot.data ?? [];
                      final filtered = data.where((c) =>
                          c.name.toLowerCase().contains(_search.toLowerCase())).toList();

                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text('Không tìm thấy danh mục')),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: GridView.builder(
                          key: const ValueKey('grid'),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return AppWidgets.animatedItem(
                              index: i,
                              child: GestureDetector(
                                onTap: () => _showEditDialog(c),
                                child: Container(
                                  decoration: AppTheme.cardDecoration(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: c.image != null && c.image!.isNotEmpty
                                              ? _buildImageWidget(c.image!)
                                              : Container(
                                                  color: Colors.orange.shade100,
                                                  child: Center(
                                                    child: Text(
                                                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          children: [
                                            Text(c.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600, fontSize: 14),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1),
                                            Text('${c.items.length} sản phẩm',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey)),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.orange.withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                                    onPressed: () => _showEditDialog(c),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red.withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                                    onPressed: () => _delete(c),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

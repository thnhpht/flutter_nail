import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

enum MessageType { success, error, warning, info }

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<Service>> _future = Future.value([]);
  List<Category> _categories = [];
  String _search = '';
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  Future<void> _load() async {
    final cats = await widget.api.getCategories();
    setState(() {
      _categories = cats;
      _future = widget.api.getServices();
    });
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getServices();
    });
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCatId = _categories.isNotEmpty ? _categories.first.id : null;
    String? imageUrl;
    XFile? pickedImage;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
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
                        child: const Icon(Icons.spa, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm dịch vụ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tạo dịch vụ nail mới',
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
                Padding(
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
                            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? FileImage(File(imageUrl!)) : null,
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCatId,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => selectedCatId = v,
                          decoration: InputDecoration(
                            labelText: 'Danh mục',
                            prefixIcon: Icon(Icons.category, color: AppTheme.primaryStart),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  labelText: 'Tên dịch vụ',
                                  prefixIcon: Icon(Icons.spa, color: AppTheme.primaryStart),
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
                                    return 'Vui lòng nhập tên dịch vụ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: priceCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Giá (VNĐ)',
                                  prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryStart),
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
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập giá';
                                  }
                                  if (double.tryParse(value.trim()) == null) {
                                    return 'Vui lòng nhập giá hợp lệ';
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

    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

      try {
        await widget.api.createService(selectedCatId!, name, price, image: imageUrl);
        await _reload();
        showFlushbar('Thêm dịch vụ thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi khi thêm dịch vụ', type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Service s) async {
    final nameCtrl = TextEditingController(text: s.name);
    final priceCtrl = TextEditingController(text: s.price.toStringAsFixed(0));
    String? selectedCatId = s.categoryId;
    String? imageUrl = s.image;
    XFile? pickedImage;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
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
                              'Chỉnh sửa dịch vụ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cập nhật thông tin dịch vụ',
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
                Padding(
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
                            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCatId,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => selectedCatId = v,
                          decoration: InputDecoration(
                            labelText: 'Danh mục',
                            prefixIcon: Icon(Icons.category, color: AppTheme.primaryStart),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  labelText: 'Tên dịch vụ',
                                  prefixIcon: Icon(Icons.spa, color: AppTheme.primaryStart),
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
                                    return 'Vui lòng nhập tên dịch vụ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: priceCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Giá (VNĐ)',
                                  prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryStart),
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
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập giá';
                                  }
                                  if (double.tryParse(value.trim()) == null) {
                                    return 'Vui lòng nhập giá hợp lệ';
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

    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? s.price;

      try {
        await widget.api.updateService(Service(
          id: s.id,
          categoryId: selectedCatId!,
          name: name,
          price: price,
          image: imageUrl,
        ));
        await _reload();
        showFlushbar('Thay đổi thông tin dịch vụ thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi khi thay đổi thông tin dịch vụ', type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Service s) async {
    try {
      await widget.api.deleteService(s.categoryId, s.id);
      await _reload();
      showFlushbar('Xóa dịch vụ thành công', type: MessageType.success);
    } catch (e) {
      showFlushbar('Lỗi khi xóa dịch vụ', type: MessageType.error);
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
                  icon: Icons.spa,
                  title: 'Dịch vụ',
                  subtitle: 'Quản lý dịch vụ theo danh mục',
                  fullWidth: true,
                ),
                                  const SizedBox(height: 24),
                  SizedBox(
                    height: AppTheme.controlHeight,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: AppTheme.inputDecoration(
                        label: 'Tìm kiếm dịch vụ...',
                        prefixIcon: Icons.search,
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300, // Đảm bảo có chiều cao cố định
                  child: FutureBuilder<List<Service>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        showFlushbar('Lỗi tải danh sách dịch vụ', type: MessageType.error);
                      }
                      final data = snapshot.data ?? [];
                      final filtered = data.where((s) =>
                        s.name.toLowerCase().contains(_search.toLowerCase())
                      ).toList();

                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Không tìm thấy dịch vụ'))]),
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
                            final s = filtered[i];
                            final cat = _categories.firstWhere(
                              (c) => c.id == s.categoryId,
                              orElse: () => Category(id: '', name: ''),
                            );
                            return AppWidgets.animatedItem(
                              index: i,
                              child: GestureDetector(
                                onTap: () => _showEditDialog(s),
                                child: Container(
                                  decoration: AppTheme.cardDecoration(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: s.image != null && s.image!.isNotEmpty
                                              ? Image.network(s.image!, fit: BoxFit.cover)
                                              : Container(
                                                  color: Colors.purple.shade100,
                                                  child: Center(
                                                    child: Text(
                                                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.purple,
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
                                            Text(
                                              s.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              'Giá: ${_formatPrice(s.price)} VNĐ',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'Danh mục: ${cat.name}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey,
                                              ),
                                            ),
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
                                                    onPressed: () => _showEditDialog(s),
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
                                                    onPressed: () => _delete(s),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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

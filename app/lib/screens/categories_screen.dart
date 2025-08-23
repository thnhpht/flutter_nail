import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';

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
    final descCtrl = TextEditingController();
    String? imageUrl;
    XFile? pickedImage;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? FileImage(File(imageUrl!))
                      : null,
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
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
        await widget.api.createCategory(
          name,
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          image: imageUrl,
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
    final descCtrl = TextEditingController(text: c.description ?? '');
    String? imageUrl = c.image;
    XFile? pickedImage;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thay đổi thông tin danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? FileImage(File(imageUrl!))
                      : null,
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
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
        await widget.api.updateCategory(Category(
          id: c.id,
          name: name,
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          items: c.items,
          image: imageUrl,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm danh mục...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm danh mục'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Category>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                showFlushbar('Lỗi tải danh sách danh mục', type: MessageType.error);
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
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: () => _showEditDialog(c),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: c.image != null && c.image!.isNotEmpty
                                      ? Image.network(c.image!, fit: BoxFit.cover)
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
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () => _showEditDialog(c),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _delete(c),
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
    );
  }
}

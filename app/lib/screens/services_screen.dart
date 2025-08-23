import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';

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
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm dịch vụ'),
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
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? FileImage(File(imageUrl!)) : null,
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCatId,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => selectedCatId = v,
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên dịch vụ')),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );

    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      if (name.isEmpty) {
        showFlushbar('Tên dịch vụ không được để trống', type: MessageType.warning);
        return;
      }

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
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thay đổi thông tin dịch vụ'),
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
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCatId,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => selectedCatId = v,
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên dịch vụ')),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );

    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? s.price;

      if (name.isEmpty) {
        showFlushbar('Tên dịch vụ không được để trống', type: MessageType.warning);
        return;
      }

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm dịch vụ...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm dịch vụ'),
              ),
            ],
          ),
        ),
        Expanded(
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
                      orElse: () => Category(id: '', name: '', description: ''),
                    );
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: () => _showEditDialog(s),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
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
                                      'Giá: ${s.price}đ',
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
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () => _showEditDialog(s),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _delete(s),
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
    );
  }
}

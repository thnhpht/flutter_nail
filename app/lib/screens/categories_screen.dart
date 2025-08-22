import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = widget.api.getCategories();
  String _search = '';

  Future<void> _reload() async {
    setState(() { _future = widget.api.getCategories(); });
  }

  Future<void> _addCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm danh mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên danh mục không được để trống')));
        return;
      }
      try {
        await widget.api.createCategory(name, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm danh mục thành công')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _editCategoryDialog(Category c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final descCtrl = TextEditingController(text: c.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Thay đổi thông tin danh mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên danh mục không được để trống')));
        return;
      }
      try {
        await widget.api.updateCategory(Category(id: c.id, name: name, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), items: c.items));
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thay đổi thông tin danh mục thành công')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                  const Spacer(),
                  FilledButton.icon(onPressed: _addCategoryDialog, icon: const Icon(Icons.add), label: const Text('Thêm danh mục')),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: Builder(
                  builder: (context) {
                    final filtered = data.where((c) => c.name.toLowerCase().contains(_search.toLowerCase()) || (c.description ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Không tìm thấy danh mục'))]),
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(c.name),
                            subtitle: Text(c.description ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCategoryDialog(c)),
                                IconButton(icon: const Icon(Icons.delete), onPressed: () async { await widget.api.deleteCategory(c.id); await _reload(); }),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
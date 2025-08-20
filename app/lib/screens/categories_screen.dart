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
      await widget.api.createCategory(nameCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
      await _reload();
    }
  }

  Future<void> _editCategoryDialog(Category c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final descCtrl = TextEditingController(text: c.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa danh mục ${c.id}'),
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
      await widget.api.updateCategory(Category(id: c.id, name: nameCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), items: c.items));
      await _reload();
    }
  }

  Future<void> _addItemDialog(int categoryId) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm dịch vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên dịch vụ')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      await widget.api.createCategoryItem(categoryId, nameCtrl.text.trim(), price);
      await _reload();
    }
  }

  Future<void> _editItemDialog(CategoryItem i) async {
    final nameCtrl = TextEditingController(text: i.name);
    final priceCtrl = TextEditingController(text: i.price.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa dịch vụ ${i.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên dịch vụ')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      final price = double.tryParse(priceCtrl.text.trim()) ?? i.price;
      await widget.api.updateCategoryItem(CategoryItem(id: i.id, categoryId: i.categoryId, name: nameCtrl.text.trim(), price: price));
      await _reload();
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
                  FilledButton.icon(onPressed: _addCategoryDialog, icon: const Icon(Icons.add), label: const Text('Thêm danh mục')),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final c = data[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ExpansionTile(
                        title: Text(c.name),
                        subtitle: Text(c.description ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCategoryDialog(c)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async { await widget.api.deleteCategory(c.id); await _reload(); }),
                          ],
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: FilledButton.icon(onPressed: () => _addItemDialog(c.id), icon: const Icon(Icons.add), label: const Text('Thêm dịch vụ')),
                            ),
                          ),
                          for (final i in c.items)
                            ListTile(
                              title: Text(i.name),
                              subtitle: Text('${i.price.toStringAsFixed(0)} đ'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _editItemDialog(i)),
                                  IconButton(icon: const Icon(Icons.delete), onPressed: () async { await widget.api.deleteCategoryItem(i.categoryId, i.id); await _reload(); }),
                                ],
                              ),
                            ),
                        ],
                      ),
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
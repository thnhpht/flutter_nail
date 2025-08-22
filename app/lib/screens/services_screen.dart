import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<Service>> _future = Future.value([]);
  List<Category> _categories = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.api.getCategories();
    setState(() {
      _categories = cats;
      _future = widget.api.getServices();
    });
  }

  Future<void> _reload() async {
    setState(() { _future = widget.api.getServices(); });
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCatId = _categories.isNotEmpty ? _categories.first.id : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm dịch vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCatId,
              items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => selectedCatId = v,
              decoration: const InputDecoration(labelText: 'Danh mục'),
            ),
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
    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên dịch vụ không được để trống')));
        return;
      }
      try {
        await widget.api.createService(selectedCatId!, name, price);
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm dịch vụ thành công')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _showEditDialog(Service s) async {
    final nameCtrl = TextEditingController(text: s.name);
    final priceCtrl = TextEditingController(text: s.price.toStringAsFixed(0));
    String? selectedCatId = s.categoryId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Thay đổi thông tin dịch vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCatId,
              items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => selectedCatId = v,
              decoration: const InputDecoration(labelText: 'Danh mục'),
            ),
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
    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? s.price;
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên dịch vụ không được để trống')));
        return;
      }
      try {
        await widget.api.updateService(Service(id: s.id, categoryId: selectedCatId!, name: name, price: price));
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thay đổi thông tin dịch vụ thành công')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
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
              FilledButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text('Thêm dịch vụ')),
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
              final data = snapshot.data ?? [];
              final filtered = data.where((s) => s.name.toLowerCase().contains(_search.toLowerCase())).toList();
              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Không tìm thấy dịch vụ'))]),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    final cat = _categories.firstWhere((c) => c.id == s.categoryId, orElse: () => Category(id: '', name: 'Không rõ'));
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text('${s.price.toStringAsFixed(0)} đ - ${cat.name}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(s)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                              try {
                                await widget.api.deleteService(s.categoryId, s.id);
                                await _reload();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa dịch vụ thành công')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                              }
                            }),
                          ],
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

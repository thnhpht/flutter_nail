import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Employee>> _future = widget.api.getEmployees();
  String _search = '';

  Future<void> _reload() async {
    setState(() { _future = widget.api.getEmployees(); });
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm nhân viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'SĐT')),
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
      final phone = phoneCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên nhân viên không được để trống')));
        return;
      }
      try {
        await widget.api.createEmployee(name, phone: phone);
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm nhân viên thành công')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _showEditDialog(Employee e) async {
    final nameCtrl = TextEditingController(text: e.name);
    final phoneCtrl = TextEditingController(text: e.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Thay đổi thông tin nhân viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'SĐT')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.api.updateEmployee(Employee(id: e.id, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()));
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sửa nhân viên thành công')));
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
                    hintText: 'Tìm kiếm nhân viên...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const Spacer(),
              FilledButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text('Thêm nhân viên')),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Employee>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? [];
              final filtered = data.where((e) => e.name.toLowerCase().contains(_search.toLowerCase()) || (e.phone ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Không tìm thấy nhân viên'))]),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(e.name),
                        subtitle: Text(e.phone ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(e)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async { await widget.api.deleteEmployee(e.id); await _reload(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa nhân viên thành công'))); }),
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
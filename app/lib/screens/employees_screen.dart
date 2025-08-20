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
      await widget.api.createEmployee(nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim());
      await _reload();
    }
  }

  Future<void> _showEditDialog(Employee e) async {
    final nameCtrl = TextEditingController(text: e.fullName);
    final phoneCtrl = TextEditingController(text: e.phoneNumber ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa ${e.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: ${e.id}'),
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
      await widget.api.updateEmployee(Employee(id: e.id, fullName: nameCtrl.text.trim(), phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()));
      await _reload();
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
              if (data.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Chưa có nhân viên'))]),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final e = data[i];
                    return ListTile(
                      title: Text(e.fullName),
                      subtitle: Text(e.phoneNumber ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(e)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () async { await widget.api.deleteEmployee(e.id); await _reload(); }),
                        ],
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
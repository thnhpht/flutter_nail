import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';
import 'package:flutter/services.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

enum MessageType { success, error, warning, info }

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Employee>> _future = widget.api.getEmployees();
  String _search = '';

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getEmployees();
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
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm nhân viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'SĐT'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
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
        showFlushbar('Tên nhân viên không được để trống', type: MessageType.warning);
        return;
      }
      try {
        await widget.api.createEmployee(name, phone: phone);
        await _reload();
        showFlushbar('Thêm nhân viên thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi khi thêm nhân viên', type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Employee e) async {
    final nameCtrl = TextEditingController(text: e.name);
    final phoneCtrl = TextEditingController(text: e.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thay đổi thông tin nhân viên'),
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
      if (name.isEmpty) {
        showFlushbar('Tên nhân viên không được để trống', type: MessageType.warning);
        return;
      }
      try {
        await widget.api.updateEmployee(Employee(
          id: e.id,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        ));
        await _reload();
        showFlushbar('Thay đổi thông tin nhân viên thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi thay đổi thông tin nhân viên', type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Employee e) async {
    try {
      await widget.api.deleteEmployee(e.id);
      await _reload();
      showFlushbar('Xóa nhân viên thành công', type: MessageType.success);
    } catch (e) {
      showFlushbar('Lỗi khi xóa nhân viên', type: MessageType.error);
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
              FilledButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm nhân viên'),
              ),
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
              if (snapshot.hasError) {
                showFlushbar('Lỗi tải danh sách nhân viên', type: MessageType.error);
              }
              final data = snapshot.data ?? [];
              final filtered = data.where((e) =>
                e.name.toLowerCase().contains(_search.toLowerCase()) ||
                (e.phone ?? '').toLowerCase().contains(_search.toLowerCase())
              ).toList();

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
                    return InkWell(
                      onTap: () => _showEditDialog(e),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  e.name.isNotEmpty ? e.name[0].toUpperCase() : (e.phone != null && e.phone!.isNotEmpty ? e.phone![0] : '?'),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.name.isEmpty ? (e.phone ?? '') : e.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.phone ?? '',
                                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                tooltip: 'Sửa',
                                onPressed: () => _showEditDialog(e),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Xóa',
                                  onPressed: () => _delete(e),
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

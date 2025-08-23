import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';
import 'package:flutter/services.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

enum MessageType { success, error, warning, info }

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = widget.api.getCustomers();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getCustomers();
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
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm khách hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'SĐT'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      final phone = phoneCtrl.text.trim();
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        showFlushbar('Tên khách hàng không được để trống', type: MessageType.warning);
        return;
      }
      try {
        // Check if phone exists
        try {
          final existing = await widget.api.getCustomer(phone);
          if (existing != null) {
            showFlushbar('SĐT của khách hàng đã được tạo', type: MessageType.warning);
            return;
          }
        } catch (e) {
          // If not found, continue
        }
        await widget.api.createCustomer(Customer(name: name, phone: phone));
        await _reload();
        showFlushbar('Thêm khách hàng thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi khi thêm khách hàng', type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Customer c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thay đổi thông tin khách hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SĐT: ${c.phone}'),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
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
        showFlushbar('Tên khách hàng không được để trống', type: MessageType.warning);
        return;
      }
      try {
        await widget.api.updateCustomer(Customer(phone: c.phone, name: nameCtrl.text.trim()));
        await _reload();
        showFlushbar('Thay đổi thông tin khách hàng thành công', type: MessageType.success);
      } catch (e) {
        showFlushbar('Lỗi thay đổi thông tin khách hàng', type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Customer c) async {
    try {
      await widget.api.deleteCustomer(c.phone);
      await _reload();
      showFlushbar('Xóa khách hàng thành công', type: MessageType.success);
    } catch (e) {
      showFlushbar('Lỗi khi xóa khách hàng', type: MessageType.error);
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
                    hintText: 'Tìm kiếm khách hàng...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),              
              const Spacer(),
              FilledButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text('Thêm khách hàng')),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Customer>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                showFlushbar('Lỗi tải danh sách khách hàng', type: MessageType.error);
              }
              final data = snapshot.data ?? [];
              final filtered = data.where((c) =>
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                c.phone.toLowerCase().contains(_search.toLowerCase())
              ).toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Không tìm thấy khách hàng'))]),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                      return InkWell(
                        onTap: () => _showEditDialog(c),
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
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    c.name.isNotEmpty ? c.name[0].toUpperCase() : c.phone[0],
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name.isEmpty ? c.phone : c.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.phone,
                                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Sửa',
                                  onPressed: () => _showEditDialog(c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Xóa',
                                  onPressed: () => _delete(c),
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

import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getCustomers();
  }

  Future<void> _reload() async {
    setState(() { _future = widget.api.getCustomers(); });
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $e')),
    );
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
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'SĐT')),
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
      try {
        await widget.api.createCustomer(Customer(phoneNumber: phoneCtrl.text.trim(), fullName: nameCtrl.text.trim()));
        await _reload();
      } catch (e) {
        _showError(e);
      }
    }
  }

  Future<void> _showEditDialog(Customer c) async {
    final nameCtrl = TextEditingController(text: c.fullName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sửa ${c.phoneNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SĐT: ${c.phoneNumber}'),
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
      try {
        await widget.api.updateCustomer(Customer(phoneNumber: c.phoneNumber, fullName: nameCtrl.text.trim()));
        await _reload();
      } catch (e) {
        _showError(e);
      }
    }
  }

  Future<void> _delete(Customer c) async {
    try {
      await widget.api.deleteCustomer(c.phoneNumber);
      await _reload();
    } catch (e) {
      _showError(e);
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
                return Center(child: Text('Lỗi tải danh sách: ${snapshot.error}'));
              }
              final data = snapshot.data ?? [];
              if (data.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Chưa có khách hàng'))]),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final c = data[i];
                    return ListTile(
                      title: Text(c.fullName.isEmpty ? c.phoneNumber : c.fullName),
                      subtitle: Text(c.phoneNumber),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(c)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(c)),
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
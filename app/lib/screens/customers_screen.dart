import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';
import 'package:flutter/services.dart';
import '../ui/design_system.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

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
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thêm khách hàng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nhập thông tin khách hàng mới',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone, color: AppTheme.primaryStart),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person, color: AppTheme.primaryStart),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ và tên';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'Huỷ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryStart.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lưu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      final phone = phoneCtrl.text.trim();
      final name = nameCtrl.text.trim();
      
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
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chỉnh sửa khách hàng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cập nhật thông tin khách hàng',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _editFormKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: AppTheme.primaryStart, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'SĐT: ${c.phone}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person, color: AppTheme.primaryStart),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ và tên';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'Huỷ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryStart.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_editFormKey.currentState!.validate()) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lưu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();

      try {
        await widget.api.updateCustomer(Customer(phone: c.phone, name: name));
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.controlHeight / 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryStart.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppWidgets.gradientHeader(
                  icon: Icons.people,
                  title: 'Khách hàng',
                  subtitle: 'Quản lý thông tin khách hàng',
                  fullWidth: true,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: AppTheme.controlHeight,
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: AppTheme.inputDecoration(
                      label: 'Tìm kiếm khách hàng...',
                      prefixIcon: Icons.search,
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: MediaQuery.of(context).size.height - 300, // Đảm bảo có chiều cao cố định
                  child: FutureBuilder<List<Customer>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        showFlushbar('Lỗi tải danh sách khách hàng', type: MessageType.error);
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(
                            children: [
                              const SizedBox(height: 200),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Không thể tải danh sách khách hàng',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vui lòng kiểm tra kết nối mạng hoặc thử lại',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _reload,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
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
                            return AppWidgets.animatedItem(
                              index: i,
                              child: InkWell(
                                onTap: () => _showEditDialog(c),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: AppTheme.cardDecoration(),
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
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                            tooltip: 'Sửa',
                                            onPressed: () => _showEditDialog(c),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                            tooltip: 'Xóa',
                                            onPressed: () => _delete(c),
                                          ),
                                        ),
                                      ],
                                    ),
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
            ),
          ),
        ),
      ),
    );
  }
}

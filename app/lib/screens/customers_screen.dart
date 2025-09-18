import 'package:flutter/material.dart';
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

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> _future;
  String _search = '';
  final _searchController = TextEditingController();

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

  Future<void> _showAddDialog() async {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: AppTheme.floatingCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.textOnPrimary.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: AppTheme.textOnPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thêm khách hàng',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Nhập thông tin khách hàng mới',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: AppTheme.inputDecoration(
                          label: 'Tên khách hàng',
                          prefixIcon: Icons.person,
                        ),
                        validator: (v) => v?.trim().isEmpty == true
                            ? 'Vui lòng nhập tên'
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: AppTheme.inputDecoration(
                          label: 'Số điện thoại',
                          prefixIcon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) => v?.trim().isEmpty == true
                            ? 'Vui lòng nhập số điện thoại'
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spacingXL),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: AppWidgets.secondaryButton(
                              label: 'Hủy',
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: AppWidgets.primaryButton(
                              label: 'Lưu',
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context, true);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final phone = phoneCtrl.text.trim();
      final name = nameCtrl.text.trim();

      try {
        // Check if phone exists
        try {
          final existing = await widget.api.getCustomer(phone);
          if (existing != null) {
            AppWidgets.showFlushbar(
              context,
              'Số điện thoại đã được sử dụng',
              type: MessageType.warning,
            );
            return;
          }
        } catch (e) {
          // If not found, continue
        }

        await widget.api.createCustomer(Customer(name: name, phone: phone));
        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Thêm khách hàng thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi thêm khách hàng',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _showEditDialog(Customer customer) async {
    final nameCtrl = TextEditingController(text: customer.name);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: AppTheme.floatingCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.textOnPrimary.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppTheme.textOnPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sửa thông tin',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Cập nhật thông tin khách hàng',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: AppTheme.inputDecoration(
                          label: 'Tên khách hàng',
                          prefixIcon: Icons.person,
                        ),
                        validator: (v) => v?.trim().isEmpty == true
                            ? 'Vui lòng nhập tên'
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Phone (read-only)
                      TextFormField(
                        initialValue: customer.phone,
                        decoration: AppTheme.inputDecoration(
                          label: 'Số điện thoại',
                          prefixIcon: Icons.phone,
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: AppTheme.spacingXL),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: AppWidgets.secondaryButton(
                              label: 'Hủy',
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: AppWidgets.primaryButton(
                              label: 'Lưu',
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context, true);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      try {
        await widget.api
            .updateCustomer(Customer(phone: customer.phone, name: name));
        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Cập nhật thông tin thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi cập nhật thông tin',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _delete(Customer customer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Xác nhận xóa',
          style: AppTheme.headingSmall,
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa khách hàng "${customer.name}"?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          AppWidgets.secondaryButton(
            label: 'Hủy',
            onPressed: () => Navigator.pop(context, false),
            isSmall: true,
          ),
          AppWidgets.primaryButton(
            label: 'Xóa',
            onPressed: () => Navigator.pop(context, true),
            isSmall: true,
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await widget.api.deleteCustomer(customer.phone);
        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Xóa khách hàng thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi xóa khách hàng',
          type: MessageType.error,
        );
      }
    }
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    if (_search.isEmpty) return customers;

    return customers.where((customer) {
      final searchLower = _search.toLowerCase();
      return customer.name.toLowerCase().contains(searchLower) ||
          customer.phone.contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Khách hàng',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          AppWidgets.iconButton(
            icon: Icons.add,
            onPressed: _showAddDialog,
            backgroundColor: AppTheme.primaryPink,
            iconColor: AppTheme.textOnPrimary,
            elevated: true,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý thông tin khách hàng',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppWidgets.searchField(
                  hintText: 'Tìm kiếm theo tên hoặc số điện thoại...',
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPink,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể tải danh sách khách hàng',
                          style: AppTheme.headingSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng kiểm tra kết nối mạng và thử lại',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppWidgets.primaryButton(
                          label: 'Thử lại',
                          onPressed: _reload,
                        ),
                      ],
                    ),
                  );
                }

                final customers = _filterCustomers(snapshot.data ?? []);

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _search.isEmpty
                              ? Icons.people_outline
                              : Icons.search_off,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'Chưa có khách hàng nào'
                              : 'Không tìm thấy kết quả',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isEmpty
                              ? 'Hãy thêm khách hàng đầu tiên'
                              : 'Thử tìm kiếm với từ khóa khác',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_search.isEmpty) ...[
                          const SizedBox(height: 24),
                          AppWidgets.primaryButton(
                            label: 'Thêm khách hàng',
                            onPressed: _showAddDialog,
                            icon: Icons.add,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  color: AppTheme.primaryPink,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return AppWidgets.modernListTile(
                        title: customer.name,
                        subtitle: customer.phone,
                        leadingIcon: Icons.person,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppWidgets.iconButton(
                              icon: Icons.edit,
                              onPressed: () => _showEditDialog(customer),
                              backgroundColor: AppTheme.info.withOpacity(0.1),
                              iconColor: AppTheme.info,
                              size: 36,
                            ),
                            const SizedBox(width: 8),
                            AppWidgets.iconButton(
                              icon: Icons.delete,
                              onPressed: () => _delete(customer),
                              backgroundColor: AppTheme.error.withOpacity(0.1),
                              iconColor: AppTheme.error,
                              size: 36,
                            ),
                          ],
                        ),
                        onTap: () => _showEditDialog(customer),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Employee>> _future = widget.api.getEmployees();
  String _search = '';
  final _searchController = TextEditingController();

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getEmployees();
    });
  }

  List<Employee> _filterEmployees(List<Employee> employees) {
    if (_search.isEmpty) return employees;
    return employees.where((employee) {
      return employee.name.toLowerCase().contains(_search.toLowerCase()) ||
          (employee.phone?.contains(_search) ?? false);
    }).toList();
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
                            'Thêm nhân viên',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Nhập thông tin nhân viên mới',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppWidgets.iconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context, false),
                      iconColor: AppTheme.textOnPrimary,
                      size: 40,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Tên nhân viên',
                            prefixIcon: Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên nhân viên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: phoneController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Số điện thoại',
                            prefixIcon: Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: passwordController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Mật khẩu',
                            prefixIcon: Icons.lock,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
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
                                label: 'Thêm',
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    try {
                                      await widget.api.createEmployee(
                                        nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        password:
                                            passwordController.text.trim(),
                                      );
                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      AppWidgets.showFlushbar(
                                          context, 'Lỗi thêm nhân viên: $e',
                                          type: MessageType.error);
                                    }
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
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      _reload();
      AppWidgets.showFlushbar(context, 'Thêm nhân viên thành công!',
          type: MessageType.success);
    }
  }

  Future<void> _showEditDialog(Employee employee) async {
    final nameController = TextEditingController(text: employee.name);
    final phoneController = TextEditingController(text: employee.phone ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
                            'Sửa nhân viên',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Cập nhật thông tin nhân viên',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppWidgets.iconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context, false),
                      iconColor: AppTheme.textOnPrimary,
                      size: 40,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Tên nhân viên',
                            prefixIcon: Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên nhân viên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: phoneController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Số điện thoại',
                            prefixIcon: Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: passwordController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Mật khẩu mới (để trống nếu không đổi)',
                            prefixIcon: Icons.lock,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
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
                                label: 'Cập nhật',
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    try {
                                      final updatedEmployee = Employee(
                                        id: employee.id,
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        password: passwordController.text
                                                .trim()
                                                .isNotEmpty
                                            ? passwordController.text.trim()
                                            : employee.password,
                                      );
                                      await widget.api
                                          .updateEmployee(updatedEmployee);
                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      AppWidgets.showFlushbar(
                                          context, 'Lỗi cập nhật nhân viên: $e',
                                          type: MessageType.error);
                                    }
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
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      _reload();
      AppWidgets.showFlushbar(context, 'Cập nhật nhân viên thành công!',
          type: MessageType.success);
    }
  }

  Future<void> _delete(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Xác nhận xóa',
          style: AppTheme.headingSmall,
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa nhân viên "${employee.name}"?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          AppWidgets.secondaryButton(
            label: 'Hủy',
            onPressed: () => Navigator.pop(context, false),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                    horizontal: AppTheme.spacingL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Xóa',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.api.deleteEmployee(employee.id);
        _reload();
        AppWidgets.showFlushbar(context, 'Xóa nhân viên thành công!',
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(context, 'Lỗi xóa nhân viên: $e',
            type: MessageType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Nhân viên',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          AppWidgets.iconButton(
            icon: Icons.refresh,
            onPressed: _reload,
            size: 40,
          ),
          AppWidgets.iconButton(
            icon: Icons.add,
            onPressed: _showAddDialog,
            size: 40,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý thông tin nhân viên',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Search Field
                AppWidgets.searchField(
                  hintText: 'Tìm theo tên hoặc số điện thoại...',
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _search = value.trim();
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _search = '';
                    });
                  },
                ),
              ],
            ),
          ),

          // Employees List
          Expanded(
            child: FutureBuilder<List<Employee>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                          'Có lỗi xảy ra',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không thể tải danh sách nhân viên',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppWidgets.primaryButton(
                          label: 'Thử lại',
                          onPressed: _reload,
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  );
                }

                final employees = snapshot.data ?? [];
                final filteredEmployees = _filterEmployees(employees);

                if (filteredEmployees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _search.isNotEmpty
                              ? Icons.search_off
                              : Icons.person_outline,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isNotEmpty
                              ? 'Không tìm thấy nhân viên'
                              : 'Chưa có nhân viên nào',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isNotEmpty
                              ? 'Thử tìm kiếm với từ khóa khác'
                              : 'Thêm nhân viên đầu tiên để bắt đầu',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_search.isEmpty) ...[
                          const SizedBox(height: 16),
                          AppWidgets.primaryButton(
                            label: 'Thêm nhân viên',
                            onPressed: _showAddDialog,
                            icon: Icons.add,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return _buildEmployeeCard(employee);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showEditDialog(employee),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.softPinkGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : 'N',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),

                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: AppTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXXS),
                      if (employee.phone != null &&
                          employee.phone!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              employee.phone!,
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Chưa có số điện thoại',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingXXS),
                      AppWidgets.statusBadge(
                        text: 'Nhân viên',
                        color: AppTheme.info,
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    AppWidgets.iconButton(
                      icon: Icons.edit,
                      onPressed: () => _showEditDialog(employee),
                      backgroundColor: AppTheme.info.withOpacity(0.1),
                      iconColor: AppTheme.info,
                      size: 40,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    AppWidgets.iconButton(
                      icon: Icons.delete,
                      onPressed: () => _delete(employee),
                      backgroundColor: AppTheme.error.withOpacity(0.1),
                      iconColor: AppTheme.error,
                      size: 40,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/bill_helper.dart';
import '../ui/design_system.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.api, this.onOrderCreated});

  final ApiClient api;
  final VoidCallback? onOrderCreated;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Information? _information;
  bool _isInfoLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _customerPhoneController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _discountController = TextEditingController();
  final _tipController = TextEditingController();

  List<Category> _categories = [];
  List<Service> _services = [];
  List<Service> _selectedServices = [];
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  double _totalPrice = 0.0;
  double _discountPercent = 0.0;
  double _tip = 0.0;
  double _finalTotalPrice = 0.0;
  bool _isLoading = false;

  // Current step in the order creation process
  int _currentStep = 0;
  final List<String> _stepTitles = [
    'Khách hàng',
    'Dịch vụ',
    'Nhân viên',
    'Thanh toán'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadServices();
    _loadEmployees();
    _loadInformation();
    _customerPhoneController.addListener(_onCustomerPhoneChanged);
    _tipController.addListener(_onTipChanged);
    _discountController.addListener(_onDiscountChanged);
  }

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onCustomerPhoneChanged);
    _tipController.removeListener(_onTipChanged);
    _discountController.removeListener(_onDiscountChanged);
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    _discountController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _loadInformation() async {
    try {
      final info = await widget.api.getInformation();
      if (mounted) {
        setState(() {
          _information = info;
          _isInfoLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInfoLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      AppWidgets.showFlushbar(context, 'Lỗi tải danh mục: $e',
          type: MessageType.error);
    }
  }

  Future<void> _loadServices() async {
    try {
      final services = await widget.api.getServices();
      setState(() {
        _services = services;
      });
    } catch (e) {
      AppWidgets.showFlushbar(context, 'Lỗi tải dịch vụ: $e',
          type: MessageType.error);
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await widget.api.getEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      AppWidgets.showFlushbar(context, 'Lỗi tải nhân viên: $e',
          type: MessageType.error);
    }
  }

  void _onCustomerPhoneChanged() {
    final phone = _customerPhoneController.text.trim();
    if (phone.length >= 10) {
      _searchCustomer(phone);
    }
  }

  void _onTipChanged() {
    final tip = double.tryParse(_tipController.text.trim()) ?? 0.0;
    setState(() {
      _tip = tip;
      _calculateTotal();
    });
  }

  void _onDiscountChanged() {
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    setState(() {
      _discountPercent = discount;
      _calculateTotal();
    });
  }

  Future<void> _searchCustomer(String phone) async {
    try {
      final customers = await widget.api.getCustomers();
      final customer = customers.where((c) => c.phone == phone).firstOrNull;
      if (customer != null) {
        setState(() {
          _customerNameController.text = customer.name;
        });
      }
    } catch (e) {
      // Handle error silently for auto-search
    }
  }

  void _toggleService(Service service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
      _calculateTotal();
    });
  }

  void _toggleEmployee(Employee employee) {
    setState(() {
      if (_selectedEmployees.contains(employee)) {
        _selectedEmployees.remove(employee);
      } else {
        _selectedEmployees.add(employee);
      }
    });
  }

  void _calculateTotal() {
    _totalPrice =
        _selectedServices.fold(0.0, (sum, service) => sum + service.price);

    final discountAmount = (_totalPrice * _discountPercent) / 100;
    _finalTotalPrice = _totalPrice - discountAmount + _tip;
  }

  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return 'Không xác định';
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      AppWidgets.showFlushbar(context, 'Vui lòng chọn ít nhất một dịch vụ',
          type: MessageType.warning);
      return;
    }
    if (_selectedEmployees.isEmpty) {
      AppWidgets.showFlushbar(context, 'Vui lòng chọn ít nhất một nhân viên',
          type: MessageType.warning);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerPhone = _customerPhoneController.text.trim();
      final customerName = _customerNameController.text.trim();

      // Create customer if not exists
      try {
        await widget.api
            .createCustomer(Customer(phone: customerPhone, name: customerName));
      } catch (e) {
        // Customer might already exist, continue
      }

      // Create the bill
      final uuid = const Uuid();
      final billId = uuid.v4();

      await widget.api.createOrder(Order(
        id: billId,
        customerPhone: customerPhone,
        customerName: customerName,
        employeeIds: _selectedEmployees.map((e) => e.id).toList(),
        employeeNames: _selectedEmployees.map((e) => e.name).toList(),
        serviceIds: _selectedServices.map((s) => s.id).toList(),
        serviceNames: _selectedServices.map((s) => s.name).toList(),
        totalPrice: _finalTotalPrice,
        discountPercent: _discountPercent,
        tip: _tip,
        createdAt: DateTime.now(),
      ));

      AppWidgets.showFlushbar(context, 'Tạo đơn hàng thành công!',
          type: MessageType.success);

      if (widget.onOrderCreated != null) {
        widget.onOrderCreated!();
      }

      // Reset form
      _resetForm();
    } catch (e) {
      AppWidgets.showFlushbar(context, 'Lỗi tạo đơn hàng: $e',
          type: MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _customerPhoneController.clear();
      _customerNameController.clear();
      _discountController.clear();
      _tipController.clear();
      _selectedServices.clear();
      _selectedEmployees.clear();
      _totalPrice = 0.0;
      _discountPercent = 0.0;
      _tip = 0.0;
      _finalTotalPrice = 0.0;
      _currentStep = 0;
    });
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Tạo đơn hàng',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: AppWidgets.iconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
        actions: [
          AppWidgets.iconButton(
            icon: Icons.refresh,
            onPressed: _resetForm,
            size: 40,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: Column(
              children: [
                // Step Progress
                Row(
                  children: List.generate(_stepTitles.length, (index) {
                    final isCompleted = index < _currentStep;
                    final isCurrent = index == _currentStep;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isCompleted || isCurrent
                                    ? AppTheme.primaryPink
                                    : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (index < _stepTitles.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Step Title
                Text(
                  'Bước ${_currentStep + 1}: ${_stepTitles[_currentStep]}',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_currentStep == 0) _buildCustomerStep(),
                    if (_currentStep == 1) _buildServicesStep(),
                    if (_currentStep == 2) _buildEmployeesStep(),
                    if (_currentStep == 3) _buildPaymentStep(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: AppWidgets.secondaryButton(
                      label: 'Quay lại',
                      onPressed: _previousStep,
                      icon: Icons.arrow_back,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: _currentStep > 0 ? 1 : 2,
                  child: _currentStep < _stepTitles.length - 1
                      ? AppWidgets.primaryButton(
                          label: 'Tiếp tục',
                          onPressed: _canProceedToNextStep() ? _nextStep : null,
                          icon: Icons.arrow_forward,
                        )
                      : AppWidgets.primaryButton(
                          label: _isLoading ? 'Đang tạo...' : 'Tạo đơn hàng',
                          onPressed: _isLoading ? null : _createOrder,
                          icon: _isLoading ? null : Icons.shopping_cart,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Customer step
        return _customerPhoneController.text.trim().isNotEmpty &&
            _customerNameController.text.trim().isNotEmpty;
      case 1: // Services step
        return _selectedServices.isNotEmpty;
      case 2: // Employees step
        return _selectedEmployees.isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildCustomerStep() {
    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin khách hàng',
                      style: AppTheme.headingSmall,
                    ),
                    Text(
                      'Nhập số điện thoại để tự động tìm khách hàng',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          TextFormField(
            controller: _customerPhoneController,
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
            controller: _customerNameController,
            decoration: AppTheme.inputDecoration(
              label: 'Tên khách hàng',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên khách hàng';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    final servicesByCategory = <String, List<Service>>{};
    for (final service in _services) {
      if (!servicesByCategory.containsKey(service.categoryId)) {
        servicesByCategory[service.categoryId] = [];
      }
      servicesByCategory[service.categoryId]!.add(service);
    }

    return Column(
      children: [
        // Selected Services Summary
        if (_selectedServices.isNotEmpty) ...[
          Container(
            decoration: AppTheme.cardDecoration(),
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Đã chọn ${_selectedServices.length} dịch vụ',
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: _selectedServices.map((service) {
                    return Container(
                      margin: const EdgeInsets.only(
                          right: AppTheme.spacingS, bottom: AppTheme.spacingS),
                      child: Chip(
                        label: Text(
                          '${service.name} (${_formatPrice(service.price)})',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.success),
                        ),
                        backgroundColor: AppTheme.success.withOpacity(0.1),
                        deleteIcon: Icon(Icons.close,
                            size: 16, color: AppTheme.success),
                        onDeleted: () => _toggleService(service),
                        side: BorderSide(
                            color: AppTheme.success.withOpacity(0.3)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],

        // Services by Category
        ...servicesByCategory.entries.map((entry) {
          final categoryId = entry.key;
          final services = entry.value;
          final categoryName = _getCategoryName(categoryId);

          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
            decoration: AppTheme.cardDecoration(elevated: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPinkLight.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      topRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: AppTheme.primaryPink,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        categoryName,
                        style: AppTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${services.length} dịch vụ',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Services List
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: services.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: AppTheme.spacingS),
                        decoration: AppTheme.cardDecoration(
                          color: isSelected
                              ? AppTheme.primaryPink.withOpacity(0.1)
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLarge),
                            onTap: () => _toggleService(service),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryPink
                                          : AppTheme.surfaceAlt,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check : Icons.spa,
                                      color: isSelected
                                          ? AppTheme.textOnPrimary
                                          : AppTheme.primaryPink,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          style: AppTheme.labelLarge,
                                        ),
                                        const SizedBox(
                                            height: AppTheme.spacingXXS),
                                        Text(
                                          _formatPrice(service.price),
                                          style: AppTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmployeesStep() {
    return Column(
      children: [
        // Selected Employees Summary
        if (_selectedEmployees.isNotEmpty) ...[
          Container(
            decoration: AppTheme.cardDecoration(),
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Đã chọn ${_selectedEmployees.length} nhân viên',
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: _selectedEmployees.map((employee) {
                    return Container(
                      margin: const EdgeInsets.only(
                          right: AppTheme.spacingS, bottom: AppTheme.spacingS),
                      child: Chip(
                        label: Text(
                          employee.name,
                          style:
                              AppTheme.bodySmall.copyWith(color: AppTheme.info),
                        ),
                        backgroundColor: AppTheme.info.withOpacity(0.1),
                        deleteIcon:
                            Icon(Icons.close, size: 16, color: AppTheme.info),
                        onDeleted: () => _toggleEmployee(employee),
                        side: BorderSide(color: AppTheme.info.withOpacity(0.3)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],

        // Employees List
        Container(
          decoration: AppTheme.cardDecoration(elevated: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusLarge),
                    topRight: Radius.circular(AppTheme.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.work,
                      color: AppTheme.info,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Chọn nhân viên phục vụ',
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_employees.length} nhân viên',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Employees
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: _employees.map((employee) {
                    final isSelected = _selectedEmployees.contains(employee);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      decoration: AppTheme.cardDecoration(
                        color:
                            isSelected ? AppTheme.info.withOpacity(0.1) : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          onTap: () => _toggleEmployee(employee),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.info
                                        : AppTheme.surfaceAlt,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.person,
                                    color: isSelected
                                        ? AppTheme.textOnPrimary
                                        : AppTheme.info,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name,
                                        style: AppTheme.labelLarge,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.spacingXXS),
                                      Text(
                                        employee.phone ?? 'Không có SĐT',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        // Order Summary
        Container(
          decoration: AppTheme.cardDecoration(elevated: true),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryPink,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    'Tóm tắt đơn hàng',
                    style: AppTheme.headingSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Customer Info
              _buildSummaryRow('Khách hàng', _customerNameController.text),
              _buildSummaryRow('Số điện thoại', _customerPhoneController.text),

              const Divider(height: 32),

              // Services
              Text(
                'Dịch vụ đã chọn',
                style:
                    AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ..._selectedServices.map((service) =>
                  _buildSummaryRow(service.name, _formatPrice(service.price))),

              const Divider(height: 32),

              // Employees
              Text(
                'Nhân viên phục vụ',
                style:
                    AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                _selectedEmployees.map((e) => e.name).join(', '),
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Payment Details
        Container(
          decoration: AppTheme.cardDecoration(elevated: true),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    color: AppTheme.success,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    'Chi tiết thanh toán',
                    style: AppTheme.headingSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: AppTheme.inputDecoration(
                        label: 'Giảm giá (%)',
                        prefixIcon: Icons.percent,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: TextFormField(
                      controller: _tipController,
                      decoration: AppTheme.inputDecoration(
                        label: 'Tip (VNĐ)',
                        prefixIcon: Icons.volunteer_activism,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Totals
              _buildTotalRow('Tổng dịch vụ', _formatPrice(_totalPrice)),
              if (_discountPercent > 0)
                _buildTotalRow(
                    'Giảm giá (${_discountPercent.toStringAsFixed(0)}%)',
                    '-${_formatPrice((_totalPrice * _discountPercent) / 100)}'),
              if (_tip > 0) _buildTotalRow('Tip', _formatPrice(_tip)),
              const Divider(height: 24),
              _buildTotalRow('Tổng cộng', _formatPrice(_finalTotalPrice),
                  isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w700)
                : AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryPink,
                  )
                : AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

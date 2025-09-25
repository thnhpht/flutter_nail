import '../generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../api_client.dart';
import '../models.dart';
import '../ui/bill_helper.dart';
import '../ui/design_system.dart';
import '../services/notification_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.api, this.onOrderCreated});

  final ApiClient api;
  final VoidCallback? onOrderCreated;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Information? _information;
  final _formKey = GlobalKey<FormState>();
  final _customerPhoneController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _discountController = TextEditingController();
  final _tipController = TextEditingController();

  List<Category> _categories = [];
  List<Service> _services = [];
  List<Service> _selectedServices = [];
  List<Category> _selectedCategories = [];
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  double _totalPrice = 0.0;
  double _discountPercent = 0.0;
  double _tip = 0.0;
  double _finalTotalPrice = 0.0;
  bool _isLoading = false;
  bool _showCategoryDropdown = false;
  bool _showServiceDropdown = false;
  bool _showEmployeeDropdown = false;
  String? _currentUserRole;
  String? _currentEmployeeId;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _loadCategories();
    _loadServices();
    _loadEmployees();
    _loadInformation();
    // Add listeners for auto-search
    _customerPhoneController.addListener(_onCustomerPhoneChanged);
    _employeePhoneController.addListener(_onEmployeePhoneChanged);
    _tipController.addListener(_onTipChanged);
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      final employeeId = prefs.getString('employee_id');

      setState(() {
        _currentUserRole = userRole;
        _currentEmployeeId = employeeId;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadInformation() async {
    try {
      final info = await widget.api.getInformation();
      if (mounted) {
        setState(() {
          _information = info;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onCustomerPhoneChanged);
    _employeePhoneController.removeListener(_onEmployeePhoneChanged);
    _tipController.removeListener(_onTipChanged);
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    _employeePhoneController.dispose();
    _employeeNameController.dispose();
    _discountController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorLoadingCategories(e.toString()),
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
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorLoadingServices(e.toString()),
          type: MessageType.error);
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await widget.api.getEmployees();
      setState(() {
        _employees = employees;

        // Tự động chọn nhân viên đăng nhập nếu là employee
        if (_currentUserRole == 'employee' && _currentEmployeeId != null) {
          final currentEmployee = employees.firstWhere(
            (employee) => employee.id == _currentEmployeeId,
            orElse: () =>
                employees.first, // Fallback to first employee if not found
          );
          _selectedEmployees = [currentEmployee];
        }
      });
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorLoadingEmployees(e.toString()),
          type: MessageType.error);
    }
  }

  Future<void> _findCustomerByPhone() async {
    final phone = _customerPhoneController.text.trim();
    if (phone.length == 10) {
      try {
        final customer = await widget.api.findCustomerByPhone(phone);
        if (customer != null) {
          setState(() {
            _customerNameController.text = customer.name;
          });
          final l10n = AppLocalizations.of(context)!;
          AppWidgets.showFlushbar(context, l10n.customerFound(customer.name),
              type: MessageType.success);
        } else {
          setState(() {
            _customerNameController.clear();
          });
          final l10n = AppLocalizations.of(context)!;
          AppWidgets.showFlushbar(context, l10n.customerNotFound,
              type: MessageType.info);
        }
      } catch (e) {
        AppWidgets.showFlushbar(context,
            AppLocalizations.of(context)!.errorSearchingCustomer(e.toString()),
            type: MessageType.error);
      }
    } else {
      setState(() {
        _customerNameController.clear();
      });
    }
  }

  Future<void> _findEmployeeByPhone() async {
    final phone = _employeePhoneController.text.trim();
    if (phone.length >= 10) {
      try {
        final employee = await widget.api.findEmployeeByPhone(phone);
        if (employee != null) {
          setState(() {
            _employeeNameController.text = employee.name;
          });
          final l10n = AppLocalizations.of(context)!;
          AppWidgets.showFlushbar(context, l10n.employeeFound(employee.name),
              type: MessageType.success);
        } else {
          setState(() {
            _employeeNameController.clear();
          });
          final l10n = AppLocalizations.of(context)!;
          AppWidgets.showFlushbar(context, l10n.employeeNotFound,
              type: MessageType.info);
        }
      } catch (e) {
        AppWidgets.showFlushbar(context,
            AppLocalizations.of(context)!.errorSearchingEmployee(e.toString()),
            type: MessageType.error);
      }
    } else {
      setState(() {
        _employeeNameController.clear();
      });
    }
  }

  void _toggleCategoryDropdown() {
    setState(() {
      _showCategoryDropdown = !_showCategoryDropdown;
      if (_showCategoryDropdown) {
        _showServiceDropdown = false;
      }
    });
  }

  void _toggleServiceDropdown() {
    setState(() {
      _showServiceDropdown = !_showServiceDropdown;
      if (_showServiceDropdown) {
        _showCategoryDropdown = false;
        _showEmployeeDropdown = false;
      }
    });
  }

  void _toggleEmployeeDropdown() {
    setState(() {
      _showEmployeeDropdown = !_showEmployeeDropdown;
      if (_showEmployeeDropdown) {
        _showCategoryDropdown = false;
        _showServiceDropdown = false;
      }
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

  void _onCustomerPhoneChanged() {
    _findCustomerByPhone();
  }

  void _onEmployeePhoneChanged() {
    _findEmployeeByPhone();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Loại bỏ tất cả ký tự không phải số
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Kiểm tra nếu số điện thoại có 10 số
    if (cleanPhone.length == 10) {
      // Format: 0xxx xxx xxx
      return '${cleanPhone.substring(0, 4)} ${cleanPhone.substring(4, 7)} ${cleanPhone.substring(7)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('84')) {
      // Format cho số có mã quốc gia 84: +84 xxx xxx xxx
      return '+${cleanPhone.substring(0, 2)} ${cleanPhone.substring(2, 5)} ${cleanPhone.substring(5, 8)} ${cleanPhone.substring(8)}';
    } else if (cleanPhone.length == 9 && !cleanPhone.startsWith('0')) {
      // Format cho số không có số 0 đầu: 0xxx xxx xxx
      return '0${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }

    // Nếu không phù hợp với format Việt Nam, trả về số gốc
    return phoneNumber;
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image/')) {
        // Xử lý data URL (base64)
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } else if (imageUrl.startsWith('http://') ||
          imageUrl.startsWith('https://')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.image,
                color: Colors.grey[400],
                size: 20,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        );
      } else if (imageUrl.startsWith('/')) {
        return Image.file(File(imageUrl), fit: BoxFit.cover);
      } else {
        return Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.image,
            color: Colors.grey[400],
            size: 20,
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.image,
          color: Colors.grey[400],
          size: 20,
        ),
      );
    }
  }

  void _onCategoryToggled(Category category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        // Remove all services from this category
        _selectedServices
            .removeWhere((service) => service.categoryId == category.id);
      } else {
        _selectedCategories.add(category);
      }
      _calculateTotal();
    });
  }

  void _onServiceToggled(Service service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
        // Add category if not already selected
        final category =
            _categories.firstWhere((c) => c.id == service.categoryId);
        if (!_selectedCategories.contains(category)) {
          _selectedCategories.add(category);
        }
      }
      _calculateTotal();
    });
  }

  void _removeSelectedCategory(Category category) {
    setState(() {
      _selectedCategories.remove(category);
      // Remove all services from this category
      _selectedServices
          .removeWhere((service) => service.categoryId == category.id);
      _calculateTotal();
    });
  }

  void _removeSelectedService(Service service) {
    setState(() {
      _selectedServices.remove(service);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalPrice =
        _selectedServices.fold(0.0, (sum, service) => sum + service.price);
    _finalTotalPrice = _totalPrice * (1 - _discountPercent / 100) + _tip;
  }

  void _onDiscountChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _discountPercent = 0.0;
      } else {
        final discount = double.tryParse(value) ?? 0.0;
        _discountPercent = discount.clamp(0.0, 100.0);
        _discountController.text = _discountPercent.toStringAsFixed(0);
        _discountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _discountController.text.length),
        );
      }
      _calculateTotal();
    });
  }

  void _onTipChanged() {
    final value = _tipController.text;
    setState(() {
      if (value.isEmpty) {
        _tip = 0.0;
      } else {
        final tip = double.tryParse(value) ?? 0.0;
        _tip = tip.clamp(0.0, double.infinity);
      }
      _calculateTotal();
    });
  }

  String _generateOrderId() {
    // Generate a real UUID using the uuid package
    const uuid = Uuid();
    return uuid.v4();
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.pleaseSelectAtLeastOneService,
          type: MessageType.warning);
      return;
    }
    if (_selectedEmployees.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.pleaseSelectAtLeastOneEmployee,
          type: MessageType.warning);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create customer if not exists
      final customerPhone = _customerPhoneController.text.trim();
      final customerName = _customerNameController.text.trim();

      try {
        await widget.api.getCustomer(customerPhone);
      } catch (e) {
        // Customer doesn't exist, create new one
        await widget.api
            .createCustomer(Customer(phone: customerPhone, name: customerName));
      }

      // Create orders for each selected employee
      List<Order> createdOrders = [];
      if (_selectedCategories.isNotEmpty && _selectedServices.isNotEmpty) {
        final order = Order(
          id: _generateOrderId(), // Generate unique ID locally
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
          isPaid: false, // Mặc định chưa thanh toán
        );

        // Validate order data
        if (order.serviceIds.isEmpty || order.serviceNames.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          throw Exception(l10n.invalidServiceData);
        }

        // Create order and get the response with real ID
        final createdOrder = await widget.api.createOrder(order);
        createdOrders.add(createdOrder);
      }

      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.orderCreatedSuccessfully,
          type: MessageType.success);

      // Send notification to shop owner if employee created the order
      if (_currentUserRole == 'employee' && _currentEmployeeId != null) {
        try {
          await _notificationService.createOrderCreatedNotification(
            orderId: createdOrders.first.id,
            customerName: customerName,
            customerPhone: customerPhone,
            employeeName: _selectedEmployees.first.name,
            totalPrice: _finalTotalPrice,
            context: context,
            currentUserRole: _currentUserRole,
          );
        } catch (e) {
          // Handle notification error silently
        }
      }

      // Create a backup of selected services before showing bills
      final selectedServicesBackup = List<Service>.from(_selectedServices);

      // Show bill for each created order using the real order data
      for (final createdOrder in createdOrders) {
        // Show bill dialog with the real order data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Create services list from the backup data
          final servicesForBill = selectedServicesBackup
              .where((service) => createdOrder.serviceIds.contains(service.id))
              .toList();

          BillHelper.showBillDialog(
            context: context,
            order: createdOrder,
            services: servicesForBill,
            api: widget.api,
            salonName: _information?.salonName,
            salonAddress: _information?.address,
            salonPhone: _information?.phone,
          );
        });
      }

      // Call the callback after a delay to ensure bills are shown first
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onOrderCreated?.call();
      });

      // Reset form after showing bills and calling callback
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _resetForm();
        }
      });
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorCreatingOrder(e.toString()),
          type: MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _customerPhoneController.clear();
    _customerNameController.clear();
    _employeePhoneController.clear();
    _employeeNameController.clear();
    _discountController.clear();
    _tipController.clear();
    setState(() {
      _selectedCategories.clear();
      _selectedServices.clear();
      _selectedEmployees.clear();
      _totalPrice = 0.0;
      _discountPercent = 0.0;
      _tip = 0.0;
      _finalTotalPrice = 0.0;
      _showCategoryDropdown = false;
      _showServiceDropdown = false;
      _showEmployeeDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        // Close dropdowns when tapping outside
        if (_showCategoryDropdown ||
            _showServiceDropdown ||
            _showEmployeeDropdown) {
          setState(() {
            _showCategoryDropdown = false;
            _showServiceDropdown = false;
            _showEmployeeDropdown = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.createNewOrder,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.servicesSelected(_selectedServices.length),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Customer Information
                    _buildSectionCard(
                      title: l10n.customerInformation,
                      icon: Icons.person,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _customerPhoneController,
                            label: l10n.phoneNumber,
                            prefixIcon: Icons.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterPhoneNumber;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _customerNameController,
                            label: l10n.customerName,
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterCustomerName;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Employee Information - chỉ hiển thị khi không phải nhân viên đăng nhập
                    if (_currentUserRole != 'employee')
                      _buildSectionCard(
                        title: l10n.employeeInformation,
                        icon: Icons.work,
                        child: Column(
                          children: [
                            // Selected Employees Chips
                            if (_selectedEmployees.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedEmployees
                                    .map((employee) => _buildChip(
                                          label: employee.name,
                                          onDeleted: () =>
                                              _toggleEmployee(employee),
                                          color: const Color(0xFF667eea),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Employee Dropdown
                            _buildDropdownButton(
                              onTap: _toggleEmployeeDropdown,
                              label: _selectedEmployees.isEmpty
                                  ? l10n.selectEmployee
                                  : l10n.employeesSelected(
                                      _selectedEmployees.length),
                              isExpanded: _showEmployeeDropdown,
                              selectText: l10n.select,
                            ),
                            if (_showEmployeeDropdown) ...[
                              const SizedBox(height: 8),
                              _buildDropdownMenu(
                                maxHeight: 200,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _employees.length,
                                  itemBuilder: (context, index) {
                                    final employee = _employees[index];
                                    final isSelected =
                                        _selectedEmployees.contains(employee);
                                    return _buildDropdownEmployeeItem(
                                      title: employee.name,
                                      subtitle: employee.phone != null
                                          ? _formatPhoneNumber(employee.phone!)
                                          : '',
                                      isSelected: isSelected,
                                      onTap: () => _toggleEmployee(employee),
                                      image: employee.image,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      // Hiển thị thông tin nhân viên đăng nhập
                      _buildSectionCard(
                        title: l10n.performingEmployee,
                        icon: Icons.person,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF667eea).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF667eea)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: const Color(0xFF667eea),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedEmployees.isNotEmpty
                                          ? _selectedEmployees.first.name
                                          : l10n.loggedInEmployee,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                    if (_selectedEmployees.isNotEmpty &&
                                        _selectedEmployees.first.phone != null)
                                      Text(
                                        _formatPhoneNumber(
                                            _selectedEmployees.first.phone!),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Category Selection
                    _buildSectionCard(
                      title: l10n.serviceCategories,
                      icon: Icons.category,
                      child: Column(
                        children: [
                          // Selected Categories Chips
                          if (_selectedCategories.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedCategories.map((category) {
                                return _buildChip(
                                  label: category.name,
                                  onDeleted: () =>
                                      _removeSelectedCategory(category),
                                  color: const Color(0xFF7386dd),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Category Dropdown
                          _buildDropdownButton(
                            onTap: _toggleCategoryDropdown,
                            label: _selectedCategories.isEmpty
                                ? l10n.selectCategory
                                : l10n.categoriesSelected(
                                    _selectedCategories.length),
                            isExpanded: _showCategoryDropdown,
                            selectText: l10n.select,
                          ),

                          // Category Dropdown Menu
                          if (_showCategoryDropdown) ...[
                            const SizedBox(height: 8),
                            _buildDropdownMenu(
                              maxHeight: 200,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  final isSelected =
                                      _selectedCategories.contains(category);
                                  return _buildDropdownCategoryItem(
                                    title: category.name,
                                    isSelected: isSelected,
                                    onTap: () => _onCategoryToggled(category),
                                    image: category.image,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Services Selection
                    _buildSectionCard(
                      title: l10n.services,
                      icon: Icons.spa,
                      child: Column(
                        children: [
                          // Selected Services Chips
                          if (_selectedServices.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedServices.map((service) {
                                return _buildChip(
                                  label: service.name,
                                  onDeleted: () =>
                                      _removeSelectedService(service),
                                  color: const Color(0xFF764ba2),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Service Dropdown
                          _buildDropdownButton(
                            onTap: _toggleServiceDropdown,
                            label: _selectedServices.isEmpty
                                ? l10n.selectService
                                : l10n.servicesSelectedCount(
                                    _selectedServices.length),
                            isExpanded: _showServiceDropdown,
                            selectText: l10n.select,
                          ),

                          // Service Dropdown Menu
                          if (_showServiceDropdown) ...[
                            const SizedBox(height: 8),
                            _buildDropdownMenu(
                              maxHeight: 300,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: (_selectedCategories.isEmpty
                                        ? _categories
                                        : _selectedCategories)
                                    .length,
                                itemBuilder: (context, categoryIndex) {
                                  final visibleCategories =
                                      _selectedCategories.isEmpty
                                          ? _categories
                                          : _selectedCategories;
                                  final category =
                                      visibleCategories[categoryIndex];
                                  final categoryServices = _services
                                      .where((service) =>
                                          service.categoryId == category.id)
                                      .toList();

                                  if (categoryServices.isEmpty)
                                    return const SizedBox.shrink();

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category Header
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      // Services in this category
                                      ...categoryServices.map((service) {
                                        final isSelected =
                                            _selectedServices.contains(service);
                                        return _buildDropdownServiceItem(
                                          title: service.name,
                                          subtitle: l10n.subtotalAmount(
                                              _formatPrice(service.price)),
                                          isSelected: isSelected,
                                          onTap: () =>
                                              _onServiceToggled(service),
                                          image: service.image,
                                        );
                                      }).toList(),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Discount Section
                    _buildSectionCard(
                      title: l10n.discount,
                      icon: Icons.discount,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                suffixText: '%',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF667eea), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: _onDiscountChanged,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final discount = double.tryParse(value);
                                  if (discount == null ||
                                      discount < 0 ||
                                      discount > 100) {
                                    return l10n.discountMustBe0To100;
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              l10n.discountAmount(_formatPrice(
                                  _totalPrice * _discountPercent / 100)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tip Section
                    _buildSectionCard(
                      title: l10n.tip,
                      icon: Icons.volunteer_activism,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tipController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.vnd,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF667eea), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) => _onTipChanged(),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final tip = double.tryParse(value);
                                  if (tip == null || tip < 0) {
                                    return l10n.tipMustBeGreaterThan0;
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              l10n.tipAmount(_formatPrice(_tip)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Total Price
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.subtotal,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                l10n.subtotalAmount(_formatPrice(_totalPrice)),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_discountPercent > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.discountPercentage(
                                      _discountPercent.toStringAsFixed(0)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  l10n.discountAmountNegative(_formatPrice(
                                      _totalPrice * _discountPercent / 100)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_tip > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.tipLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  l10n.tipAmountPositive(_formatPrice(_tip)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.totalPayment,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                l10n.totalPaymentAmount(
                                    _formatPrice(_finalTotalPrice)),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryButton(
                            onPressed: _isLoading ? null : _createOrder,
                            isLoading: _isLoading,
                            label: l10n.createOrder,
                            icon: Icons.check,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSecondaryButton(
                            onPressed: _isLoading ? null : _resetForm,
                            label: l10n.refresh,
                            icon: Icons.refresh,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onDeleted,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
      onDeleted: onDeleted,
      backgroundColor: color,
      side: BorderSide.none,
    );
  }

  Widget _buildDropdownButton({
    required VoidCallback onTap,
    required String label,
    required bool isExpanded,
    required String selectText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: label.contains(selectText)
                    ? Colors.grey[600]
                    : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownMenu({
    required double maxHeight,
    required Widget child,
  }) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDropdownCategoryItem({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? image,
  }) {
    return ListTile(
      leading: image != null && image.isNotEmpty
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(image),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Icon(
                Icons.category,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      tileColor:
          isSelected ? const Color(0xFF667eea).withValues(alpha: 0.1) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDropdownServiceItem({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? image,
  }) {
    return ListTile(
      leading: image != null && image.isNotEmpty
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(image),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Icon(
                Icons.spa,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      tileColor:
          isSelected ? const Color(0xFF667eea).withValues(alpha: 0.1) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDropdownEmployeeItem({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? image,
  }) {
    return ListTile(
      leading: image != null && image.isNotEmpty
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: _buildImageWidget(image),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      tileColor:
          isSelected ? const Color(0xFF667eea).withValues(alpha: 0.1) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

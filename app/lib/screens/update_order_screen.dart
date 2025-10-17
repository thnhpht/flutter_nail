import '../generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class UpdateOrderScreen extends StatefulWidget {
  const UpdateOrderScreen({
    super.key,
    required this.api,
    required this.order,
    this.onOrderUpdated,
    this.onCancel,
  });

  final ApiClient api;
  final Order order;
  final VoidCallback? onOrderUpdated;
  final VoidCallback? onCancel;

  @override
  State<UpdateOrderScreen> createState() => _UpdateOrderScreenState();
}

class _UpdateOrderScreenState extends State<UpdateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerPhoneController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _discountController = TextEditingController();
  final _tipController = TextEditingController();
  final _taxController = TextEditingController();
  final _shippingFeeController = TextEditingController();

  List<Category> _categories = [];
  List<Service> _services = [];
  List<ServiceWithQuantity> _selectedServices = [];
  List<Category> _selectedCategories = [];
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  double _totalPrice = 0.0;
  double _discountPercent = 0.0;
  double _tip = 0.0;
  double _taxPercent = 0.0;
  double _shippingFee = 0.0;
  double _finalTotalPrice = 0.0;
  bool _isLoading = false;
  bool _showEmployeeDropdown = false;
  bool _isPaid = false;
  String? _currentUserRole;
  String? _currentEmployeeId;
  String _deliveryOption = 'pickup'; // 'pickup' or 'delivery'

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Add listeners for auto-search
    _customerPhoneController.addListener(_onCustomerPhoneChanged);
    _employeePhoneController.addListener(_onEmployeePhoneChanged);
    _tipController.addListener(_onTipChanged);
    _taxController.addListener(_onTaxChanged);
    _shippingFeeController.addListener(_onShippingFeeChanged);
  }

  Future<void> _initializeData() async {
    // Load user info first
    await _loadCurrentUserInfo();
    // Then load other data
    _loadCategories();
    _loadServices();
    _loadEmployees();
    // Initialize form data after user info is loaded
    _initializeFormData();
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

  void _initializeFormData() {
    // Initialize form with existing order data
    _customerPhoneController.text = widget.order.customerPhone;
    _customerNameController.text = widget.order.customerName;
    _discountController.text = widget.order.discountPercent.toStringAsFixed(0);
    _tipController.text = widget.order.tip.toStringAsFixed(0);
    _taxController.text = widget.order.taxPercent.toStringAsFixed(0);
    _shippingFeeController.text = widget.order.shippingFee.toStringAsFixed(0);
    _isPaid = widget.order.isPaid;
    _deliveryOption = widget.order.deliveryMethod.isNotEmpty
        ? widget.order.deliveryMethod
        : 'pickup';

    _discountPercent = widget.order.discountPercent;
    _tip = widget.order.tip;
    _taxPercent = widget.order.taxPercent;
    _shippingFee = widget.order.shippingFee;

    // Initialize selected employees (optional)
    if (_employees.isNotEmpty) {
      if (_currentUserRole == 'employee' && _currentEmployeeId != null) {
        // Nếu là nhân viên đăng nhập, tự động chọn nhân viên đó
        try {
          final currentEmployee = _employees.firstWhere(
            (employee) => employee.id == _currentEmployeeId,
          );
          _selectedEmployees = [currentEmployee];
        } catch (e) {
          // Nếu không tìm thấy nhân viên, để danh sách rỗng
          _selectedEmployees = [];
        }
      } else {
        // Nếu là chủ shop, giữ nguyên logic cũ
        _selectedEmployees = _employees
            .where((employee) => widget.order.employeeIds.contains(employee.id))
            .toList();
      }
    } else {
      // Không có nhân viên nào, để danh sách rỗng
      _selectedEmployees = [];
    }

    // Initialize selected services and categories with quantities
    _selectedServices = [];
    for (int i = 0; i < widget.order.serviceIds.length; i++) {
      final serviceId = widget.order.serviceIds[i];
      final quantity = i < widget.order.serviceQuantities.length
          ? widget.order.serviceQuantities[i]
          : 1; // Default to 1 if quantity not available

      // Tìm service với try-catch để tránh lỗi "no element"
      try {
        final service = _services.firstWhere((s) => s.id == serviceId);
        _selectedServices.add(ServiceWithQuantity(
          service: service,
          quantity: quantity,
        ));
      } catch (e) {
        // Nếu không tìm thấy service, bỏ qua
        print('Service not found: $serviceId');
      }
    }

    _selectedCategories = _categories
        .where((category) => _selectedServices.any((serviceWithQuantity) =>
            serviceWithQuantity.service.categoryId == category.id))
        .toList();

    _calculateTotal();
  }

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onCustomerPhoneChanged);
    _employeePhoneController.removeListener(_onEmployeePhoneChanged);
    _tipController.removeListener(_onTipChanged);
    _taxController.removeListener(_onTaxChanged);
    _shippingFeeController.removeListener(_onShippingFeeChanged);
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    _employeePhoneController.dispose();
    _employeeNameController.dispose();
    _discountController.dispose();
    _tipController.dispose();
    _taxController.dispose();
    _shippingFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getCategories();
      setState(() {
        _categories = categories;
        // Initialize form data if services are loaded (employees are optional)
        if (_services.isNotEmpty) {
          _initializeFormData();
        }
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
        // Initialize form data if categories are loaded (employees are optional)
        if (_categories.isNotEmpty) {
          _initializeFormData();
        }
      });
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorLoadingServices(e.toString()),
          type: MessageType.error);
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final allEmployees = await widget.api.getEmployees();
      List<Employee> employees;

      // Filter employees based on delivery option
      if (_deliveryOption == 'delivery') {
        // Load delivery employees for home delivery
        employees = allEmployees
            .where((employee) => employee.employeeType == 'delivery')
            .toList();
      } else {
        // Load service employees for pickup
        employees = allEmployees
            .where((employee) => employee.employeeType == 'service')
            .toList();
      }

      setState(() {
        _employees = employees;
        // Initialize form data if categories and services are loaded
        if (_categories.isNotEmpty && _services.isNotEmpty) {
          _initializeFormData();
        }
        _ensureEmployeeSelected(); // Ensure current employee is selected
      });
    } catch (e) {
      // If employees fail to load, still try to initialize form data
      setState(() {
        _employees = [];
        if (_categories.isNotEmpty && _services.isNotEmpty) {
          _initializeFormData();
        }
      });
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorLoadingEmployees(e.toString()),
          type: MessageType.error);
    }
  }

  Future<void> _loadEmployeesForDeliveryOption() async {
    try {
      final allEmployees = await widget.api.getEmployees();
      List<Employee> employees;

      // Filter employees based on delivery option
      if (_deliveryOption == 'delivery') {
        // Load delivery employees for home delivery
        employees = allEmployees
            .where((employee) => employee.employeeType == 'delivery')
            .toList();
      } else {
        // Load service employees for pickup
        employees = allEmployees
            .where((employee) => employee.employeeType == 'service')
            .toList();
      }

      setState(() {
        _employees = employees;
        // Don't reinitialize form data to avoid resetting delivery option
        _ensureEmployeeSelected(); // Ensure current employee is selected
      });
    } catch (e) {
      // If employees fail to load, don't reinitialize form data
      setState(() {
        _employees = [];
      });
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorLoadingEmployees(e.toString()),
          type: MessageType.error);
    }
  }

  void _ensureEmployeeSelected() {
    // Đảm bảo nhân viên hiện tại được chọn nếu đang đăng nhập bằng nhân viên
    // Chỉ thực hiện nếu có nhân viên trong danh sách
    if (_currentUserRole == 'employee' &&
        _currentEmployeeId != null &&
        _employees.isNotEmpty &&
        _selectedEmployees.isEmpty) {
      try {
        final currentEmployee = _employees.firstWhere(
          (employee) => employee.id == _currentEmployeeId,
        );
        _selectedEmployees = [currentEmployee];
      } catch (e) {
        // Nếu không tìm thấy nhân viên, để danh sách rỗng
        _selectedEmployees = [];
      }
    }
    // Nếu không có nhân viên nào, _selectedEmployees sẽ là danh sách rỗng (đã được xử lý trong _initializeFormData)
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

  void _toggleEmployeeDropdown() {
    setState(() {
      _showEmployeeDropdown = !_showEmployeeDropdown;
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
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
        // Không tự động xóa các dịch vụ đã chọn khi bỏ chọn danh mục
        // Người dùng có thể tự xóa dịch vụ thông qua chip hoặc chọn lại danh mục
      } else {
        _selectedCategories.add(category);
      }
      _calculateTotal();
    });
  }

  void _onServiceToggled(Service service) {
    setState(() {
      final existingIndex = _selectedServices.indexWhere(
        (swq) => swq.service.id == service.id,
      );

      if (existingIndex != -1) {
        _selectedServices.removeAt(existingIndex);
      } else {
        _selectedServices
            .add(ServiceWithQuantity(service: service, quantity: 1));
        // Add category if not already selected
        try {
          final category =
              _categories.firstWhere((c) => c.id == service.categoryId);
          if (!_selectedCategories.contains(category)) {
            _selectedCategories.add(category);
          }
        } catch (e) {
          // Nếu không tìm thấy category, bỏ qua
        }
      }
      _calculateTotal();
    });
  }

  void _removeSelectedService(ServiceWithQuantity serviceWithQuantity) {
    setState(() {
      _selectedServices.remove(serviceWithQuantity);
      _calculateTotal();
    });
  }

  void _increaseServiceQuantity(ServiceWithQuantity serviceWithQuantity) {
    setState(() {
      final index = _selectedServices.indexOf(serviceWithQuantity);
      if (index != -1) {
        _selectedServices[index] = serviceWithQuantity.copyWith(
          quantity: serviceWithQuantity.quantity + 1,
        );
        _calculateTotal();
      }
    });
  }

  void _decreaseServiceQuantity(ServiceWithQuantity serviceWithQuantity) {
    setState(() {
      final index = _selectedServices.indexOf(serviceWithQuantity);
      if (index != -1) {
        if (serviceWithQuantity.quantity > 1) {
          _selectedServices[index] = serviceWithQuantity.copyWith(
            quantity: serviceWithQuantity.quantity - 1,
          );
        } else {
          _selectedServices.removeAt(index);
        }
        _calculateTotal();
      }
    });
  }

  void _calculateTotal() {
    _totalPrice = _selectedServices.fold(0.0,
        (sum, serviceWithQuantity) => sum + serviceWithQuantity.totalPrice);
    final subtotalAfterDiscount = _totalPrice * (1 - _discountPercent / 100);
    final taxAmount = subtotalAfterDiscount * (_taxPercent / 100);
    _finalTotalPrice = subtotalAfterDiscount + _tip + taxAmount + _shippingFee;
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

  void _onTaxChanged() {
    final value = _taxController.text;
    setState(() {
      if (value.isEmpty) {
        _taxPercent = 0.0;
      } else {
        final tax = double.tryParse(value) ?? 0.0;
        _taxPercent = tax.clamp(0.0, 100.0);
        _taxController.text = _taxPercent.toStringAsFixed(0);
        _taxController.selection = TextSelection.fromPosition(
          TextPosition(offset: _taxController.text.length),
        );
      }
      _calculateTotal();
    });
  }

  void _onShippingFeeChanged() {
    final value = _shippingFeeController.text;
    setState(() {
      if (value.isEmpty) {
        _shippingFee = 0.0;
      } else {
        final shippingFee = double.tryParse(value) ?? 0.0;
        _shippingFee = shippingFee.clamp(0.0, double.infinity);
      }
      _calculateTotal();
    });
  }

  void _onDeliveryOptionChanged(String value) {
    setState(() {
      _deliveryOption = value;
      // Clear selected employees when changing delivery option
      _selectedEmployees.clear();
    });
    // Reload employees based on new delivery option without reinitializing form data
    _loadEmployeesForDeliveryOption();
  }

  bool _canUpdateOrder() {
    // Check if order is from today
    final today = DateTime.now();
    final orderDate = DateTime(
      widget.order.createdAt.year,
      widget.order.createdAt.month,
      widget.order.createdAt.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);

    return orderDate.isAtSameMomentAs(todayDate);
  }

  Future<void> _updateOrder() async {
    if (!_canUpdateOrder()) {
      final l10n = AppLocalizations.of(context)!;
      AppWidgets.showFlushbar(
        context,
        l10n.canOnlyUpdateTodayOrders,
        type: MessageType.warning,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.pleaseSelectAtLeastOneService,
          type: MessageType.warning);
      return;
    }

    // Validate delivery requirements
    if (_deliveryOption == 'delivery') {
      // For delivery, require full customer information
      if (_customerNameController.text.trim().isEmpty ||
          _customerPhoneController.text.trim().isEmpty ||
          widget.order.customerAddress == null ||
          widget.order.customerAddress!.isEmpty) {
        AppWidgets.showFlushbar(context,
            'Vui lòng nhập đầy đủ thông tin khách hàng (tên, số điện thoại, địa chỉ) để giao hàng tại nhà',
            type: MessageType.warning);
        return;
      }

      // For delivery, require at least one delivery employee
      if (_selectedEmployees.isEmpty) {
        AppWidgets.showFlushbar(
            context, 'Vui lòng chọn ít nhất một nhân viên giao hàng',
            type: MessageType.warning);
        return;
      }
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

      // Update the order
      final updatedOrder = Order(
        id: widget.order.id, // Keep the same ID
        customerPhone: customerPhone,
        customerName: customerName,
        customerAddress: widget.order.customerAddress, // Keep original address
        employeeIds: _selectedEmployees.map((e) => e.id).toList(),
        employeeNames: _selectedEmployees.map((e) => e.name).toList(),
        serviceIds: _selectedServices.map((swq) => swq.service.id).toList(),
        serviceNames: _selectedServices.map((swq) => swq.service.name).toList(),
        serviceQuantities:
            _selectedServices.map((swq) => swq.quantity).toList(),
        totalPrice: _finalTotalPrice,
        discountPercent: _discountPercent,
        tip: _tip,
        taxPercent: _taxPercent,
        shippingFee: _shippingFee, // Use updated shipping fee
        createdAt: widget.order.createdAt, // Keep original creation date
        isPaid: _isPaid,
        isBooking: widget.order.isBooking, // Keep original booking status
        deliveryMethod: _deliveryOption, // Use selected delivery method
        deliveryStatus: _deliveryOption == 'delivery'
            ? 'pending'
            : '', // Set delivery status based on delivery method
      );

      // Validate order data
      if (updatedOrder.serviceIds.isEmpty ||
          updatedOrder.serviceNames.isEmpty) {
        final l10n = AppLocalizations.of(context)!;
        throw Exception(l10n.invalidServiceData);
      }

      // Update order
      await widget.api.updateOrder(updatedOrder);

      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.orderUpdatedSuccessfully,
          type: MessageType.success);

      // Call the callback after a delay to ensure UI updates are processed
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onOrderUpdated?.call();
      });

      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.errorUpdatingOrder(e.toString()),
          type: MessageType.error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        // Close dropdowns when tapping outside
        if (_showEmployeeDropdown) {
          setState(() {
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
                            Icons.edit,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.updateOrder,
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
                          if (!_canUpdateOrder()) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                l10n.canOnlyUpdateTodayOrders,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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

                    // Delivery Option Section
                    _buildSectionCard(
                      title: l10n.deliveryOption,
                      icon: Icons.local_shipping,
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(l10n.pickupAtSalon),
                            value: 'pickup',
                            groupValue: _deliveryOption,
                            onChanged: (value) {
                              if (value != null) {
                                _onDeliveryOptionChanged(value);
                              }
                            },
                            activeColor: const Color(0xFF667eea),
                          ),
                          RadioListTile<String>(
                            title: Text(l10n.homeDelivery),
                            value: 'delivery',
                            groupValue: _deliveryOption,
                            onChanged: (value) {
                              if (value != null) {
                                _onDeliveryOptionChanged(value);
                              }
                            },
                            activeColor: const Color(0xFF667eea),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Employee Information - optional selection
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
                          GestureDetector(
                            onTap: _toggleEmployeeDropdown,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedEmployees.isEmpty
                                        ? l10n.selectEmployee
                                        : l10n.employeesSelected(
                                            _selectedEmployees.length),
                                    style: TextStyle(
                                      color: _selectedEmployees.isEmpty
                                          ? Colors.grey[600]
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    _showEmployeeDropdown
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showEmployeeDropdown) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
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
                    ),

                    const SizedBox(height: 16),

                    // Category Selection
                    _buildSectionCard(
                      title: l10n.serviceCategories,
                      icon: Icons.category,
                      child: Column(
                        children: [
                          // Categories Carousel
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategories.contains(category);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildCompactCategoryCard(
                                      category, isSelected),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Services Selection
                    _buildSectionCard(
                      title: l10n.services,
                      icon: Icons.shopping_cart,
                      child: Column(
                        children: [
                          // Selected Services Chips
                          if (_selectedServices.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _selectedServices.map((serviceWithQuantity) {
                                return _buildServiceChipWithQuantity(
                                  serviceWithQuantity: serviceWithQuantity,
                                  onDeleted: () => _removeSelectedService(
                                      serviceWithQuantity),
                                  onIncrease: () => _increaseServiceQuantity(
                                      serviceWithQuantity),
                                  onDecrease: () => _decreaseServiceQuantity(
                                      serviceWithQuantity),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Services Grid - chỉ hiển thị khi đã chọn category
                          if (_selectedCategories.isNotEmpty) ...[
                            _buildCompactServicesGrid(),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .pleaseSelectAtLeastOneCategory,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Selected Services Details Section
                    if (_selectedServices.isNotEmpty)
                      _buildSectionCard(
                        title: l10n.servicesSelected(_selectedServices.length),
                        icon: Icons.shopping_cart,
                        child: Column(
                          children: [
                            // Services list
                            ...(_selectedServices.map((serviceWithQuantity) =>
                                _buildSelectedServiceItem(
                                    serviceWithQuantity))),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            // Total price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.subtotal,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_formatPrice(_totalPrice)}₫',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF667eea),
                                  ),
                                ),
                              ],
                            ),
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

                    // Tax Section
                    _buildSectionCard(
                      title: l10n.tax,
                      icon: Icons.receipt,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
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
                              onChanged: (value) => _onTaxChanged(),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final tax = double.tryParse(value);
                                  if (tax == null || tax < 0 || tax > 100) {
                                    return l10n.taxMustBe0To100;
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
                              l10n.taxAmount(_formatPrice(
                                  (_totalPrice * (1 - _discountPercent / 100)) *
                                      _taxPercent /
                                      100)),
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

                    // Shipping Fee Section
                    _buildSectionCard(
                      title: l10n.shippingFee,
                      icon: Icons.local_shipping,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shippingFeeController,
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
                              onChanged: (value) => _onShippingFeeChanged(),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final shippingFee = double.tryParse(value);
                                  if (shippingFee == null || shippingFee < 0) {
                                    return l10n.shippingFeeMustBeGreaterThan0;
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
                              l10n.shippingFeeAmount(
                                  _formatPrice(_shippingFee)),
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

                    // Payment Status Section
                    _buildSectionCard(
                      title: l10n.paymentStatus,
                      icon: Icons.payment,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isPaid ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _isPaid ? Colors.green[300]! : Colors.red[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPaid ? Icons.check_circle : Icons.pending,
                              color:
                                  _isPaid ? Colors.green[600] : Colors.red[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPaid ? l10n.paid : l10n.unpaid,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isPaid
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                  Text(
                                    _isPaid
                                        ? l10n.customerPaidFully
                                        : l10n.customerNotPaid,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isPaid
                                          ? Colors.green[600]
                                          : Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPaid,
                              onChanged: (value) {
                                setState(() {
                                  _isPaid = value;
                                });
                              },
                              activeThumbColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              inactiveTrackColor: Colors.red[200],
                            ),
                          ],
                        ),
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
                                '${_formatPrice(_totalPrice)} ${l10n.vnd}',
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
                                  l10n.discountPercent(
                                      _discountPercent.toStringAsFixed(0)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '-${_formatPrice(_totalPrice * _discountPercent / 100)} ${l10n.vnd}',
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
                                  '+${_formatPrice(_tip)} ${l10n.vnd}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_taxPercent > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.taxLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '+${_formatPrice((_totalPrice * (1 - _discountPercent / 100)) * _taxPercent / 100)} ${l10n.vnd}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_shippingFee > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.shippingFeeLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '+${_formatPrice(_shippingFee)} ${l10n.vnd}',
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
                                l10n.totalPaymentLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_formatPrice(_finalTotalPrice)} ${l10n.vnd}',
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
                            onPressed: _isLoading || !_canUpdateOrder()
                                ? null
                                : _updateOrder,
                            isLoading: _isLoading,
                            label: l10n.save,
                            icon: Icons.save,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSecondaryButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (widget.onCancel != null) {
                                      widget.onCancel!();
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                            label: l10n.cancel,
                            icon: Icons.close,
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

  Widget _buildServiceChipWithQuantity({
    required ServiceWithQuantity serviceWithQuantity,
    required VoidCallback onDeleted,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF764ba2), Color(0xFF667eea)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF764ba2).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Service name
          Flexible(
            child: Text(
              serviceWithQuantity.service.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease button
                GestureDetector(
                  onTap: onDecrease,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: serviceWithQuantity.quantity > 1
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: serviceWithQuantity.quantity > 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ),
                ),
                // Quantity display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${serviceWithQuantity.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Increase button
                GestureDetector(
                  onTap: onIncrease,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          GestureDetector(
            onTap: onDeleted,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
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

  Widget _buildCompactCategoryCard(Category category, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategoryToggled(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                          ]
                        : [
                            Colors.grey[300]!,
                            Colors.grey[400]!,
                          ],
                  ),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? _buildImageWidget(category.image!)
                    : _buildCompactCategoryImagePlaceholder(),
              ),

              // Overlay for better text readability
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),

              // Category name
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF667eea),
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactServicesGrid() {
    // Filter services based on selected categories
    List<Service> visibleServices = _services;
    if (_selectedCategories.isNotEmpty) {
      visibleServices = _services
          .where((service) => _selectedCategories
              .any((category) => category.id == service.categoryId))
          .toList();
    }

    // Sort services by category name, then by price
    visibleServices.sort((a, b) {
      final categoryA = _categories.firstWhere(
        (cat) => cat.id == a.categoryId,
        orElse: () => Category(id: '', name: ''),
      );
      final categoryB = _categories.firstWhere(
        (cat) => cat.id == b.categoryId,
        orElse: () => Category(id: '', name: ''),
      );

      final categoryComparison = categoryA.name.compareTo(categoryB.name);
      if (categoryComparison != 0) {
        return categoryComparison;
      }
      return a.price.compareTo(b.price);
    });

    // Use maxCrossAxisExtent to maintain consistent item size across all devices
    // This ensures service items maintain mobile-like size on tablet/desktop
    const double maxItemWidth =
        120.0; // Maximum width for each service item (mobile-like size)

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxItemWidth, // Maximum width for each item
        childAspectRatio: 0.75, // Slightly taller to accommodate text
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: visibleServices.length,
      itemBuilder: (context, index) {
        final service = visibleServices[index];
        final isSelected = _selectedServices.any((serviceWithQuantity) =>
            serviceWithQuantity.service.id == service.id);
        return _buildCompactServiceCard(service, isSelected);
      },
    );
  }

  Widget _buildCompactServiceCard(Service service, bool isSelected) {
    final category = _categories.firstWhere(
      (cat) => cat.id == service.categoryId,
      orElse: () => Category(id: '', name: ''),
    );

    return GestureDetector(
      onTap: () => _onServiceToggled(service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF667eea).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: service.image != null && service.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            child: _buildImageWidget(service.image!),
                          )
                        : _buildCompactServiceImagePlaceholder(),
                  ),
                ),

                // Service info - Fixed height container to prevent overflow
                Container(
                  height: 65, // Fixed height to prevent overflow
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Service name - Limited space
                      Expanded(
                        flex: 2,
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Category name
                      Expanded(
                        flex: 1,
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Price
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${_formatPrice(service.price)}₫',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF667eea)
                                : Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.3),
            const Color(0xFF764ba2).withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Icon(
        Icons.category,
        size: 24,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildCompactServiceImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Icon(
        Icons.shopping_cart,
        size: 20,
        color: Colors.grey[400],
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

  Widget _buildSelectedServiceItem(ServiceWithQuantity serviceWithQuantity) {
    final category = _categories.firstWhere(
      (cat) => cat.id == serviceWithQuantity.service.categoryId,
      orElse: () => Category(id: '', name: ''),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Image, Info, Remove button
          Row(
            children: [
              // Service image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: serviceWithQuantity.service.image != null &&
                        serviceWithQuantity.service.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(
                            serviceWithQuantity.service.image!),
                      )
                    : Icon(
                        Icons.shopping_cart,
                        color: Colors.grey[400],
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),

              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceWithQuantity.service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(serviceWithQuantity.service.price)}₫',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF667eea),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Remove button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _removeSelectedService(serviceWithQuantity),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom row: Quantity controls and total price
          Row(
            children: [
              // Quantity label and controls
              Row(
                children: [
                  Text(
                    'Số lượng',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantity controls
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrease button
                        Container(
                          decoration: BoxDecoration(
                            color: serviceWithQuantity.quantity > 1
                                ? const Color(0xFF667eea).withValues(alpha: 0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: serviceWithQuantity.quantity > 1
                                ? () => _decreaseServiceQuantity(
                                    serviceWithQuantity)
                                : null,
                            icon: const Icon(Icons.remove),
                            color: serviceWithQuantity.quantity > 1
                                ? const Color(0xFF667eea)
                                : Colors.grey[400],
                            iconSize: 18,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),

                        // Quantity display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${serviceWithQuantity.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Increase button
                        Container(
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF667eea).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _increaseServiceQuantity(serviceWithQuantity),
                            icon: const Icon(Icons.add),
                            color: const Color(0xFF667eea),
                            iconSize: 18,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Total price for this service
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tổng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_formatPrice(serviceWithQuantity.totalPrice)}₫',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF667eea),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

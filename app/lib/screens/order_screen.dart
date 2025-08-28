import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/bill_helper.dart';
import '../config/salon_config.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.api, this.onOrderCreated});

  final ApiClient api;
  final VoidCallback? onOrderCreated;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

enum MessageType { success, error, info, warning }

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerPhoneController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _employeeNameController = TextEditingController();
  
  List<Category> _categories = [];
  List<Service> _selectedServices = [];
  List<Category> _selectedCategories = [];
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  double _totalPrice = 0.0;
  bool _isLoading = false;
  bool _showCategoryDropdown = false;
  bool _showServiceDropdown = false;
  bool _showEmployeeDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadEmployees();
    
    // Add listeners for auto-search
    _customerPhoneController.addListener(_onCustomerPhoneChanged);
    _employeePhoneController.addListener(_onEmployeePhoneChanged);
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

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onCustomerPhoneChanged);
    _employeePhoneController.removeListener(_onEmployeePhoneChanged);
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    _employeePhoneController.dispose();
    _employeeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      showFlushbar('Lỗi tải danh mục: $e', type: MessageType.error);
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await widget.api.getEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      showFlushbar('Lỗi tải danh sách nhân viên: $e', type: MessageType.error);
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
          showFlushbar('Đã tìm thấy khách hàng: ${customer.name}', type: MessageType.success);
        } else {
          setState(() {
            _customerNameController.clear();
          });
          showFlushbar('Không tìm thấy khách hàng với số điện thoại này. Vui lòng nhập tên để tạo mới.', type: MessageType.info);
        }
      } catch (e) {
        showFlushbar('Lỗi tìm kiếm khách hàng: $e', type: MessageType.error);
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
          showFlushbar('Đã tìm thấy nhân viên: ${employee.name}', type: MessageType.success);
        } else {
          setState(() {
            _employeeNameController.clear();
          });
          showFlushbar('Không tìm thấy nhân viên với số điện thoại này. Vui lòng nhập tên để tạo mới.', type: MessageType.info);
        }
      } catch (e) {
        showFlushbar('Lỗi tìm kiếm nhân viên: $e', type: MessageType.error);
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

  void _onCategoryToggled(Category category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        // Remove all services from this category
        _selectedServices.removeWhere((service) => service.categoryId == category.id);
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
        final category = _categories.firstWhere((c) => c.id == service.categoryId);
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
      _selectedServices.removeWhere((service) => service.categoryId == category.id);
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
    _totalPrice = _selectedServices.fold(0.0, (sum, service) => sum + service.price);
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      showFlushbar('Vui lòng chọn ít nhất một dịch vụ', type: MessageType.warning);
      return;
    }
    if (_selectedEmployees.isEmpty) {
      showFlushbar('Vui lòng chọn ít nhất một nhân viên', type: MessageType.warning);
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
        await widget.api.createCustomer(Customer(phone: customerPhone, name: customerName));
      }

      // Create orders for each selected employee
      List<Order> createdOrders = [];
      if (_selectedCategories.isNotEmpty && _selectedServices.isNotEmpty) {
        for (final employee in _selectedEmployees) {
          final order = Order(
            id: '00000000-0000-0000-0000-000000000000', // Guid.Empty - will be replaced by server
            customerPhone: customerPhone,
            customerName: customerName,
            employeeId: employee.id,
            employeeName: employee.name,
            categoryIds: _selectedCategories.map((c) => c.id).toList(),
            categoryName: _selectedCategories.map((c) => c.name).join(', '), // Combine all category names
            serviceIds: _selectedServices.map((s) => s.id).toList(),
            serviceNames: _selectedServices.map((s) => s.name).toList(),
            totalPrice: _totalPrice,
            createdAt: DateTime.now(),
          );

          // Validate order data
          if (order.serviceIds.isEmpty || order.serviceNames.isEmpty) {
            throw Exception('Dữ liệu dịch vụ không hợp lệ');
          }

          // Create order and get the response with real ID
          final createdOrder = await widget.api.createOrder(order);
          createdOrders.add(createdOrder);
        }
      }
      
      showFlushbar('Đã tạo đơn thành công!', type: MessageType.success);
      
      // Create a backup of selected services before showing bills
      final selectedServicesBackup = List<Service>.from(_selectedServices);
      
      // Show bill for each created order using the real order data
      for (final createdOrder in createdOrders) {
        // Show bill dialog with the real order data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Create services list from the backup data
          final servicesForBill = selectedServicesBackup.where((service) => 
            createdOrder.serviceIds.contains(service.id)
          ).toList();
          
          BillHelper.showBillDialog(
            context: context,
            order: createdOrder,
            services: servicesForBill,
            salonName: SalonConfig.salonName,
            salonAddress: SalonConfig.salonAddress,
            salonPhone: SalonConfig.salonPhone,
          );
        });
      }
      
      // Call the callback after a delay to ensure bills are shown first
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onOrderCreated?.call();
      });
      
      // Reset form after showing bills and calling callback
      Future.delayed(const Duration(milliseconds: 1500), () {
        _resetForm();
      });
    } catch (e) {
      showFlushbar('Lỗi tạo đơn: $e', type: MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _customerPhoneController.clear();
    _customerNameController.clear();
    _employeePhoneController.clear();
    _employeeNameController.clear();
    setState(() {
      _selectedCategories.clear();
      _selectedServices.clear();
      _selectedEmployees.clear();
      _totalPrice = 0.0;
      _showCategoryDropdown = false;
      _showServiceDropdown = false;
      _showEmployeeDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close dropdowns when tapping outside
        if (_showCategoryDropdown || _showServiceDropdown || _showEmployeeDropdown) {
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
                        const Text(
                          'Tạo đơn mới',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedServices.length} dịch vụ đã chọn',
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
                    title: 'Thông tin khách hàng',
                    icon: Icons.person,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _customerPhoneController,
                          label: 'Số điện thoại',
                          prefixIcon: Icons.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _customerNameController,
                          label: 'Tên khách hàng',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên khách hàng';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Employee Information
                  _buildSectionCard(
                    title: 'Thông tin nhân viên',
                    icon: Icons.work,
                    child: Column(
                      children: [
                        // Selected Employees Chips
                        if (_selectedEmployees.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedEmployees.map((employee) => _buildChip(
                              label: employee.name,
                              onDeleted: () => _toggleEmployee(employee),
                              color: const Color(0xFF667eea),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Employee Dropdown
                        _buildDropdownButton(
                          onTap: _toggleEmployeeDropdown,
                          label: _selectedEmployees.isEmpty 
                              ? 'Chọn nhân viên' 
                              : '${_selectedEmployees.length} nhân viên đã chọn',
                          isExpanded: _showEmployeeDropdown,
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
                                final isSelected = _selectedEmployees.contains(employee);
                                return _buildDropdownItem(
                                  title: employee.name,
                                  subtitle: employee.phone ?? '',
                                  isSelected: isSelected,
                                  onTap: () => _toggleEmployee(employee),
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
                    title: 'Danh mục dịch vụ',
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
                                onDeleted: () => _removeSelectedCategory(category),
                                color: const Color(0xFF667eea),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Dropdown
                        _buildDropdownButton(
                          onTap: _toggleCategoryDropdown,
                          label: _selectedCategories.isEmpty 
                              ? 'Chọn danh mục' 
                              : '${_selectedCategories.length} danh mục đã chọn',
                          isExpanded: _showCategoryDropdown,
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
                                final isSelected = _selectedCategories.contains(category);
                                return _buildDropdownItem(
                                  title: category.name,
                                  isSelected: isSelected,
                                  onTap: () => _onCategoryToggled(category),
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
                    title: 'Dịch vụ',
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
                                onDeleted: () => _removeSelectedService(service),
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
                              ? 'Chọn dịch vụ' 
                              : '${_selectedServices.length} dịch vụ đã chọn',
                          isExpanded: _showServiceDropdown,
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
                                final visibleCategories = _selectedCategories.isEmpty
                                    ? _categories
                                    : _selectedCategories;
                                final category = visibleCategories[categoryIndex];
                                final categoryServices = category.items;
                                
                                if (categoryServices.isEmpty) return const SizedBox.shrink();
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      final isSelected = _selectedServices.contains(service);
                                      return _buildDropdownItem(
                                        title: service.name,
                                        subtitle: '${_formatPrice(service.price)} VNĐ',
                                        isSelected: isSelected,
                                        onTap: () => _onServiceToggled(service),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_formatPrice(_totalPrice)} VNĐ',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                          label: 'Tạo đơn',
                          icon: Icons.check,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSecondaryButton(
                          onPressed: _isLoading ? null : _resetForm,
                          label: 'Làm mới',
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
            color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFF667eea).withOpacity(0.1),
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildChip({
    required String label,
    required VoidCallback onDeleted,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
                color: label.contains('Chọn') ? Colors.grey[600] : Colors.black,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDropdownItem({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      tileColor: isSelected ? const Color(0xFF667eea).withOpacity(0.1) : null,
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
            color: const Color(0xFF667eea).withOpacity(0.3),
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

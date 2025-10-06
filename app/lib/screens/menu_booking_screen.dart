import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import '../ui/bill_helper.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/notification_service.dart';

class MenuScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback? onLogout;
  final VoidCallback? onOrderCreated;

  const MenuScreen(
      {super.key, required this.api, this.onLogout, this.onOrderCreated});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  List<Category> _categories = [];
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  // Booking functionality
  List<ServiceWithQuantity> _selectedServices = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  String _deliveryOption = 'pickup'; // 'pickup' or 'delivery'
  bool _showBookingForm = false;
  bool _isCreatingBooking = false;

  // Customer phone dropdown
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _showCustomerDropdown = false;

  // Notification service
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadData();
    _loadCustomers();
    // Initialize notification service with API client
    _notificationService.initialize(apiClient: widget.api);
    // Add listener for auto-search
    _customerPhoneController.addListener(_onCustomerPhoneChanged);
  }

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onCustomerPhoneChanged);
    _animationController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get salon name from SharedPreferences for booking user
      final prefs = await SharedPreferences.getInstance();
      final salonName = prefs.getString('salon_name') ?? '';

      if (salonName.isEmpty) {
        throw Exception('Salon name not found');
      }

      // Use booking-specific API methods for booking user
      final categories = await widget.api.getCategoriesForBooking(salonName);
      final services = await widget.api.getServicesForBooking(salonName);

      setState(() {
        // Sort categories alphabetically by name
        categories.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _categories = categories;

        // Sort services by price from low to high
        services.sort((a, b) => a.price.compareTo(b.price));
        _services = services;
        _filteredServices = services;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorLoadingData(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      // Get salon name from SharedPreferences for booking user
      final prefs = await SharedPreferences.getInstance();
      final salonName = prefs.getString('salon_name') ?? '';

      if (salonName.isEmpty) {
        throw Exception('Salon name not found');
      }

      // Use booking-specific API method for booking user
      final customers = await widget.api.getCustomersForBooking(salonName);
      setState(() {
        _allCustomers = customers;

        // Add some test customers if list is empty (for testing purposes)
        if (_allCustomers.isEmpty) {
          _allCustomers = [
            Customer(
                phone: '0123456789',
                name: 'Nguyễn Văn A',
                address: '123 Đường ABC'),
            Customer(
                phone: '0987654321',
                name: 'Trần Thị B',
                address: '456 Đường XYZ'),
            Customer(
                phone: '0111222333',
                name: 'Lê Văn C',
                address: '789 Đường DEF'),
          ];
        }
      });
    } catch (e) {
      // Add test customers for demo when API fails
      setState(() {
        _allCustomers = [
          Customer(
              phone: '0123456789',
              name: 'Nguyễn Văn A',
              address: '123 Đường ABC'),
          Customer(
              phone: '0987654321',
              name: 'Trần Thị B',
              address: '456 Đường XYZ'),
          Customer(
              phone: '0111222333', name: 'Lê Văn C', address: '789 Đường DEF'),
        ];
      });
    }
  }

  Future<void> _findCustomerByPhone() async {
    final phone = _customerPhoneController.text.trim();
    if (phone.length == 10) {
      try {
        // Get salon name from SharedPreferences for booking user
        final prefs = await SharedPreferences.getInstance();
        final salonName = prefs.getString('salon_name') ?? '';

        if (salonName.isEmpty) {
          throw Exception('Salon name not found');
        }

        // Use booking-specific API method for booking user
        final customer =
            await widget.api.findCustomerByPhoneForBooking(phone, salonName);
        if (customer != null) {
          setState(() {
            _customerNameController.text = customer.name;
            _customerAddressController.text = customer.address ?? '';
          });
          AppWidgets.showFlushbar(context,
              AppLocalizations.of(context)!.customerFound(customer.name),
              type: MessageType.success);
        } else {
          setState(() {
            _customerNameController.clear();
            _customerAddressController.clear();
          });
          AppWidgets.showFlushbar(
              context, AppLocalizations.of(context)!.customerNotFound,
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
        _customerAddressController.clear();
      });
    }
  }

  void _onCustomerPhoneChanged() {
    final phone = _customerPhoneController.text.trim();

    // Filter customers based on phone input
    if (phone.length >= 3) {
      setState(() {
        _filteredCustomers = _allCustomers
            .where((customer) {
              final customerPhone =
                  customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
              final inputPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
              return customerPhone.contains(inputPhone) ||
                  customer.name.toLowerCase().contains(phone.toLowerCase());
            })
            .take(10)
            .toList(); // Limit to 10 results for better performance

        _showCustomerDropdown = _filteredCustomers.isNotEmpty;
      });
    } else {
      setState(() {
        _showCustomerDropdown = false;
        _filteredCustomers.clear();
      });
    }

    // Auto-fill customer info for exact phone match
    if (phone.length == 10) {
      final exactMatch = _allCustomers.firstWhere(
        (customer) => customer.phone.replaceAll(RegExp(r'[^0-9]'), '') == phone,
        orElse: () => Customer(phone: '', name: ''),
      );

      if (exactMatch.phone.isNotEmpty) {
        setState(() {
          _customerNameController.text = exactMatch.name;
          _customerAddressController.text = exactMatch.address ?? '';
          _showCustomerDropdown = false;
        });
        AppWidgets.showFlushbar(
            context, 'Đã tìm thấy khách hàng: ${exactMatch.name}',
            type: MessageType.success);
      } else {
        // Try API search as fallback
        _findCustomerByPhone();
      }
    } else if (phone.length < 10) {
      // Clear customer name if phone is less than 10 digits
      setState(() {
        _customerNameController.clear();
        _customerAddressController.clear();
      });
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _customerPhoneController.text = customer.phone;
      _customerNameController.text = customer.name;
      _customerAddressController.text = customer.address ?? '';
      _showCustomerDropdown = false;
    });
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterServices();
    });
  }

  void _filterServices() {
    List<Service> filtered = _services;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((service) =>
              service.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by selected category
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((service) => service.categoryId == _selectedCategoryId)
          .toList();
    }

    // Sort services: first by category name, then by price from low to high
    filtered.sort((a, b) {
      // First sort by category name
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

      // If same category, sort by price from low to high
      return a.price.compareTo(b.price);
    });

    setState(() {
      _filteredServices = filtered;
    });
  }

  void _onCategorySelected(Category category) {
    HapticFeedback.lightImpact();
    setState(() {
      // Toggle category selection - nếu đã chọn thì bỏ chọn
      if (_selectedCategoryId == category.id) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = category.id;
      }
    });
    _filterServices();
  }

  void _clearCategoryFilter() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = null;
    });
    _filterServices();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
    _searchController.clear(); // Clear the text field
    _filterServices();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty && _selectedCategoryId != null) {
      final category = _categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => Category(
            id: '', name: AppLocalizations.of(context)!.unknownCategory),
      );
      return AppLocalizations.of(context)!
          .noServicesFoundWithSearchAndCategory(_searchQuery, category.name);
    } else if (_searchQuery.isNotEmpty) {
      return AppLocalizations.of(context)!
          .noServicesFoundWithSearch(_searchQuery);
    } else if (_selectedCategoryId != null) {
      final category = _categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => Category(
            id: '', name: AppLocalizations.of(context)!.unknownCategory),
      );
      return AppLocalizations.of(context)!.noServicesInCategory(category.name);
    } else {
      return AppLocalizations.of(context)!.noServicesYet;
    }
  }

  void _onServiceToggled(Service service) {
    setState(() {
      final existingServiceIndex = _selectedServices.indexWhere(
          (serviceWithQuantity) =>
              serviceWithQuantity.service.id == service.id);

      if (existingServiceIndex != -1) {
        _selectedServices.removeAt(existingServiceIndex);
      } else {
        _selectedServices
            .add(ServiceWithQuantity(service: service, quantity: 1));
      }
    });
  }

  double get _totalPrice {
    return _selectedServices.fold(0.0,
        (sum, serviceWithQuantity) => sum + serviceWithQuantity.totalPrice);
  }

  void _increaseServiceQuantity(ServiceWithQuantity serviceWithQuantity) {
    setState(() {
      serviceWithQuantity.quantity++;
    });
  }

  void _decreaseServiceQuantity(ServiceWithQuantity serviceWithQuantity) {
    setState(() {
      if (serviceWithQuantity.quantity > 1) {
        serviceWithQuantity.quantity--;
      }
    });
  }

  void _removeSelectedService(ServiceWithQuantity serviceWithQuantity) {
    setState(() {
      _selectedServices.remove(serviceWithQuantity);
    });
  }

  void _showBookingFormDialog() {
    setState(() {
      _showBookingForm = true;
    });
  }

  void _hideBookingForm() {
    setState(() {
      _showBookingForm = false;
    });
  }

  Future<void> _createBooking() async {
    if (_selectedServices.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.pleaseSelectAtLeastOneService,
          type: MessageType.warning);
      return;
    }

    // Handle customer info based on delivery method
    String customerName = _customerNameController.text.trim();
    String customerPhone = _customerPhoneController.text.trim();

    if (_deliveryOption == 'delivery') {
      // For delivery, require full customer information
      if (customerName.isEmpty ||
          customerPhone.isEmpty ||
          _customerAddressController.text.trim().isEmpty) {
        AppWidgets.showFlushbar(context,
            'Vui lòng nhập đầy đủ thông tin khách hàng (tên, số điện thoại, địa chỉ) để giao hàng tại nhà',
            type: MessageType.warning);
        return;
      }
    } else {
      // For pickup, generate fake customer info if name or phone is empty
      if (customerName.isEmpty || customerPhone.isEmpty) {
        // Generate fake customer info
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        customerName = customerName.isEmpty
            ? 'Khách hàng ${timestamp.toString().substring(8)}'
            : customerName;
        // Generate a 10-digit phone number starting with '0'
        if (customerPhone.isEmpty) {
          // Ensure the generated number is always 10 digits
          final timestampStr = timestamp.toString();
          // Take the last 9 digits of the timestamp (pad left if needed)
          final last9Digits = timestampStr.length >= 9
              ? timestampStr.substring(timestampStr.length - 9)
              : timestampStr.padLeft(9, '0');
          customerPhone = '0$last9Digits';
        }

        // Update the text fields to show the generated info
        setState(() {
          _customerNameController.text = customerName;
          _customerPhoneController.text = customerPhone;
        });
      }
    }

    setState(() {
      _isCreatingBooking = true;
    });

    try {
      // Get salon name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final salonName = prefs.getString('salon_name') ?? '';

      if (salonName.isEmpty) {
        throw Exception('Salon name not found');
      }

      // Create lists for order data
      final serviceIds = _selectedServices.map((s) => s.service.id).toList();
      final serviceNames =
          _selectedServices.map((s) => s.service.name).toList();
      final serviceQuantities =
          _selectedServices.map((s) => s.quantity).toList();

      // Calculate total price
      final totalPrice = _selectedServices.fold<double>(
        0.0,
        (sum, serviceWithQuantity) =>
            sum +
            (serviceWithQuantity.service.price * serviceWithQuantity.quantity),
      );

      // Create booking order
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: _customerAddressController.text.trim().isNotEmpty
            ? _customerAddressController.text.trim()
            : null,
        employeeIds: [], // No employees for booking
        employeeNames: [], // No employees for booking
        serviceIds: serviceIds,
        serviceNames: serviceNames,
        serviceQuantities: serviceQuantities,
        totalPrice: totalPrice,
        createdAt: DateTime.now(),
        isPaid: false,
        isBooking: true, // This is a booking order
        deliveryMethod: _deliveryOption, // Use the selected delivery option
      );

      // Create the booking order using booking-specific API
      final createdOrder =
          await widget.api.createBookingOrder(order, salonName);

      // Show success message
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.bookingSuccessful,
          type: MessageType.success);

      // Notification is automatically created by backend when booking order is created
      // No need to send notification from client side

      // Show bill dialog instead of confirmation
      await BillHelper.showBillDialog(
        context: context,
        order: createdOrder,
        servicesWithQuantity: _selectedServices,
        api: widget.api,
      );

      // Call the callback to refresh dashboard stats
      widget.onOrderCreated?.call();

      // Reset form
      _resetBookingForm();
    } catch (e) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.bookingFailed,
          type: MessageType.error);
    } finally {
      setState(() {
        _isCreatingBooking = false;
      });
    }
  }

  void _resetBookingForm() {
    setState(() {
      _selectedServices.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerAddressController.clear();
      _deliveryOption = 'pickup';
      _showBookingForm = false;
    });
  }

  void _handleLogout() {
    if (widget.onLogout != null) {
      widget.onLogout!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close dropdowns when tapping outside
        if (_showCustomerDropdown) {
          setState(() {
            _showCustomerDropdown = false;
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
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header với search bar
                        Column(
                          children: [
                            _buildFullWidthHeader(),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildSearchBar(),
                            ),
                          ],
                        ),

                        // Categories carousel
                        _buildCategoriesSection(),

                        // Services grid
                        _buildServicesSection(),
                      ],
                    ),
                  ),

                  // Logout button positioned above header on the right
                  if (widget.onLogout != null)
                    Positioned(
                      top: 10,
                      right: 20,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _handleLogout,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.exit_to_app,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Floating booking button
                  if (_selectedServices.isNotEmpty)
                    _buildFloatingBookingButton(),

                  // Booking form overlay
                  if (_showBookingForm) _buildBookingFormOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, color: Colors.white, size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              AppLocalizations.of(context)!.bookingScreenTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: AppTheme.controlHeight,
      child: TextField(
        controller: _searchController,
        textAlignVertical: TextAlignVertical.center,
        onChanged: _onSearchChanged,
        decoration: AppTheme.inputDecoration(
          label: AppLocalizations.of(context)!.searchServicesPlaceholder,
          prefixIcon: Icons.search,
        ).copyWith(
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                  ),
                  onPressed: _clearSearch,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noCategoriesYet,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: AppTheme.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with navigation arrows
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.categoriesSection,
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 24,
                          desktop: 28,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (_selectedCategoryId != null)
                      Text(
                        AppLocalizations.of(context)!
                            .servicesCount(_filteredServices.length),
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: AppTheme.primaryStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedCategoryId != null)
                      TextButton(
                        onPressed: _clearCategoryFilter,
                        child: Text(
                          AppLocalizations.of(context)!.clearFilter,
                          style: TextStyle(
                            color: AppTheme.primaryStart,
                            fontSize: AppTheme.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: AppTheme.getResponsiveSpacing(
                        context,
                        mobile: 8,
                        tablet: 12,
                        desktop: 16,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .categoriesCount(_categories.length),
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: AppTheme.primaryStart,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(
            height: AppTheme.getResponsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),

          // Categories carousel
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryId == category.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildCategoryCard(category, isSelected),
                );
              },
            ),
          ),

          SizedBox(
            height: AppTheme.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Background image or gradient
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [
                            AppTheme.primaryStart,
                            AppTheme.primaryEnd,
                          ]
                        : [
                            Colors.grey[300]!,
                            Colors.grey[400]!,
                          ],
                  ),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? _buildImageWidget(category.image!)
                    : _buildCategoryImagePlaceholder(),
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

              // Category name label
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildServicesSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategoryId != null
                  ? Icons.category_outlined
                  : Icons.search_off,
              size: AppTheme.getResponsiveFontSize(
                context,
                mobile: 48,
                tablet: 56,
                desktop: 64,
              ),
              color: Colors.grey[400],
            ),
            SizedBox(
              height: AppTheme.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedCategoryId != null || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    _clearSearch();
                    _clearCategoryFilter();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.viewAllServices,
                    style: TextStyle(
                      color: AppTheme.primaryStart,
                      fontSize: AppTheme.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Services section title
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.servicesSection,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (_filteredServices.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .servicesCount(_filteredServices.length),
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: AppTheme.primaryStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          SizedBox(
            height: AppTheme.getResponsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),

          // Services grouped by category
          _buildGroupedServices(),
        ],
      ),
    );
  }

  Widget _buildGroupedServices() {
    // Group services by category
    final Map<String, List<Service>> groupedServices = {};
    for (final service in _filteredServices) {
      final categoryId = service.categoryId;
      if (!groupedServices.containsKey(categoryId)) {
        groupedServices[categoryId] = [];
      }
      groupedServices[categoryId]!.add(service);
    }

    // Sort categories by name
    final sortedCategories = groupedServices.keys.toList()
      ..sort((a, b) {
        final categoryA = _categories.firstWhere(
          (cat) => cat.id == a,
          orElse: () => Category(id: '', name: ''),
        );
        final categoryB = _categories.firstWhere(
          (cat) => cat.id == b,
          orElse: () => Category(id: '', name: ''),
        );
        return categoryA.name.compareTo(categoryB.name);
      });

    return Column(
      children: sortedCategories.map((categoryId) {
        final services = groupedServices[categoryId]!
          ..sort((a, b) => a.price.compareTo(
              b.price)); // Sort services by price within each category
        final category = _categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => Category(
              id: '', name: AppLocalizations.of(context)!.unknownCategory),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
                vertical: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryStart,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    width: AppTheme.getResponsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(
                    width: AppTheme.getResponsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${services.length}',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: AppTheme.primaryStart,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Services grid for this category
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppTheme.isMobile(context) ? 2 : 3,
                childAspectRatio: 0.75, // Slightly taller to accommodate text
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: services.length,
              itemBuilder: (context, serviceIndex) {
                final service = services[serviceIndex];
                return _buildServiceCard(service);
              },
            ),

            // Spacing between categories
            if (sortedCategories.indexOf(categoryId) <
                sortedCategories.length - 1)
              SizedBox(
                height: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard(Service service) {
    final category = _categories.firstWhere(
      (cat) => cat.id == service.categoryId,
      orElse: () =>
          Category(id: '', name: AppLocalizations.of(context)!.unknownCategory),
    );

    final isSelected = _selectedServices.any(
        (serviceWithQuantity) => serviceWithQuantity.service.id == service.id);

    return GestureDetector(
      onTap: () => _onServiceToggled(service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryStart : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
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
                        : _buildServiceImagePlaceholder(),
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
                          style: const TextStyle(
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
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
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
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryStart,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
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
        return Image.network(imageUrl, fit: BoxFit.cover);
      } else if (imageUrl.startsWith('/')) {
        return Image.file(File(imageUrl), fit: BoxFit.cover);
      } else {
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(Icons.image, color: Colors.grey[600], size: 32),
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
        ),
      );
    }
  }

  Widget _buildServiceImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 232,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Icon(
        Icons.shopping_cart,
        size: AppTheme.getResponsiveFontSize(
          context,
          mobile: 48,
          tablet: 56,
          desktop: 64,
        ),
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildCategoryImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryStart.withValues(alpha: 0.3),
            AppTheme.primaryEnd.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Icon(
        Icons.category,
        size: AppTheme.getResponsiveFontSize(
          context,
          mobile: 48,
          tablet: 56,
          desktop: 64,
        ),
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildFloatingBookingButton() {
    return Positioned(
      right: 16,
      bottom: 20,
      child: GestureDetector(
        onTap: _showBookingFormDialog,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryStart.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shopping cart icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 24,
                  ),
                  // Badge with service count
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_selectedServices.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Total price
              Text(
                '${_formatPrice(_totalPrice)}₫',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingFormOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryStart.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryStart,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.bookingScreenDetails,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _hideBookingForm,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Customer Information Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.bookingCustomerInfo,
                    icon: Icons.person,
                    child: Column(
                      children: [
                        // Phone input with dropdown
                        Column(
                          children: [
                            TextField(
                              controller: _customerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.phoneNumber,
                                prefixIcon: const Icon(Icons.phone),
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
                                  borderSide: BorderSide(
                                      color: AppTheme.primaryStart, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            // Customer dropdown when typing phone
                            if (_showCustomerDropdown) ...[
                              const SizedBox(height: 8),
                              Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: AppTheme.primaryStart
                                            .withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Header
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryStart
                                              .withValues(alpha: 0.1),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.people,
                                                color: AppTheme.primaryStart,
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Khách hàng tìm thấy (${_filteredCustomers.length})',
                                              style: TextStyle(
                                                color: AppTheme.primaryStart,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Customer list
                                      Flexible(
                                        child: _filteredCustomers.isEmpty
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Text(
                                                  'Không tìm thấy khách hàng',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              )
                                            : ListView.builder(
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                itemCount:
                                                    _filteredCustomers.length,
                                                itemBuilder: (context, index) {
                                                  final customer =
                                                      _filteredCustomers[index];
                                                  return _buildDropdownCustomerItem(
                                                    customerName: customer.name,
                                                    customerPhone:
                                                        customer.phone,
                                                    onTap: () =>
                                                        _selectCustomer(
                                                            customer),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _customerNameController,
                          label: AppLocalizations.of(context)!.customerName,
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _customerAddressController,
                          label: AppLocalizations.of(context)!.address,
                          prefixIcon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected Services Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!
                        .servicesSelected(_selectedServices.length),
                    icon: Icons.shopping_cart,
                    child: Column(
                      children: [
                        // Services list
                        ...(_selectedServices.map((serviceWithQuantity) =>
                            _buildBookingServiceItem(serviceWithQuantity))),

                        if (_selectedServices.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Total price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.total,
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
                                  color: AppTheme.primaryStart,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delivery Option Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.deliveryOption,
                    icon: Icons.local_shipping,
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title:
                              Text(AppLocalizations.of(context)!.pickupAtSalon),
                          value: 'pickup',
                          groupValue: _deliveryOption,
                          onChanged: (value) {
                            setState(() {
                              _deliveryOption = value!;
                              // Clear customer info when switching to pickup
                              _customerNameController.clear();
                              _customerPhoneController.clear();
                              _customerAddressController.clear();
                            });
                          },
                          activeColor: AppTheme.primaryStart,
                        ),
                        RadioListTile<String>(
                          title:
                              Text(AppLocalizations.of(context)!.homeDelivery),
                          value: 'delivery',
                          groupValue: _deliveryOption,
                          onChanged: (value) {
                            setState(() {
                              _deliveryOption = value!;
                            });
                          },
                          activeColor: AppTheme.primaryStart,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          onPressed: _hideBookingForm,
                          label: AppLocalizations.of(context)!.cancel,
                          icon: Icons.close,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPrimaryButton(
                          onPressed: _isCreatingBooking ? null : _createBooking,
                          isLoading: _isCreatingBooking,
                          label: AppLocalizations.of(context)!.bookingButton,
                          icon: Icons.check,
                        ),
                      ),
                    ],
                  ),
                ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryStart,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
  }) {
    return TextField(
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
          borderSide: BorderSide(color: AppTheme.primaryStart, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
      height: 48,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryStart.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
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

  Widget _buildBookingServiceItem(ServiceWithQuantity serviceWithQuantity) {
    final category = _categories.firstWhere(
      (cat) => cat.id == serviceWithQuantity.service.categoryId,
      orElse: () =>
          Category(id: '', name: AppLocalizations.of(context)!.unknownCategory),
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
                        color: AppTheme.primaryStart,
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
              // Quantity label
              Text(
                'Số lượng',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

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
                            ? AppTheme.primaryStart.withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: serviceWithQuantity.quantity > 1
                            ? () =>
                                _decreaseServiceQuantity(serviceWithQuantity)
                            : null,
                        icon: const Icon(Icons.remove),
                        color: serviceWithQuantity.quantity > 1
                            ? AppTheme.primaryStart
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
                        color: AppTheme.primaryStart.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () =>
                            _increaseServiceQuantity(serviceWithQuantity),
                        icon: const Icon(Icons.add),
                        color: AppTheme.primaryStart,
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

              const SizedBox(width: 16),

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
                      color: AppTheme.primaryStart,
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

  Widget _buildDropdownCustomerItem({
    required String customerName,
    required String customerPhone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryStart,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Customer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPhoneNumber(customerPhone),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryStart,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

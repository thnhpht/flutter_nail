import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'api_client.dart';
import 'config/api_config.dart';
import 'models.dart';
import 'screens/login_screen.dart';
import 'screens/order_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/services_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/menu_booking_screen.dart' as booking;
import 'screens/bills_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/inventory_reports_screen.dart';
import 'screens/profit_reports_screen.dart';
import 'screens/salon_info_screen.dart';
import 'screens/update_order_screen.dart';
import 'ui/navigation_drawer.dart';
import 'ui/design_system.dart';
import 'ui/notification_button.dart';
import 'services/notification_service.dart';
import 'services/language_service.dart';
import 'services/audio_service.dart';
import 'generated/l10n/app_localizations.dart';

enum _HomeView {
  welcome,
  customers,
  employees,
  categories,
  services,
  menu,
  orders,
  bills,
  reports,
  inventoryReports,
  profitReports,
  salonInfo,
  updateOrder
}

void main() {
// Sử dụng ApiConfig để tự động detect platform và chọn URL phù hợp
  final baseUrl = ApiConfig.baseUrl;
  // Removed print statements for production
  runApp(NailApp(baseUrl: baseUrl));
}

class NailApp extends StatefulWidget {
  const NailApp({super.key, required this.baseUrl});
  final String baseUrl;

  @override
  State<NailApp> createState() => _NailAppState();
}

class _NailAppState extends State<NailApp> {
  late final ApiClient api = ApiClient(baseUrl: widget.baseUrl);
  _HomeView _view = _HomeView.welcome;
  bool _isLoggedIn = false;
  String _userRole = 'shop_owner'; // Default to shop owner
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationService _notificationService = NotificationService();
  final LanguageService _languageService = LanguageService();
  final AudioService _audioService = AudioService();

  // Dashboard stats
  Map<String, dynamic> _todayStats = {
    'totalBills': 0,
    'totalCustomers': 0,
    'totalRevenue': 0.0,
  };
  bool _isLoadingStats = true;

  // Salon information
  Information? _salonInfo;
  bool _isLoadingSalonInfo = true;
  bool _hasLoadedSalonInfo = false;

  // Employee information
  String? _employeeName;
  bool _isLoadingEmployeeName = true;

  // Update order
  Order? _orderToUpdate;

  // Callback function to refresh dashboard stats
  void Function()? _onOrderCreated;

  // Debounce mechanism to prevent too frequent refreshes
  DateTime? _lastRefreshTime;
  static const Duration _refreshDebounceTime = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _notificationService.initialize(apiClient: api);

    // Initialize audio service
    _audioService.initialize();

    // Listen for new notifications
    _notificationService.newNotificationNotifier
        .addListener(_onNewNotification);

    // Set up callback for order creation
    _onOrderCreated = () {
      _debouncedRefreshStats();
    };

    // Listen for language changes
    _languageService.addListener(_onLanguageChanged);
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await api.isLoggedIn();
    print('_checkLoginStatus: isLoggedIn = $isLoggedIn');

    if (isLoggedIn) {
      // Get user role from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role') ?? 'shop_owner';
      print('_checkLoginStatus: userRole from SharedPreferences = $userRole');

      setState(() {
        _isLoggedIn = isLoggedIn;
        _userRole = userRole;
      });

      print('_checkLoginStatus: _userRole set to $_userRole');

      // Only load authenticated data for real users (not booking users)
      if (userRole != 'booking') {
        _loadTodayStats();
        _loadSalonInfo(); // Load salon info when checking login status
        // Load employee name with the correct userRole
        if (userRole == 'employee') {
          _loadEmployeeName();
        } else {
          setState(() {
            _employeeName = null;
            _isLoadingEmployeeName = false;
          });
        }
      } else {
        // For booking users, load salon info using booking-specific API
        _loadSalonInfoForBooking();
        setState(() {
          _employeeName = null;
          _isLoadingEmployeeName = false;
          _isLoadingStats = false; // Don't load stats for booking users
        });
      }
    } else {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _userRole = 'shop_owner'; // Reset to default
        _employeeName = null; // Reset employee name
        _isLoadingEmployeeName = true; // Reset loading state
      });
    }
  }

  Future<void> _loadTodayStats() async {
    // Debug: Check user role before loading stats
    print('_loadTodayStats called with userRole: $_userRole');

    // Don't load stats for booking users
    if (_userRole == 'booking') {
      print('Skipping stats loading for booking user');
      setState(() {
        _isLoadingStats = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoadingStats = true;
      });

      final stats = await api.getTodayStats();
      setState(() {
        _todayStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      // Fallback to local calculation if API fails
      await _calculateLocalStats();
    }
  }

  Future<void> _loadSalonInfo() async {
    // Debug: Check user role before loading salon info
    print('_loadSalonInfo called with userRole: $_userRole');

    // Don't load salon info for booking users (they should use _loadSalonInfoForBooking)
    if (_userRole == 'booking') {
      print('Skipping authenticated salon info loading for booking user');
      _loadSalonInfoForBooking();
      return;
    }

    try {
      setState(() {
        _isLoadingSalonInfo = true;
      });
      final salonInfo = await api.getInformation();
      setState(() {
        _salonInfo = salonInfo;
        _isLoadingSalonInfo = false;
        _hasLoadedSalonInfo = true;
      });
    } catch (e) {
      setState(() {
        _isLoadingSalonInfo = false;
        _hasLoadedSalonInfo = true;
      });
      // Salon info loading failed, but don't show error to user
      // The app will use fallback values
    }
  }

  Future<void> _loadSalonInfoForBooking() async {
    try {
      setState(() {
        _isLoadingSalonInfo = true;
      });

      // Get salon name from SharedPreferences for booking user
      final prefs = await SharedPreferences.getInstance();
      final salonName = prefs.getString('salon_name') ?? '';

      if (salonName.isNotEmpty) {
        final salonInfo = await api.getInformationForBooking(salonName);
        setState(() {
          _salonInfo = salonInfo;
          _isLoadingSalonInfo = false;
          _hasLoadedSalonInfo = true;
        });
      } else {
        setState(() {
          _isLoadingSalonInfo = false;
          _hasLoadedSalonInfo = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSalonInfo = false;
        _hasLoadedSalonInfo = true;
      });
      // Salon info loading failed, but don't show error to user
      // The app will use fallback values
    }
  }

  Future<void> _loadEmployeeName() async {
    try {
      setState(() {
        _isLoadingEmployeeName = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employee_id');

      if (employeeId != null && employeeId.isNotEmpty) {
        final employees = await api.getEmployees();
        final employee = employees.firstWhere(
          (e) => e.id == employeeId,
          orElse: () => throw Exception('Employee not found'),
        );
        setState(() {
          _employeeName = employee.name;
          _isLoadingEmployeeName = false;
        });
      } else {
        setState(() {
          _employeeName = null;
          _isLoadingEmployeeName = false;
        });
      }
    } catch (e) {
      setState(() {
        _employeeName = null;
        _isLoadingEmployeeName = false;
      });
    }
  }

  Future<void> _calculateLocalStats() async {
    try {
      // Don't calculate stats for booking users
      if (_userRole == 'booking') {
        setState(() {
          _isLoadingStats = false;
        });
        return;
      }

      final orders = await api.getOrders();

      final today = DateTime.now();
      var todayOrders = orders.where((order) {
        final orderDate = order.createdAt;
        return orderDate.year == today.year &&
            orderDate.month == today.month &&
            orderDate.day == today.day;
      }).toList();

      // Nếu là nhân viên, lọc theo nhân viên đó
      if (_userRole == 'employee') {
        final prefs = await SharedPreferences.getInstance();
        final employeeId = prefs.getString('employee_id');
        if (employeeId != null && employeeId.isNotEmpty) {
          todayOrders = todayOrders.where((order) {
            return order.employeeIds.contains(employeeId);
          }).toList();
        }
      }

      // Đếm số khách hàng duy nhất hôm nay (khách hàng có ít nhất 1 hóa đơn trong ngày)
      final todayCustomers =
          todayOrders.map((order) => order.customerPhone).toSet().length;

      final totalRevenue =
          todayOrders.fold<double>(0.0, (sum, order) => sum + order.totalPrice);

      setState(() {
        _todayStats = {
          'totalBills': todayOrders.length,
          'totalCustomers': todayCustomers,
          'totalRevenue': totalRevenue,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _onLoginSuccess() async {
    // Get user role from SharedPreferences after login
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? 'shop_owner';

    setState(() {
      _isLoggedIn = true;
      _userRole = userRole;
      _view = _HomeView
          .welcome; // Luôn luôn trả về màn hình chính sau khi đăng nhập
    });

    // Re-initialize NotificationService with current API client
    _notificationService.initialize(apiClient: api);

    // Re-add listener after login
    _notificationService.newNotificationNotifier
        .addListener(_onNewNotification);

    // Only load authenticated data for real users (not booking users)
    if (userRole != 'booking') {
      _loadTodayStats();
      _loadSalonInfo();
      // Load employee name with the correct userRole
      if (userRole == 'employee') {
        _loadEmployeeName();
      } else {
        setState(() {
          _employeeName = null;
          _isLoadingEmployeeName = false;
        });
      }
    } else {
      // For booking users, load salon info using booking-specific API
      _loadSalonInfoForBooking();
      setState(() {
        _employeeName = null;
        _isLoadingEmployeeName = false;
        _isLoadingStats = false; // Don't load stats for booking users
      });
    }
  }

  void _refreshBills() {
    // Refresh bills screen by switching to it and back
    setState(() {
      _view = _HomeView.bills;
    });

    // Refresh stats as well (only for authenticated users)
    if (_userRole != 'booking') {
      _loadTodayStats();
    }

    // Add a small delay to ensure the screen is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // This will trigger a rebuild of the bills screen
      });
    });
  }

  void _refreshSalonInfo() {
    // Refresh salon info when updated from salon info screen
    if (_userRole != 'booking') {
      _loadSalonInfo();
    } else {
      _loadSalonInfoForBooking();
    }
  }

  void _navigateToUpdateOrder(Order order) {
    setState(() {
      _orderToUpdate = order;
      _view = _HomeView.updateOrder;
    });
  }

  void _onLanguageChanged() {
    setState(() {
      // Rebuild the widget when language changes
    });
  }

  @override
  void dispose() {
    _notificationService.newNotificationNotifier
        .removeListener(_onNewNotification);
    _languageService.removeListener(_onLanguageChanged);
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageService,
      builder: (context, child) {
        return MaterialApp(
          title: 'FShop',
          locale: _languageService.currentLocale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LanguageService.supportedLocales,
          theme: ThemeData(
            colorSchemeSeed: Colors.pink,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
          ),
          home: _isLoggedIn
              ? (_userRole == 'booking'
                  ? _buildBookingScreen()
                  : _buildMainScreen())
              : LoginScreen(
                  api: api,
                  onLoginSuccess: _onLoginSuccess,
                ),
          // Add responsive builder to handle orientation changes
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }

  Widget _buildBookingScreen() {
    // Booking user gets direct access to menu booking screen without navigation
    return booking.MenuScreen(
        api: api, onLogout: _handleLogout, onOrderCreated: _onOrderCreated);
  }

  Widget _buildMainScreen() {
    // Use NavigationDrawer for all devices
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppNavigationDrawer(
        selectedIndex: _getSelectedIndex(),
        onItemSelected: _onNavigationItemSelected,
        onLogout: _handleLogout,
        userRole: _userRole,
        languageService: _languageService,
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Responsive App Bar
            Container(
              padding: AppTheme.getResponsivePadding(
                context,
                mobile:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                tablet:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                desktop:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu Button and Notification Button (all devices)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Notification Button (only for shop owners)
                      if (_userRole == 'shop_owner')
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: NotificationButton(apiClient: api),
                        ),
                    ],
                  ),

                  // Spacer to push salon name to the right
                  const Spacer(),

                  // Logo/Title - Moved to the right
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _view = _HomeView.welcome;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: _isLoadingSalonInfo && !_hasLoadedSalonInfo
                            ? SizedBox(
                                width: AppTheme.isMobile(context) ? 150 : 200,
                                height: 20,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _salonInfo?.salonName.isNotEmpty == true
                                        ? _salonInfo!.salonName
                                        : 'Shop',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTheme.getResponsiveFontSize(
                                        context,
                                        mobile: 24,
                                        tablet: 28,
                                        desktop: 32,
                                      ),
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _getWelcomeText(context),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: AppTheme.getResponsiveFontSize(
                                        context,
                                        mobile: 12,
                                        tablet: 14,
                                        desktop: 16,
                                      ),
                                      letterSpacing: 0.3,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content with responsive padding
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _getCurrentScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex() {
    if (_userRole == 'employee') {
      // Employee navigation mapping
      switch (_view) {
        case _HomeView.welcome:
          return -1; // No selection for welcome screen
        case _HomeView.menu:
          return 0; // First item in employee nav
        case _HomeView.services:
          return 1; // Second item in employee nav
        case _HomeView.orders:
          return 2; // Third item in employee nav
        case _HomeView.bills:
          return 3; // Fourth item in employee nav
        case _HomeView.updateOrder:
          return -1; // No selection for update order screen
        default:
          return -1; // No selection for restricted screens
      }
    } else {
      // Shop owner navigation mapping
      switch (_view) {
        case _HomeView.welcome:
          return -1; // No selection for welcome screen
        case _HomeView.customers:
          return 1; // Second item in shop owner nav drawer
        case _HomeView.employees:
          return 2; // Third item in shop owner nav drawer
        case _HomeView.categories:
          return 3; // Fourth item in shop owner nav drawer
        case _HomeView.services:
          return 4; // Fifth item in shop owner nav drawer
        case _HomeView.menu:
          return 9; // Menu item in shop owner nav drawer
        case _HomeView.orders:
          return 5; // Sixth item in shop owner nav drawer
        case _HomeView.bills:
          return 6; // Seventh item in shop owner nav drawer
        case _HomeView.reports:
          return 7; // Eighth item in shop owner nav drawer
        case _HomeView.inventoryReports:
          return 10; // Eleventh item in shop owner nav drawer
        case _HomeView.profitReports:
          return 11; // Twelfth item in shop owner nav drawer
        case _HomeView.salonInfo:
          return 8; // Ninth item in shop owner nav drawer
        case _HomeView.updateOrder:
          return -1; // No selection for update order screen
      }
    }
  }

  void _onNavigationItemSelected(int index) {
    setState(() {
      if (_userRole == 'employee') {
        // Employee navigation mapping
        switch (index) {
          case 0: // Menu (first item in employee nav)
            _view = _HomeView.menu;
            break;
          case 1: // Services (second item in employee nav)
            _view = _HomeView.services;
            break;
          case 2: // Orders (third item in employee nav)
            _view = _HomeView.orders;
            break;
          case 3: // Bills (fourth item in employee nav)
            _view = _HomeView.bills;
            break;
          default:
            _view = _HomeView.welcome;
            break;
        }
      } else {
        // Shop owner navigation mapping
        switch (index) {
          case 0:
            _view = _HomeView.welcome;
            break;
          case 1:
            _view = _HomeView.customers;
            break;
          case 2:
            _view = _HomeView.employees;
            break;
          case 3:
            _view = _HomeView.categories;
            break;
          case 4:
            _view = _HomeView.services;
            break;
          case 5:
            _view = _HomeView.orders;
            break;
          case 6:
            _view = _HomeView.bills;
            break;
          case 7:
            _view = _HomeView.reports;
            break;
          case 8:
            _view = _HomeView.salonInfo;
            break;
          case 9:
            _view = _HomeView.menu;
            break;
          case 10:
            _view = _HomeView.inventoryReports;
            break;
          case 11:
            _view = _HomeView.profitReports;
            break;
          default:
            _view = _HomeView.welcome;
            break;
        }
      }
    });

    // Close drawer after selection
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _handleLogout() async {
    await api.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  void _onNewNotification() {
    final newNotification = _notificationService.newNotificationNotifier.value;

    if (newNotification != null && _userRole == 'shop_owner' && mounted) {
      // Play notification sound for shop owner when receiving new notification from polling
      _audioService.playNotificationSound();
      // Just clear the notification - no Flushbar needed
      _notificationService.clearNewNotification();

      // Auto refresh today's stats when new notification arrives
      // This ensures dashboard updates when new orders are created
      // Only refresh if notification is about orders (order_created, booking_created, order_paid)
      if (newNotification.type == 'order_created' ||
          newNotification.type == 'booking_created' ||
          newNotification.type == 'order_paid') {
        _debouncedRefreshStats();
      }
    }
  }

  /// Debounced refresh to prevent too frequent API calls
  void _debouncedRefreshStats() {
    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > _refreshDebounceTime) {
      _lastRefreshTime = now;
      _loadTodayStats();
    }
  }

  String _formatCurrencyVN(double amount) {
    // Format số tiền theo định dạng Việt Nam: 150.000 VNĐ
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} VNĐ';
  }

  String _getWelcomeText(BuildContext context) {
    if (_userRole == 'employee') {
      if (_isLoadingEmployeeName) {
        return '...';
      } else if (_employeeName != null && _employeeName!.isNotEmpty) {
        return '$_employeeName';
      } else {
        // Fallback to localized text or default
        final l10n = AppLocalizations.of(context);
        return l10n?.employee ?? 'Nhân viên';
      }
    } else {
      final l10n = AppLocalizations.of(context);
      return l10n?.boss ?? 'Boss';
    }
  }

  Widget _getCurrentScreen() {
    // Check if employee is trying to access restricted screens
    if (_userRole == 'employee') {
      switch (_view) {
        case _HomeView.customers:
        case _HomeView.employees:
        case _HomeView.categories:
        case _HomeView.reports:
          // Redirect employees to welcome screen if they try to access restricted screens
          return _buildWelcomeScreen();
        case _HomeView.menu:
          return MenuScreen(api: api);
        case _HomeView.services:
          return ServicesScreen(api: api);
        case _HomeView.orders:
          return OrderScreen(api: api, onOrderCreated: _onOrderCreated);
        case _HomeView.bills:
          return BillsScreen(
              api: api, onNavigateToUpdateOrder: _navigateToUpdateOrder);
        case _HomeView.updateOrder:
          if (_orderToUpdate != null) {
            return UpdateOrderScreen(
              api: api,
              order: _orderToUpdate!,
              onOrderUpdated: () {
                _refreshBills();
                setState(() {
                  _view = _HomeView.bills;
                  _orderToUpdate = null; // Reset order after update
                });
              },
              onCancel: () {
                setState(() {
                  _view = _HomeView.bills;
                  _orderToUpdate = null; // Reset order when cancel
                });
              },
            );
          }
          return BillsScreen(
              api: api, onNavigateToUpdateOrder: _navigateToUpdateOrder);
        default:
          return _buildWelcomeScreen();
      }
    } else {
      // Shop owner has access to all screens
      switch (_view) {
        case _HomeView.customers:
          return CustomersScreen(api: api);
        case _HomeView.employees:
          return EmployeesScreen(api: api);
        case _HomeView.categories:
          return CategoriesScreen(api: api);
        case _HomeView.services:
          return ServicesScreen(api: api);
        case _HomeView.menu:
          return MenuScreen(api: api);
        case _HomeView.orders:
          return OrderScreen(api: api, onOrderCreated: _onOrderCreated);
        case _HomeView.bills:
          return BillsScreen(
              api: api, onNavigateToUpdateOrder: _navigateToUpdateOrder);
        case _HomeView.reports:
          return ReportsScreen(api: api);
        case _HomeView.inventoryReports:
          return InventoryReportsScreen(api: api);
        case _HomeView.profitReports:
          return ProfitReportsScreen(api: api);
        case _HomeView.salonInfo:
          return SalonInfoScreen(
              api: api, onSalonInfoUpdated: _refreshSalonInfo);
        case _HomeView.updateOrder:
          if (_orderToUpdate != null) {
            return UpdateOrderScreen(
              api: api,
              order: _orderToUpdate!,
              onOrderUpdated: () {
                _refreshBills();
                setState(() {
                  _view = _HomeView.bills;
                  _orderToUpdate = null; // Reset order after update
                });
              },
              onCancel: () {
                setState(() {
                  _view = _HomeView.bills;
                  _orderToUpdate = null; // Reset order when cancel
                });
              },
            );
          }
          // If no order to update, redirect to bills screen
          return BillsScreen(
              api: api, onNavigateToUpdateOrder: _navigateToUpdateOrder);
        default:
          return _buildWelcomeScreen();
      }
    }
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      child: Container(
        padding: AppTheme.getResponsivePadding(
          context,
          mobile: const EdgeInsets.all(16),
          tablet: const EdgeInsets.all(24),
          desktop: const EdgeInsets.all(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Icon with responsive sizing
            _isLoadingSalonInfo && !_hasLoadedSalonInfo
                ? SizedBox(
                    width: AppTheme.isMobile(context)
                        ? 120
                        : AppTheme.isTablet(context)
                            ? 150
                            : 160,
                    height: AppTheme.isMobile(context)
                        ? 120
                        : AppTheme.isTablet(context)
                            ? 150
                            : 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : (_salonInfo?.logo.isNotEmpty == true
                    ? _buildSalonLogo(_salonInfo!.logo)
                    : _buildFallbackLogo()),

            SizedBox(
                height: AppTheme.getResponsiveSpacing(context,
                    mobile: 16, tablet: 24, desktop: 24)),

            // Quick Stats Cards
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

// Hiển thị logo salon, hỗ trợ network/file/base64
  Widget _buildSalonLogo(String logoUrl) {
    final size = AppTheme.isMobile(context)
        ? 120.0
        : AppTheme.isTablet(context)
            ? 150.0
            : 160.0;
    try {
      if (logoUrl.startsWith('data:image/')) {
        // base64
        final base64String = logoUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } else if (logoUrl.startsWith('http://') ||
          logoUrl.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            logoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(),
          ),
        );
      } else if (logoUrl.startsWith('/')) {
        // local file
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(logoUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(),
          ),
        );
      } else {
        return _buildFallbackLogo();
      }
    } catch (e) {
      return _buildFallbackLogo();
    }
  }

  Widget _buildQuickStats() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: AppTheme.getResponsivePadding(
                context,
                mobile: const EdgeInsets.all(16),
                tablet: const EdgeInsets.all(20),
                desktop: const EdgeInsets.all(24),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      if (l10n == null) {
                        return Text(
                          'Tổng quan hôm nay',
                          style: TextStyle(
                            fontSize: AppTheme.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }

                      return Text(
                        l10n.todayOverview,
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  SizedBox(
                      height: AppTheme.getResponsiveSpacing(context,
                          mobile: 16, tablet: 20, desktop: 24)),

                  // Responsive layout for stats cards
                  _buildStatsLayout(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsLayout() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        if (l10n == null) {
          // Fallback layout if localization is not available
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Khách hàng',
                    value: '0',
                    color: Colors.blue,
                  )),
                  SizedBox(
                      width: AppTheme.getResponsiveSpacing(context,
                          mobile: 12, tablet: 16, desktop: 20)),
                  Expanded(
                      child: _buildStatCard(
                    icon: Icons.receipt,
                    title: 'Hóa đơn',
                    value: '0',
                    color: Colors.green,
                  )),
                ],
              ),
              SizedBox(
                  height: AppTheme.getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20)),
              _buildStatCard(
                icon: Icons.attach_money,
                title: 'Doanh thu',
                value: '0 VNĐ',
                color: Colors.orange,
              ),
            ],
          );
        }

        // Use same layout for mobile, tablet and desktop: top row (customers + bills), bottom row (revenue full width)
        return Column(
          children: [
            // Top row: Customers and Bills
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: l10n.customers,
                    value: _isLoadingStats
                        ? '...'
                        : '${_todayStats['totalCustomers'] ?? 0}',
                    color: AppTheme.primaryEnd,
                    delay: 0,
                  ),
                ),
                SizedBox(
                    width: AppTheme.getResponsiveSpacing(context,
                        mobile: 12, tablet: 16, desktop: 20)),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.receipt,
                    title: l10n.bills,
                    value: _isLoadingStats
                        ? '...'
                        : '${_todayStats['totalBills'] ?? 0}',
                    color: AppTheme.primaryStart,
                    delay: 100,
                  ),
                ),
              ],
            ),
            SizedBox(
                height: AppTheme.getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
            // Bottom row: Revenue full width
            SizedBox(
              width: double.infinity,
              child: _buildStatCard(
                icon: Icons.attach_money,
                title: l10n.revenue,
                value: _isLoadingStats
                    ? '...'
                    : _formatCurrencyVN(_todayStats['totalRevenue'] ?? 0.0),
                color: Colors.green,
                delay: 200,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animValue) * 20),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: AppTheme.getResponsivePadding(
                context,
                mobile: const EdgeInsets.all(12),
                tablet: const EdgeInsets.all(16),
                desktop: const EdgeInsets.all(20),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),
                  SizedBox(
                      height: AppTheme.getResponsiveSpacing(context,
                          mobile: 8, tablet: 10, desktop: 12)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height: AppTheme.getResponsiveSpacing(context,
                          mobile: 4, tablet: 6, desktop: 8)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackLogo() {
    final size = AppTheme.isMobile(context)
        ? 120.0
        : AppTheme.isTablet(context)
            ? 150.0
            : 160.0;
    final iconSize = AppTheme.isMobile(context)
        ? 60.0
        : AppTheme.isTablet(context)
            ? 80.0
            : 90.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.business,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

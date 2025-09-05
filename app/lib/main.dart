import 'package:flutter/material.dart';
import 'api_client.dart';
import 'screens/login_screen.dart';
import 'screens/order_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/services_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/reports_screen.dart';
import 'ui/navigation_drawer.dart';
import 'ui/design_system.dart';

enum _HomeView { welcome, customers, employees, categories, services, orders, bills, reports }

void main() {
const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5088/api');
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Dashboard stats
  Map<String, dynamic> _todayStats = {
    'totalBills': 0,
    'totalCustomers': 0,
    'totalRevenue': 0.0,
  };
  bool _isLoadingStats = true;
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await api.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
    if (isLoggedIn) {
      _loadTodayStats();
    }
  }

  Future<void> _loadTodayStats() async {
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

  Future<void> _calculateLocalStats() async {
    try {
      final orders = await api.getOrders();
      final customers = await api.getCustomers();
      
      final today = DateTime.now();
      final todayOrders = orders.where((order) {
        final orderDate = order.createdAt;
        return orderDate.year == today.year &&
               orderDate.month == today.month &&
               orderDate.day == today.day;
      }).toList();
      
      // Since Customer model doesn't have createdAt, we'll use total customers count
      // or you can modify the Customer model to include createdAt if needed
      final totalCustomers = customers.length;
      
      final totalRevenue = todayOrders.fold<double>(0.0, (sum, order) => sum + order.totalPrice);
      
      setState(() {
        _todayStats = {
          'totalBills': todayOrders.length,
          'totalCustomers': totalCustomers,
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

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
    _loadTodayStats();
  }

  void _refreshBills() {
    // Refresh bills screen by switching to it and back
    setState(() {
      _view = _HomeView.bills;
    });
    
    // Refresh stats as well
    _loadTodayStats();
    
    // Add a small delay to ensure the screen is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // This will trigger a rebuild of the bills screen
      });
    });
  }

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Nail Manager',
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
    home: _isLoggedIn ? _buildMainScreen() : LoginScreen(
      api: api,
      onLoginSuccess: _onLoginSuccess,
    ),
  );
}

Widget _buildMainScreen() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Use NavigationRail for wider screens (tablet/desktop)
      if (constraints.maxWidth > 800) {
        return Scaffold(
          body: Row(
            children: [
              AppNavigationRail(
                selectedIndex: _getSelectedIndex(),
                onItemSelected: _onNavigationItemSelected,
                onLogout: _handleLogout,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        );
      }
      
      // Use NavigationDrawer for mobile screens
      return Scaffold(
        key: _scaffoldKey,
        drawer: AppNavigationDrawer(
          selectedIndex: _getSelectedIndex(),
          onItemSelected: _onNavigationItemSelected,
          onLogout: _handleLogout,
        ),
        body: _buildMainContent(),
      );
    },
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
          // Modern App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu Button (mobile only)
                if (MediaQuery.of(context).size.width <= 800)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                
                // Logo/Title - Clickable to go home
                Expanded(
                  child: Center(
                    child: Material(
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
                          child: Image.asset(
                            'icon/brand.png',
                            width: 200,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
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
  switch (_view) {
    case _HomeView.welcome:
      return 0;
    case _HomeView.customers:
      return 1;
    case _HomeView.employees:
      return 2;
    case _HomeView.categories:
      return 3;
    case _HomeView.services:
      return 4;
    case _HomeView.orders:
      return 5;
    case _HomeView.bills:
      return 6;
    case _HomeView.reports:
      return 7;
  }
}

void _onNavigationItemSelected(int index) {
  setState(() {
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
    }
  });
  
  // Close drawer on mobile after selection
  if (MediaQuery.of(context).size.width <= 800) {
    Navigator.of(context).pop();
  }
}

  void _handleLogout() async {
    await api.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

Widget _getCurrentScreen() {
  switch (_view) {
    case _HomeView.customers:
      return CustomersScreen(api: api);
    case _HomeView.employees:
      return EmployeesScreen(api: api);
    case _HomeView.categories:
      return CategoriesScreen(api: api);
    case _HomeView.services:
      return ServicesScreen(api: api);
    case _HomeView.orders:
      return OrderScreen(api: api, onOrderCreated: _refreshBills);
    case _HomeView.bills:
      return BillsScreen(api: api);
    case _HomeView.reports:
      return ReportsScreen(api: api);
    case _HomeView.welcome:
    default:
      return _buildWelcomeScreen();
  }
}

Widget _buildWelcomeScreen() {
  return Container(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Welcome Icon with enhanced styling
        Image.asset(
          'icon/logo.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        
        // Welcome Text with enhanced styling
        const Text(
          'Chào mừng đến với\nAeRI Nailroom',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.8,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Hệ thống quản lý salon nail chuyên nghiệp',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        // Quick Stats Cards
        _buildQuickStats(),
        const SizedBox(height: 32),
        
        // Quick Actions
        _buildQuickActions(),
      ],
    ),
  );
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Tổng quan hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.receipt,
                        title: 'Hóa đơn',
                        value: _isLoadingStats ? '...' : '${_todayStats['totalBills'] ?? 0}',
                        color: Colors.green,
                        delay: 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        title: 'Khách hàng',
                        value: _isLoadingStats ? '...' : '${_todayStats['totalCustomers'] ?? 0}',
                        color: Colors.blue,
                        delay: 100,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.attach_money,
                        title: 'Doanh thu',
                        value: _isLoadingStats ? '...' : _formatCurrency(_todayStats['totalRevenue'] ?? 0.0),
                        color: Colors.orange,
                        delay: 200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildQuickActions() {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 1000),
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, (1 - value) * 30),
        child: Opacity(
          opacity: value,
          child: Column(
            children: [
              const Text(
                'Thao tác nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.add_shopping_cart,
                      title: 'Tạo đơn mới',
                      onTap: () => setState(() => _view = _HomeView.orders),
                      delay: 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.people_alt,
                      title: 'Thêm khách hàng',
                      onTap: () => setState(() => _view = _HomeView.customers),
                      delay: 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.receipt_long,
                      title: 'Xem hóa đơn',
                      onTap: () => setState(() => _view = _HomeView.bills),
                      delay: 200,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.analytics,
                      title: 'Báo cáo',
                      onTap: () => setState(() => _view = _HomeView.reports),
                      delay: 300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  int delay = 0,
}) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 800 + delay),
    builder: (context, value, child) {
      return Transform.scale(
        scale: 0.9 + (0.1 * value),
        child: Opacity(
          opacity: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

}


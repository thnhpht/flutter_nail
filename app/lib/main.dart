import 'package:flutter/material.dart';
import 'api_client.dart';
import 'screens/order_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/services_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/reports_screen.dart';

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
  void _refreshBills() {
    // Refresh bills screen by switching to it and back
    setState(() {
      _view = _HomeView.bills;
    });
    
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
    home: Scaffold(
      body: Container(
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
                    // Logo/Title
                    Row(
                      children: [
                        Container(
                          child: Image.asset(
                            'icon/brand.png',
                            width: 200,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    
                    // Toggle Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: () {
                            setState(() {
                              if (_view == _HomeView.welcome) {
                                _view = _HomeView.orders;
                              } else {
                                _view = _HomeView.welcome;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _view == _HomeView.welcome ? Icons.add_shopping_cart : Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _view == _HomeView.welcome ? 'Tạo đơn' : 'Đóng',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
                  child: () {
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
                  }(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
}

Widget _buildWelcomeScreen() {
  return Container(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Welcome Icon with enhanced styling
        Image.asset(
          'icon/logo.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
        // Welcome Text with enhanced styling
        const Text(
          'Chào mừng đến với\nAeRI Nailroom',
          style: TextStyle(
            fontSize: 26,
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
        const SizedBox(height: 32),
        // Feature Cards with enhanced styling
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.people,
                title: 'Khách hàng',
                subtitle: 'Quản lý khách hàng',
                onTap: () => setState(() => _view = _HomeView.customers),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.work,
                title: 'Nhân viên',
                subtitle: 'Quản lý nhân viên salon',
                onTap: () => setState(() => _view = _HomeView.employees),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.category,
                title: 'Danh mục',
                subtitle: 'Quản lý danh mục',
                onTap: () => setState(() => _view = _HomeView.categories),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.spa,
                title: 'Dịch vụ',
                subtitle: 'Quản lý dịch vụ',
                onTap: () => setState(() => _view = _view = _HomeView.services),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.receipt,
                title: 'Hóa đơn',
                subtitle: 'Quản lý hóa đơn',
                onTap: () => setState(() => _view = _HomeView.bills),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Báo cáo',
                subtitle: 'Báo cáo doanh thu',
                onTap: () => setState(() => _view = _HomeView.reports),
              ),
            ),
          ],
        ) 
      ],
    ),
  );
}

Widget _buildFeatureCard({
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
}


import 'package:flutter/material.dart';
import 'api_client.dart';
import 'screens/customers_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/services_screen.dart';

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
int _index = 0;

@override
Widget build(BuildContext context) {
    final pages = [
    CustomersScreen(api: api),
    EmployeesScreen(api: api),
    CategoriesScreen(api: api),
    ServicesScreen(api: api),
    ];
    return MaterialApp(
    title: 'Nail Manager',
    theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
    home: Scaffold(
        appBar: AppBar(
            title: const Text(
            'AERI',
            style: TextStyle(
                fontSize: 24,            // 👈 chỉnh cỡ chữ
                fontWeight: FontWeight.bold, // đậm hơn
                color: Colors.pink,     // màu chữ
            ),
            ),
            centerTitle: true, // nếu muốn căn giữa
        ),
        body: pages[_index],
        bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'Khách hàng'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Nhân viên'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Danh mục'),
          NavigationDestination(icon: Icon(Icons.image), label: 'Dịch vụ'),
        ],
      ),
    ),
    );
}
}

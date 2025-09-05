import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient({required this.baseUrl});
  final String baseUrl; // e.g. http://localhost:5088/api
  
  // Auth methods
  Future<CheckEmailResponse> checkEmail(String email) async {
    final r = await http.post(_u('/auth/check-email'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(CheckEmailRequest(email: email).toJson()));
    _check(r);
    return CheckEmailResponse.fromJson(jsonDecode(r.body));
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final r = await http.post(_u('/auth/login'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(request.toJson()));
    _check(r);
    return LoginResponse.fromJson(jsonDecode(r.body));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('database_name');
    await prefs.remove('user_email');
    await prefs.remove('user_login');
    await prefs.remove('password_login');
    await prefs.remove('jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }

  Future<String?> getCurrentDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('database_name');
  }



  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$baseUrl$path').replace(queryParameters: q);

  // Customers
  Future<List<Customer>> getCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/customers'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Customer> getCustomer(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/customers/$phone'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    return Customer.fromJson(jsonDecode(r.body));
  }

  Future<void> createCustomer(Customer c) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.post(_u('/customers'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        }, 
        body: jsonEncode(c.toJson()));
    _check(r, expect201: true);
  }

  Future<void> updateCustomer(Customer c) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.put(_u('/customers/${c.phone}'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        }, 
        body: jsonEncode(c.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteCustomer(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.delete(_u('/customers/$phone'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r, expect204: true);
  }

  // Employees
  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/employees'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createEmployee(String name, {String? phone}) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.post(_u('/employees'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'name': name, 'phone': phone}));
    _check(r, expect201: true);
  }

  Future<void> updateEmployee(Employee e) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.put(_u('/employees/${e.id}'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        }, 
        body: jsonEncode(e.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.delete(_u('/employees/$id'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r, expect204: true);
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/categories'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createCategory(String name, {String? image}) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.post(_u('/categories'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'name': name, 'items': [], 'image': image}));
    _check(r, expect201: true);
  }

  Future<void> updateCategory(Category c) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.put(_u('/categories/${c.id}'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        }, 
        body: jsonEncode(c.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.delete(_u('/categories/$id'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r, expect204: true);
  }

  // Category Items (Services)
  Future<List<Service>> getServices() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/services'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createService(String categoryId, String name, double price, {String? image}) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.post(_u('/services'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'categoryId': categoryId, 'name': name, 'price': price, 'image': image}));
    _check(r, expect201: true);
  }

  Future<void> updateService(Service i) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.put(_u('/services/${i.id}'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        }, 
        body: jsonEncode(i.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteService(String categoryId, String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.delete(_u('/services/$serviceId'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r, expect204: true);
  }

  // Orders
  Future<List<Order>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/orders'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> createOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    // Convert lists to JSON strings for backend
    final orderData = order.toJson();
    orderData['employeeIds'] = jsonEncode(order.employeeIds);
    orderData['employeeNames'] = jsonEncode(order.employeeNames);
    orderData['serviceIds'] = jsonEncode(order.serviceIds);
    orderData['serviceNames'] = jsonEncode(order.serviceNames);
    
    final r = await http.post(_u('/orders'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        }, 
        body: jsonEncode(orderData));
    _check(r, expect201: true);
    
    return Order.fromJson(jsonDecode(r.body));
  }

  // Helper methods for finding customers and employees by phone
  Future<Customer?> findCustomerByPhone(String phone) async {
    try {
      return await getCustomer(phone);
    } catch (e) {
      return null; // Customer not found
    }
  }

  Future<Employee?> findEmployeeByPhone(String phone) async {
    try {
      final employees = await getEmployees();
      return employees.firstWhere((e) => e.phone == phone);
    } catch (e) {
      return null; // Employee not found
    }
  }

  // Dashboard statistics
  Future<Map<String, dynamic>> getTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';
    
    final r = await http.get(_u('/dashboard/today-stats'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  void _check(http.Response r, {bool expect201 = false, bool expect204 = false}) {
    final ok = expect201 ? r.statusCode == 201 : expect204 ? r.statusCode == 204 : (r.statusCode >= 200 && r.statusCode < 300);
    if (!ok) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }
}
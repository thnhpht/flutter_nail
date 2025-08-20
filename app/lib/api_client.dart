import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiClient {
  ApiClient({required this.baseUrl});
  final String baseUrl; // e.g. http://localhost:5088/api

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$baseUrl$path').replace(queryParameters: q);

  // Customers
  Future<List<Customer>> getCustomers() async {
    final r = await http.get(_u('/customers'));
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Customer> getCustomer(String phone) async {
    final r = await http.get(_u('/customers/$phone'));
    _check(r);
    return Customer.fromJson(jsonDecode(r.body));
  }

  Future<void> createCustomer(Customer c) async {
    final r = await http.post(_u('/customers'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(c.toJson()));
    _check(r, expect201: true);
  }

  Future<void> updateCustomer(Customer c) async {
    final r = await http.put(_u('/customers/${c.phoneNumber}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(c.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteCustomer(String phone) async {
    final r = await http.delete(_u('/customers/$phone'));
    _check(r, expect204: true);
  }

  // Employees
  Future<List<Employee>> getEmployees() async {
    final r = await http.get(_u('/employees'));
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createEmployee(String name, {String? phone}) async {
    final r = await http.post(_u('/employees'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': 0, 'fullName': name, 'phoneNumber': phone}));
    _check(r, expect201: true);
  }

  Future<void> updateEmployee(Employee e) async {
    final r = await http.put(_u('/employees/${e.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(e.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteEmployee(int id) async {
    final r = await http.delete(_u('/employees/$id'));
    _check(r, expect204: true);
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final r = await http.get(_u('/categories'));
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createCategory(String name, {String? description}) async {
    final r = await http.post(_u('/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': 0, 'name': name, 'description': description, 'items': []}));
    _check(r, expect201: true);
  }

  Future<void> updateCategory(Category c) async {
    final r = await http.put(_u('/categories/${c.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(c.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteCategory(int id) async {
    final r = await http.delete(_u('/categories/$id'));
    _check(r, expect204: true);
  }

  // Category Items
  Future<void> createCategoryItem(int categoryId, String name, double price) async {
    final r = await http.post(_u('/categories/$categoryId/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': 0, 'categoryId': categoryId, 'name': name, 'price': price}));
    _check(r, expect201: true);
  }

  Future<void> updateCategoryItem(CategoryItem i) async {
    final r = await http.put(_u('/categories/${i.categoryId}/items/${i.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(i.toJson()));
    _check(r, expect204: true);
  }

  Future<void> deleteCategoryItem(int categoryId, int itemId) async {
    final r = await http.delete(_u('/categories/$categoryId/items/$itemId'));
    _check(r, expect204: true);
  }

  void _check(http.Response r, {bool expect201 = false, bool expect204 = false}) {
    final ok = expect201 ? r.statusCode == 201 : expect204 ? r.statusCode == 204 : (r.statusCode >= 200 && r.statusCode < 300);
    if (!ok) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }
} 
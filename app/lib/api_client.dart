import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient({required this.baseUrl});
  final String baseUrl; // e.g. http://localhost:5088/api

  // HTTP client với timeout configuration
  final http.Client _client = http.Client();

  // Timeout duration cho các requests
  static const Duration _timeout = Duration(seconds: 10);

  // Auth methods
  Future<CheckEmailResponse> checkEmail(String email) async {
    final r = await _client
        .post(_u('/auth/check-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(CheckEmailRequest(email: email).toJson()))
        .timeout(_timeout);
    _check(r);
    return CheckEmailResponse.fromJson(jsonDecode(r.body));
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final r = await _client
        .post(_u('/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()))
        .timeout(_timeout);
    _check(r);

    final response = LoginResponse.fromJson(jsonDecode(r.body));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', response.token);
    await prefs.setString('user_role', response.userRole ?? 'shop_owner');
    await prefs.setString(
        'user_email', request.email); // Lưu user email cho shop owner

    return response;
  }

  Future<LoginResponse> employeeLogin(EmployeeLoginRequest request) async {
    final r = await _client
        .post(_u('/auth/employee-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()))
        .timeout(_timeout);
    _check(r);

    final response = LoginResponse.fromJson(jsonDecode(r.body));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', response.token);
    await prefs.setString('user_role', response.userRole ?? 'employee');
    await prefs.setString('employee_id', response.employeeId ?? '');
    await prefs.setString(
        'shop_name', request.shopName); // Lưu tên shop để gửi thông báo

    return response;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('database_name');
    await prefs.remove('user_email');
    await prefs.remove('user_login');
    await prefs.remove('password_login');
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('employee_id');
    await prefs.remove('shop_name');
    await prefs.remove('salon_name'); // For booking users
  }

  // Booking methods
  Future<bool> checkSalonExists(String salonName) async {
    try {
      final r = await _client
          .get(_u(
              '/auth/check-salon?salonName=${Uri.encodeComponent(salonName)}'))
          .timeout(_timeout);

      if (r.statusCode == 200) {
        final response = jsonDecode(r.body);
        return response['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveBookingUserInfo(String salonName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', 'booking');
    await prefs.setString('salon_name', salonName);

    // For booking users, create a temporary JWT token using salon name as email
    // This is a workaround since backend doesn't have public booking endpoints
    await prefs.setString('jwt_token', 'booking_temp_token');
    await prefs.setString('database_name', salonName);
  }

  // Booking-specific API methods (no authentication required)
  Future<List<Category>> getCategoriesForBooking(String salonName) async {
    final r = await _client
        .get(_u(
            '/booking/categories?salonName=${Uri.encodeComponent(salonName)}'))
        .timeout(_timeout);
    _checkBooking(r);
    final List<dynamic> data = jsonDecode(r.body);
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<List<Service>> getServicesForBooking(String salonName) async {
    final r = await _client
        .get(
            _u('/booking/services?salonName=${Uri.encodeComponent(salonName)}'))
        .timeout(_timeout);
    _checkBooking(r);
    final List<dynamic> data = jsonDecode(r.body);
    return data.map((json) => Service.fromJson(json)).toList();
  }

  Future<Information> getInformationForBooking(String salonName) async {
    final r = await _client
        .get(_u(
            '/booking/information?salonName=${Uri.encodeComponent(salonName)}'))
        .timeout(_timeout);
    _checkBooking(r);
    return Information.fromJson(jsonDecode(r.body));
  }

  Future<List<Customer>> getCustomersForBooking(String salonName) async {
    final r = await _client
        .get(_u(
            '/booking/customers?salonName=${Uri.encodeComponent(salonName)}'))
        .timeout(_timeout);
    _checkBooking(r);
    final List<dynamic> data = jsonDecode(r.body);
    return data.map((json) => Customer.fromJson(json)).toList();
  }

  Future<Customer?> findCustomerByPhoneForBooking(
      String phone, String salonName) async {
    try {
      final r = await _client
          .get(_u(
              '/booking/customers/$phone?salonName=${Uri.encodeComponent(salonName)}'))
          .timeout(_timeout);
      _checkBooking(r);
      return Customer.fromJson(jsonDecode(r.body));
    } catch (e) {
      return null; // Customer not found
    }
  }

  Future<List<ServiceInventory>> getServiceInventoryForBooking(
      String salonName) async {
    final r = await _client
        .get(_u(
            '/booking/servicedetails/inventory?salonName=${Uri.encodeComponent(salonName)}'))
        .timeout(_timeout);
    _checkBooking(r);
    final List<dynamic> data = jsonDecode(r.body);
    return data.map((json) => ServiceInventory.fromJson(json)).toList();
  }

  Future<Order> createBookingOrder(Order order, String salonName) async {
    // Create booking order request
    final bookingRequest = {
      'salonName': salonName,
      'customerPhone': order.customerPhone,
      'customerName': order.customerName,
      'customerAddress': order.customerAddress,
      'serviceIds': order.serviceIds,
      'serviceNames': order.serviceNames,
      'serviceQuantities': order.serviceQuantities,
      'totalPrice': order.totalPrice,
      'deliveryMethod': order.deliveryMethod,
    };

    final r = await _client
        .post(_u('/booking/orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bookingRequest))
        .timeout(_timeout);
    _checkBooking(r, expect201: true);
    return Order.fromJson(jsonDecode(r.body));
  }

  // Notification methods
  Future<Map<String, dynamic>> sendNotification({
    required String shopName,
    required String title,
    required String message,
    required String type,
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String employeeName,
    required double totalPrice,
  }) async {
    final requestBody = {
      'shopName': shopName,
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'employeeName': employeeName,
      'totalPrice': totalPrice,
    };

    final r = await _client
        .post(_u('/auth/send-notification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody))
        .timeout(_timeout);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> getNotifications(String shopName) async {
    final r = await _client
        .get(_u('/auth/get-notifications?shopName=$shopName'))
        .timeout(_timeout);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> markNotificationRead({
    required String shopName,
    required String notificationId,
  }) async {
    final requestBody = {
      'shopName': shopName,
      'notificationId': notificationId,
    };

    final r = await _client
        .post(_u('/auth/mark-notification-read'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody))
        .timeout(_timeout);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> deleteNotification({
    required String shopName,
    required String notificationId,
  }) async {
    final requestBody = {
      'shopName': shopName,
      'notificationId': notificationId,
    };

    final r = await _client
        .post(_u('/auth/delete-notification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody))
        .timeout(_timeout);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> markAllNotificationsRead({
    required String shopName,
  }) async {
    final requestBody = {
      'shopName': shopName,
      'notificationId':
          '', // Not used for this endpoint, but required by the request model
    };

    final r = await _client
        .post(_u('/auth/mark-all-notifications-read'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody))
        .timeout(_timeout);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> clearAllNotifications({
    required String shopName,
  }) async {
    final requestBody = {
      'shopName': shopName,
    };

    final r = await _client
        .post(_u('/auth/clear-all-notifications'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody))
        .timeout(_timeout);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }

  Future<String?> getCurrentDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('database_name');
  }

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q);

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
    return list
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<List<String>> getCustomerGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.get(_u('/customers/groups'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.cast<String>();
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
    return list
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEmployee(String name,
      {String? phone, String? password, String? image}) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.post(_u('/employees'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password ?? '',
          'image': image
        }));
    _check(r, expect201: true);
  }

  Future<void> updateEmployee(Employee e) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final response = await http.put(
      _u('/employees/${e.id}'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(e.toJson()),
    );

    if (response.statusCode >= 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['title'] ?? 'Lỗi cập nhật nhân viên');
    }
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

  Future<String> uploadEmployeeImage(
      List<int> imageBytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    var request = http.MultipartRequest('POST', _u('/employees/upload-image'));
    request.headers.addAll({
      'Authorization': 'Bearer $jwtToken',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _check(response);

    final responseData = jsonDecode(response.body);
    return responseData['imageUrl'] as String;
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
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<String> uploadCategoryImage(
      List<int> imageBytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    var request = http.MultipartRequest('POST', _u('/categories/upload-image'));
    request.headers.addAll({
      'Authorization': 'Bearer $jwtToken',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _check(response);

    final responseData = jsonDecode(response.body);
    return responseData['imageUrl'] as String;
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
    return list
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createService(String categoryId, String name, double price,
      {String? image, String? unit}) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.post(_u('/services'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'categoryId': categoryId,
          'name': name,
          'price': price,
          'image': image,
          'unit': unit
        }));
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

  Future<String> uploadServiceImage(
      List<int> imageBytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    var request = http.MultipartRequest('POST', _u('/services/upload-image'));
    request.headers.addAll({
      'Authorization': 'Bearer $jwtToken',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _check(response);

    final responseData = jsonDecode(response.body);
    return responseData['imageUrl'] as String;
  }

  // ServiceDetails methods
  Future<List<ServiceDetails>> getServiceDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.get(_u('/servicedetails'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => ServiceDetails.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceDetails>> getServiceDetailsByServiceId(
      String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r =
        await http.get(_u('/servicedetails/service/$serviceId'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => ServiceDetails.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceDetails> createServiceDetails(
      ServiceDetails serviceDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.post(_u('/servicedetails'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(serviceDetails.toJson()));
    _check(r, expect201: true);
    return ServiceDetails.fromJson(jsonDecode(r.body));
  }

  // Service Inventory
  Future<List<ServiceInventory>> getServiceInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.get(_u('/servicedetails/inventory'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => ServiceInventory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceInventory?> getServiceInventoryByServiceId(
      String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r =
        await http.get(_u('/servicedetails/inventory/$serviceId'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final inventoryJson = jsonDecode(r.body) as Map<String, dynamic>?;
    return inventoryJson != null
        ? ServiceInventory.fromJson(inventoryJson)
        : null;
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

  Future<Order?> getOrderById(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.get(_u('/orders/$orderId'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    final orderJson = jsonDecode(r.body) as Map<String, dynamic>;
    return Order.fromJson(orderJson);
  }

  Future<bool> checkOrderIdExists(String orderId) async {
    try {
      await getOrderById(orderId);
      return true; // Order exists
    } catch (e) {
      return false; // Order doesn't exist
    }
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

  Future<void> updateOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    // Convert lists to JSON strings for backend
    final orderData = order.toJson();
    orderData['employeeIds'] = jsonEncode(order.employeeIds);
    orderData['employeeNames'] = jsonEncode(order.employeeNames);
    orderData['serviceIds'] = jsonEncode(order.serviceIds);
    orderData['serviceNames'] = jsonEncode(order.serviceNames);

    final r = await http.put(_u('/orders/${order.id}'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(orderData));
    _check(r, expect204: true);
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

  // Information (Salon Info)
  Future<Information> getInformation() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.get(_u('/information'), headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    });
    _check(r);
    return Information.fromJson(jsonDecode(r.body));
  }

  Future<void> updateInformation(Information information) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final r = await http.put(_u('/information'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(information.toJson()));
    _check(r, expect204: true);
  }

  Future<String> uploadQRCode(List<int> imageBytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    var request =
        http.MultipartRequest('POST', _u('/information/upload-qrcode'));
    request.headers.addAll({
      'Authorization': 'Bearer $jwtToken',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _check(response);

    final responseData = jsonDecode(response.body);
    return responseData['qrCodeUrl'] as String;
  }

  Future<String> uploadLogo(List<int> imageBytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    var request = http.MultipartRequest('POST', _u('/information/upload-logo'));
    request.headers.addAll({
      'Authorization': 'Bearer $jwtToken',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _check(response);

    final responseData = jsonDecode(response.body);
    return responseData['logoUrl'] as String;
  }

  void _check(http.Response r,
      {bool expect201 = false, bool expect204 = false}) {
    final ok = expect201
        ? r.statusCode == 201
        : expect204
            ? r.statusCode == 204
            : (r.statusCode >= 200 && r.statusCode < 300);
    if (!ok) {
      if (r.statusCode == 401) {
        logout();
      }
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  void _checkBooking(http.Response r,
      {bool expect201 = false, bool expect204 = false}) {
    final ok = expect201
        ? r.statusCode == 201
        : expect204
            ? r.statusCode == 204
            : (r.statusCode >= 200 && r.statusCode < 300);
    if (!ok) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  // Dispose client khi không cần thiết
  void dispose() {
    _client.close();
  }
}

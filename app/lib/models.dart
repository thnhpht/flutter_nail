import 'dart:convert';

class Customer {
  final String phone;
  final String name;

  Customer({required this.phone, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    phone: json['phone'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'name': name,
  };
}

class Employee {
  final String id;
  final String name;
  final String? phone;

  Employee({required this.id, required this.name, this.phone});

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
  };
}

class Service {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String? image;

  Service({required this.id, required this.categoryId, required this.name, required this.price, this.image});

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    image: json['image'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'price': price,
    'image': image,
  };
}

class Category {
  final String id;
  final String name;
  final List<Service> items;
  final String? image;

  Category({required this.id, required this.name, this.items = const [], this.image});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList(),
    image: json['image'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
    'image': image,
  };
}

class Order {
  final String id;
  final String customerPhone;
  final String customerName;
  final String employeeId;
  final String employeeName;
  final List<String> categoryIds;
  final String categoryName;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final double totalPrice;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerPhone,
    required this.customerName,
    required this.employeeId,
    required this.employeeName,
    required this.categoryIds,
    required this.categoryName,
    required this.serviceIds,
    required this.serviceNames,
    required this.totalPrice,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<String> categoryIds = [];
    List<String> serviceIds = [];
    List<String> serviceNames = [];
    
    // Handle categoryIds - could be JSON string or array
    if (json['categoryIds'] is String) {
      try {
        final decoded = jsonDecode(json['categoryIds'] as String);
        categoryIds = (decoded as List<dynamic>).cast<String>();
      } catch (e) {
        categoryIds = [];
      }
    } else if (json['categoryIds'] is List) {
      categoryIds = (json['categoryIds'] as List<dynamic>).cast<String>();
    }
    
    // Handle serviceIds - could be JSON string or array
    if (json['serviceIds'] is String) {
      try {
        final decoded = jsonDecode(json['serviceIds'] as String);
        serviceIds = (decoded as List<dynamic>).cast<String>();
      } catch (e) {
        serviceIds = [];
      }
    } else if (json['serviceIds'] is List) {
      serviceIds = (json['serviceIds'] as List<dynamic>).cast<String>();
    }
    
    // Handle serviceNames - could be JSON string or array
    if (json['serviceNames'] is String) {
      try {
        final decoded = jsonDecode(json['serviceNames'] as String);
        serviceNames = (decoded as List<dynamic>).cast<String>();
      } catch (e) {
        serviceNames = [];
      }
    } else if (json['serviceNames'] is List) {
      serviceNames = (json['serviceNames'] as List<dynamic>).cast<String>();
    }
    
    return Order(
      id: json['id'] as String,
      customerPhone: json['customerPhone'] as String,
      customerName: json['customerName'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      categoryIds: categoryIds,
      categoryName: json['categoryName'] as String,
      serviceIds: serviceIds,
      serviceNames: serviceNames,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerPhone': customerPhone,
    'customerName': customerName,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'categoryIds': categoryIds,
    'categoryName': categoryName,
    'serviceIds': serviceIds,
    'serviceNames': serviceNames,
    'totalPrice': totalPrice,
    'createdAt': createdAt.toIso8601String(),
  };
}
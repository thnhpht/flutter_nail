import 'dart:convert';

class User {
  final String email;
  final String password;
  final String userLogin;
  final String passwordLogin;

  User({
    required this.email,
    required this.password,
    required this.userLogin,
    required this.passwordLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        email: json['email'] as String,
        password: json['password'] as String,
        userLogin: json['userLogin'] as String,
        passwordLogin: json['passwordLogin'] as String,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'userLogin': userLogin,
        'passwordLogin': passwordLogin,
      };
}

class LoginRequest {
  final String email;
  final String password;
  final String userLogin;
  final String passwordLogin;

  LoginRequest({
    required this.email,
    required this.password,
    required this.userLogin,
    required this.passwordLogin,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'userLogin': userLogin,
        'passwordLogin': passwordLogin,
      };
}

class CheckEmailRequest {
  final String email;

  CheckEmailRequest({required this.email});

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}

class CheckEmailResponse {
  final bool exists;
  final String message;

  CheckEmailResponse({
    required this.exists,
    required this.message,
  });

  factory CheckEmailResponse.fromJson(Map<String, dynamic> json) =>
      CheckEmailResponse(
        exists: json['exists'] as bool,
        message: json['message'] as String,
      );
}

class LoginResponse {
  final bool success;
  final String message;
  final String databaseName;
  final String token;
  final String? userRole; // 'shop_owner' or 'employee'
  final String? employeeId; // For employee login

  LoginResponse({
    required this.success,
    required this.message,
    required this.databaseName,
    required this.token,
    this.userRole,
    this.employeeId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        databaseName: json['databaseName'] as String,
        token: json['token'] as String,
        userRole: json['userRole'] as String?,
        employeeId: json['employeeId'] as String?,
      );
}

class EmployeeLoginRequest {
  final String shopEmail;
  final String employeePhone;
  final String employeePassword;

  EmployeeLoginRequest({
    required this.shopEmail,
    required this.employeePhone,
    required this.employeePassword,
  });

  Map<String, dynamic> toJson() => {
        'shopEmail': shopEmail,
        'employeePhone': employeePhone,
        'employeePassword': employeePassword,
      };
}

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
  final String? password;

  Employee({required this.id, required this.name, this.phone, this.password});

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        password: json['password'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'password': password,
      };
}

class Service {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String? image;

  Service(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.price,
      this.image});

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

  Category(
      {required this.id,
      required this.name,
      this.items = const [],
      this.image});

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
  final List<String> employeeIds;
  final List<String> employeeNames;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final double totalPrice;
  final double discountPercent;
  final double tip;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerPhone,
    required this.customerName,
    required this.employeeIds,
    required this.employeeNames,
    required this.serviceIds,
    required this.serviceNames,
    required this.totalPrice,
    this.discountPercent = 0.0,
    this.tip = 0.0,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<String> employeeIds = [];
    List<String> employeeNames = [];
    List<String> serviceIds = [];
    List<String> serviceNames = [];

    // Handle employeeIds - could be JSON string or array
    if (json['employeeIds'] is String) {
      try {
        final decoded = jsonDecode(json['employeeIds'] as String);
        employeeIds = (decoded as List<dynamic>).cast<String>();
      } catch (e) {
        employeeIds = [];
      }
    } else if (json['employeeIds'] is List) {
      employeeIds = (json['employeeIds'] as List<dynamic>).cast<String>();
    }

    // Handle employeeNames - could be JSON string or array
    if (json['employeeNames'] is String) {
      try {
        final decoded = jsonDecode(json['employeeNames'] as String);
        employeeNames = (decoded as List<dynamic>).cast<String>();
      } catch (e) {
        employeeNames = [];
      }
    } else if (json['employeeNames'] is List) {
      employeeNames = (json['employeeNames'] as List<dynamic>).cast<String>();
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
      employeeIds: employeeIds,
      employeeNames: employeeNames,
      serviceIds: serviceIds,
      serviceNames: serviceNames,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerPhone': customerPhone,
        'customerName': customerName,
        'employeeIds': employeeIds,
        'employeeNames': employeeNames,
        'serviceIds': serviceIds,
        'serviceNames': serviceNames,
        'totalPrice': totalPrice,
        'discountPercent': discountPercent,
        'tip': tip,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Information {
  final int id;
  final String salonName;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String facebook;
  final String instagram;
  final String zalo;
  final String logo;
  final String qrCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Information({
    required this.id,
    required this.salonName,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.facebook,
    required this.instagram,
    required this.zalo,
    required this.logo,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Information.fromJson(Map<String, dynamic> json) => Information(
        id: json['id'] as int,
        salonName: json['salonName'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        website: json['website'] as String? ?? '',
        facebook: json['facebook'] as String? ?? '',
        instagram: json['instagram'] as String? ?? '',
        zalo: json['zalo'] as String? ?? '',
        logo: json['logo'] as String? ?? '',
        qrCode: json['qrCode'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'salonName': salonName,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'facebook': facebook,
        'instagram': instagram,
        'zalo': zalo,
        'logo': logo,
        'qrCode': qrCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Information copyWith({
    int? id,
    String? salonName,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? facebook,
    String? instagram,
    String? zalo,
    String? logo,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Information(
      id: id ?? this.id,
      salonName: salonName ?? this.salonName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      zalo: zalo ?? this.zalo,
      logo: logo ?? this.logo,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

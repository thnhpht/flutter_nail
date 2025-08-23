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
  final String? description;
  final List<Service> items;
  final String? image;

  Category({required this.id, required this.name, this.description, this.items = const [], this.image});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList(),
    image: json['image'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'items': items.map((e) => e.toJson()).toList(),
    'image': image,
  };
}
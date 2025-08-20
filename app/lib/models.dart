class Customer {
final String phoneNumber;
final String fullName;

Customer({required this.phoneNumber, required this.fullName});

factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        phoneNumber: json['phoneNumber'] as String,
        fullName: json['fullName'] as String,
    );

Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'fullName': fullName,
    };
}

class Employee {
final int id;
final String fullName;
final String? phoneNumber;

Employee({required this.id, required this.fullName, this.phoneNumber});

factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
    );

Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
    };
}

class CategoryItem {
final int id;
final int categoryId;
final String name;
final double price;

CategoryItem({required this.id, required this.categoryId, required this.name, required this.price});

factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] as int,
        categoryId: json['categoryId'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'price': price,
    };
}

class Category {
final int id;
final String name;
final String? description;
final List<CategoryItem> items;

Category({required this.id, required this.name, this.description, this.items = const []});

factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    );

Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'items': items.map((e) => e.toJson()).toList(),
    };
} 
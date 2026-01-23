/// Model untuk Package (Paket Bundling)
class Package {
  final String id;
  final String name;
  final String? description;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<PackageItem>? items;

  const Package({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  /// Total harga komponen (sebagai panduan)
  double get totalComponentPrice {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
  }

  /// Margin (harga paket - total komponen)
  double get margin => price - totalComponentPrice;

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: json['package_items'] != null
          ? (json['package_items'] as List)
                .map((item) => PackageItem.fromJson(item))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Package copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PackageItem>? items,
  }) {
    return Package(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

/// Model untuk PackageItem (Komponen Paket)
class PackageItem {
  final String id;
  final String packageId;
  final String? productId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final DateTime? createdAt;

  const PackageItem({
    required this.id,
    required this.packageId,
    this.productId,
    required this.itemName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.createdAt,
  });

  double get subtotal => unitPrice * quantity;

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      id: json['id'] as String,
      packageId: json['package_id'] as String,
      productId: json['product_id'] as String?,
      itemName:
          json['item_name'] as String? ??
          (json['products'] != null ? json['products']['name'] : 'Unknown'),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'package_id': packageId,
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_id': packageId,
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  PackageItem copyWith({
    String? id,
    String? packageId,
    String? productId,
    String? itemName,
    int? quantity,
    double? unitPrice,
    DateTime? createdAt,
  }) {
    return PackageItem(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

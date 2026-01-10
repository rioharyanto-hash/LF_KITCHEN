/// Model untuk Produk Kue
class Product {
  final String id;
  final String name;
  final String? description;
  final double unitPrice;
  final double specialPrice;
  final double? costPrice;
  final int stockQty;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.specialPrice = 0,
    this.costPrice,
    required this.stockQty,
    this.category,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      specialPrice: (json['special_price'] as num?)?.toDouble() ?? 0,
      costPrice: json['cost_price'] != null
          ? (json['cost_price'] as num).toDouble()
          : null,
      stockQty: json['stock_qty'] as int? ?? 0,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit_price': unitPrice,
      'special_price': specialPrice,
      'cost_price': costPrice,
      'stock_qty': stockQty,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Untuk insert/update (tanpa id dan created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'description': description,
      'unit_price': unitPrice,
      'special_price': specialPrice,
      'cost_price': costPrice,
      'stock_qty': stockQty,
      'category': category,
      'image_url': imageUrl,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? unitPrice,
    double? specialPrice,
    double? costPrice,
    int? stockQty,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      specialPrice: specialPrice ?? this.specialPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQty: stockQty ?? this.stockQty,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

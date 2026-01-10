/// Model untuk Produk Kue
class Product {
  final String id;
  final String name;
  final String? size; // Ukuran: 22cm, 24cm, slice, dll
  final String? description;
  final double unitPrice; // Harga Normal
  final double specialPrice; // Harga Spesial
  final double? costPrice; // Harga Pokok
  final int stockQty;
  final String? category; // Kategori: Kue Ulang Tahun, Snack Box, dll
  final String? unit; // Satuan: pcs, box, slice
  final String? productType; // Jenis: Cake, Pastry, Bread, Snack
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.size,
    this.description,
    required this.unitPrice,
    this.specialPrice = 0,
    this.costPrice,
    required this.stockQty,
    this.category,
    this.unit,
    this.productType,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Nama produk dengan ukuran (jika ada)
  String get displayName {
    if (size != null && size!.isNotEmpty) {
      return '$name - $size';
    }
    return name;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as String?,
      description: json['description'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      specialPrice: (json['special_price'] as num?)?.toDouble() ?? 0,
      costPrice: json['cost_price'] != null
          ? (json['cost_price'] as num).toDouble()
          : null,
      stockQty: json['stock_qty'] as int? ?? 0,
      category: json['category'] as String?,
      unit: json['unit'] as String?,
      productType: json['product_type'] as String?,
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
      'size': size,
      'description': description,
      'unit_price': unitPrice,
      'special_price': specialPrice,
      'cost_price': costPrice,
      'stock_qty': stockQty,
      'category': category,
      'unit': unit,
      'product_type': productType,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Untuk insert/update (tanpa id dan created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'size': size,
      'description': description,
      'unit_price': unitPrice,
      'special_price': specialPrice,
      'cost_price': costPrice,
      'stock_qty': stockQty,
      'category': category,
      'unit': unit,
      'product_type': productType,
      'image_url': imageUrl,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? size,
    String? description,
    double? unitPrice,
    double? specialPrice,
    double? costPrice,
    int? stockQty,
    String? category,
    String? unit,
    String? productType,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      specialPrice: specialPrice ?? this.specialPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQty: stockQty ?? this.stockQty,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      productType: productType ?? this.productType,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

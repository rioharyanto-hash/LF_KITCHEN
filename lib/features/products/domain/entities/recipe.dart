import 'package:equatable/equatable.dart';

/// Entity untuk item dalam resep (Bahan Baku + Jumlah)
class RecipeItem extends Equatable {
  final String id;
  final String productId;
  final String rawMaterialId;
  final String? rawMaterialName; // Denormalized for UI
  final double quantity;
  final String unit; // gram, ml, pcs, dll
  final double? unitCost; // Current cost of the raw material per unit beli
  final double unitConversion; // 1 unit beli = x unit resep

  const RecipeItem({
    required this.id,
    required this.productId,
    required this.rawMaterialId,
    this.rawMaterialName,
    required this.quantity,
    required this.unit,
    this.unitCost,
    this.unitConversion = 1.0,
  });

  /// Hitung total cost untuk item ini dengan mempertimbangkan konversi satuan
  /// Contoh: Telur Rp 32.000/kg. Resep pakai 2 butir. Konversi 1kg = 16 butir.
  /// Total Cost = (32000 / 16) * 2 = 4000
  double get totalCost => ((unitCost ?? 0) / unitConversion) * quantity;

  RecipeItem copyWith({
    String? id,
    String? productId,
    String? rawMaterialId,
    String? rawMaterialName,
    double? quantity,
    String? unit,
    double? unitCost,
    double? unitConversion,
  }) {
    return RecipeItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      unitConversion: unitConversion ?? this.unitConversion,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    rawMaterialId,
    rawMaterialName,
    quantity,
    unit,
    unitCost,
    unitConversion,
  ];
}

/// Entity untuk Resep Produk (Kumpulan RecipeItem)
class ProductRecipe extends Equatable {
  final String productId;
  final List<RecipeItem> items;
  final int recipeYield; // Jumlah hasil produksi per resep

  const ProductRecipe({
    required this.productId,
    required this.items,
    this.recipeYield = 1,
  });

  /// Hitung total HPP (Harga Pokok Produksi) per UNIT produk
  /// Rumus: Total Biaya Semua Bahan / Hasil Produksi
  double get totalHpp {
    final totalMaterialCost = items.fold(
      0.0,
      (sum, item) => sum + item.totalCost,
    );
    return totalMaterialCost / (recipeYield > 0 ? recipeYield : 1);
  }

  @override
  List<Object?> get props => [productId, items, recipeYield];
}

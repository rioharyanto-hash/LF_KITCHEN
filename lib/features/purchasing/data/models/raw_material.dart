import 'package:flutter/foundation.dart';

/// Model untuk Raw Material (Bahan Baku)
@immutable
class RawMaterial {
  final String id;
  final String name;
  final String unit; // kg, gr, pcs, liter
  final double stockQty;
  final double? minStockAlert;
  final double? lastPurchasePrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.stockQty,
    this.minStockAlert,
    this.lastPurchasePrice,
    required this.createdAt,
    this.updatedAt,
  });

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String? ?? 'pcs',
      stockQty: (json['stock_qty'] as num?)?.toDouble() ?? 0,
      minStockAlert: (json['min_stock_alert'] as num?)?.toDouble(),
      lastPurchasePrice: (json['last_purchase_price'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'unit': unit,
      'stock_qty': stockQty,
      'min_stock_alert': minStockAlert,
      'last_purchase_price': lastPurchasePrice,
    };
  }

  RawMaterial copyWith({
    String? id,
    String? name,
    String? unit,
    double? stockQty,
    double? minStockAlert,
    double? lastPurchasePrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      stockQty: stockQty ?? this.stockQty,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if stock is low
  bool get isLowStock => minStockAlert != null && stockQty <= minStockAlert!;

  /// Display unit with quantity
  String get stockDisplay =>
      '${stockQty.toStringAsFixed(stockQty.truncateToDouble() == stockQty ? 0 : 1)} $unit';
}

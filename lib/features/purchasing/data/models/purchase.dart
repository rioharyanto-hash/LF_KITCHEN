import 'package:flutter/foundation.dart';

/// Model untuk Material Purchase (Pembelian Bahan)
@immutable
class Purchase {
  final String id;
  final String? supplierId;
  final String? supplierName; // Denormalized
  final DateTime purchaseDate;
  final double totalCost;
  final String? invoiceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<PurchaseItem>? items;

  const Purchase({
    required this.id,
    this.supplierId,
    this.supplierName,
    required this.purchaseDate,
    required this.totalCost,
    this.invoiceNumber,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['suppliers'] != null
          ? json['suppliers']['name'] as String?
          : null,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      invoiceNumber: json['invoice_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: json['purchase_items'] != null
          ? (json['purchase_items'] as List)
                .map((item) => PurchaseItem.fromJson(item))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'supplier_id': supplierId,
      'purchase_date': purchaseDate.toIso8601String(),
      'total_cost': totalCost,
      'invoice_number': invoiceNumber,
      'notes': notes,
    };
  }

  Purchase copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    double? totalCost,
    String? invoiceNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalCost: totalCost ?? this.totalCost,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

/// Model untuk Purchase Item (Detail Pembelian)
@immutable
class PurchaseItem {
  final String id;
  final String purchaseId;
  final String materialId;
  final String? materialName; // Denormalized
  final String? materialUnit; // Denormalized
  final double quantity;
  final double unitCost;
  final double subtotal;
  final DateTime? createdAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.materialId,
    this.materialName,
    this.materialUnit,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.createdAt,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String,
      materialId: json['material_id'] as String,
      materialName: json['raw_materials'] != null
          ? json['raw_materials']['name'] as String?
          : null,
      materialUnit: json['raw_materials'] != null
          ? json['raw_materials']['unit'] as String?
          : null,
      quantity: (json['quantity'] as num).toDouble(),
      unitCost: (json['unit_cost'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'purchase_id': purchaseId,
      'material_id': materialId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'subtotal': subtotal,
    };
  }

  PurchaseItem copyWith({
    String? id,
    String? purchaseId,
    String? materialId,
    String? materialName,
    String? materialUnit,
    double? quantity,
    double? unitCost,
    double? subtotal,
    DateTime? createdAt,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      materialUnit: materialUnit ?? this.materialUnit,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

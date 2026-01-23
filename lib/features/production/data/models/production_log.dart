/// Model untuk Log Produksi
class ProductionLog {
  final String id;
  final String orderId;
  final String? orderItemId;
  final String? productId;
  final String productName;
  final String? productSize;
  final String? customerName;
  final DateTime? deliveryDate;
  final int quantity;
  final String? producedBy;
  final DateTime createdAt;
  final String? notes;

  const ProductionLog({
    required this.id,
    required this.orderId,
    this.orderItemId,
    this.productId,
    required this.productName,
    this.productSize,
    this.customerName,
    this.deliveryDate,
    required this.quantity,
    this.producedBy,
    required this.createdAt,
    this.notes,
  });

  factory ProductionLog.fromJson(Map<String, dynamic> json) {
    return ProductionLog(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderItemId: json['order_item_id'] as String?,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String,
      productSize: json['product_size'] as String?,
      customerName: json['customer_name'] as String?,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      quantity: json['quantity'] as int,
      producedBy: json['produced_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'order_id': orderId,
      if (orderItemId != null) 'order_item_id': orderItemId,
      if (productId != null) 'product_id': productId,
      'product_name': productName,
      if (productSize != null) 'product_size': productSize,
      if (customerName != null) 'customer_name': customerName,
      if (deliveryDate != null)
        'delivery_date': deliveryDate!.toIso8601String().split('T')[0],
      'quantity': quantity,
      if (producedBy != null) 'produced_by': producedBy,
      if (notes != null) 'notes': notes,
    };
  }

  ProductionLog copyWith({
    String? id,
    String? orderId,
    String? orderItemId,
    String? productId,
    String? productName,
    String? productSize,
    String? customerName,
    DateTime? deliveryDate,
    int? quantity,
    String? producedBy,
    DateTime? createdAt,
    String? notes,
  }) {
    return ProductionLog(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSize: productSize ?? this.productSize,
      customerName: customerName ?? this.customerName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      quantity: quantity ?? this.quantity,
      producedBy: producedBy ?? this.producedBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

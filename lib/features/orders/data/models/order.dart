import '../../../products/data/models/product.dart';

/// Enum untuk tipe order
enum OrderType { po, direct }

/// Enum untuk status order
enum OrderStatus { draft, confirmed, processing, ready, completed, cancelled }

/// Enum untuk status pembayaran
enum PaymentStatus { unpaid, partial, paid }

/// Model untuk Order (Pesanan)
class Order {
  final String id;
  final String? customerId;
  final String? customerName; // Denormalized untuk display
  final String? customerPhone;
  final String? customerAddress;
  final DateTime orderDate;
  final OrderType orderType;
  final OrderStatus status;
  final double totalAmount;
  final double dpAmount;
  final PaymentStatus paymentStatus;
  final DateTime? deliveryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem>? items;

  const Order({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.orderDate,
    required this.orderType,
    required this.status,
    required this.totalAmount,
    this.dpAmount = 0,
    required this.paymentStatus,
    this.deliveryDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String?,
      customerName:
          json['customer_name'] as String? ??
          (json['customers'] != null ? json['customers']['name'] : null),
      customerPhone:
          json['customer_phone'] as String? ??
          (json['customers'] != null ? json['customers']['phone'] : null),
      customerAddress: json['customers'] != null
          ? json['customers']['address']
          : null,
      orderDate: DateTime.parse(json['order_date'] as String),
      orderType: OrderType.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['order_type'] as String).toUpperCase(),
        orElse: () => OrderType.direct,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
        orElse: () => OrderStatus.draft,
      ),
      totalAmount: (json['total_amount'] as num).toDouble(),
      dpAmount: (json['dp_amount'] as num?)?.toDouble() ?? 0,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['payment_status'] as String).toUpperCase(),
        orElse: () => PaymentStatus.unpaid,
      ),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: json['order_items'] != null
          ? (json['order_items'] as List)
                .map((item) => OrderItem.fromJson(item))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String(),
      'order_type': orderType.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'total_amount': totalAmount,
      'dp_amount': dpAmount,
      'payment_status': paymentStatus.name.toUpperCase(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'notes': notes,
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? orderDate,
    OrderType? orderType,
    OrderStatus? status,
    double? totalAmount,
    double? dpAmount,
    PaymentStatus? paymentStatus,
    DateTime? deliveryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderDate: orderDate ?? this.orderDate,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      dpAmount: dpAmount ?? this.dpAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  /// Sisa pembayaran
  double get remainingPayment => totalAmount - dpAmount;

  /// Apakah sudah lunas
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  /// Label status yang user-friendly
  String get statusLabel {
    switch (status) {
      case OrderStatus.draft:
        return 'Draft';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.processing:
        return 'Dalam Produksi';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  /// Label pembayaran
  String get paymentLabel {
    switch (paymentStatus) {
      case PaymentStatus.unpaid:
        return 'Belum Bayar';
      case PaymentStatus.partial:
        return 'DP';
      case PaymentStatus.paid:
        return 'Lunas';
    }
  }
}

/// Model untuk Order Item (Detail Pesanan)
class OrderItem {
  final String id;
  final String orderId;
  final String? productId; // Nullable for composite products like snack box
  final String? productName; // Denormalized
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime? createdAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId, // Now optional
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      productName:
          json['product_name'] as String? ??
          (json['products'] != null ? json['products']['name'] : null),
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    final json = <String, dynamic>{
      'order_id': orderId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
    // Only include product_id if not null
    if (productId != null && productId!.isNotEmpty) {
      json['product_id'] = productId;
    }
    // Include product_name for composite products
    if (productName != null) {
      json['product_name'] = productName;
    }
    return json;
  }

  /// Factory untuk membuat OrderItem dari Product
  factory OrderItem.fromProduct(Product product, int quantity, String orderId) {
    return OrderItem(
      id: '', // akan di-generate oleh DB
      orderId: orderId,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: product.unitPrice,
      subtotal: product.unitPrice * quantity,
    );
  }

  /// Copy with untuk update values
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

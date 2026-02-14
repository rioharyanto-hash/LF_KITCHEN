import '../../domain/entities/order.dart';

/// Model untuk Order (Data Layer)
class OrderModel extends Order {
  const OrderModel({
    required super.id,
    super.customerId,
    super.customerName,
    super.customerPhone,
    super.customerAddress,
    required super.orderDate,
    required super.orderType,
    required super.status,
    required super.totalAmount,
    super.dpAmount = 0,
    required super.paymentStatus,
    super.deliveryDate,
    super.notes,
    required super.createdAt,
    super.updatedAt,
    super.receiptNumber,
    super.shippingCost = 0,
    super.paymentMethod,
    List<OrderItemModel>? items,
  }) : super(items: items);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
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
      receiptNumber: json['receipt_number'] as String?,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      items: json['order_items'] != null
          ? (json['order_items'] as List)
                .map((item) => OrderItemModel.fromJson(item))
                .toList()
          : null,
    );
  }

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerAddress: order.customerAddress,
      orderDate: order.orderDate,
      orderType: order.orderType,
      status: order.status,
      totalAmount: order.totalAmount,
      dpAmount: order.dpAmount,
      paymentStatus: order.paymentStatus,
      deliveryDate: order.deliveryDate,
      notes: order.notes,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      receiptNumber: order.receiptNumber,
      shippingCost: order.shippingCost,
      paymentMethod: order.paymentMethod,
      items: order.items?.map((e) => OrderItemModel.fromEntity(e)).toList(),
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
      'receipt_number': receiptNumber,
      'shipping_cost': shippingCost,
      'payment_method': paymentMethod,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'order_date': orderDate.toIso8601String(),
      'order_type': orderType.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'total_amount': totalAmount,
      'dp_amount': dpAmount,
      'payment_status': paymentStatus.name.toUpperCase(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'notes': notes,
      'receipt_number': receiptNumber,
      'shipping_cost': shippingCost,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    super.productId,
    super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.subtotal,
    super.producedQty = 0,
    super.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      productName:
          json['product_name'] as String? ??
          (json['products'] != null ? json['products']['name'] : null),
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      producedQty: json['produced_qty'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  factory OrderItemModel.fromEntity(OrderItem item) {
    return OrderItemModel(
      id: item.id,
      orderId: item.orderId,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      subtotal: item.subtotal,
      producedQty: item.producedQty,
      createdAt: item.createdAt,
    );
  }

  Map<String, dynamic> toInsertJson() {
    final json = <String, dynamic>{
      'order_id': orderId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
    if (productId != null && productId!.isNotEmpty) {
      json['product_id'] = productId;
    }
    if (productName != null) {
      json['product_name'] = productName;
    }
    return json;
  }
}

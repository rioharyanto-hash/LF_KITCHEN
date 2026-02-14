import 'package:equatable/equatable.dart';

/// Enum untuk tipe order
enum OrderType { po, direct }

/// Enum untuk status order
enum OrderStatus { draft, confirmed, processing, ready, completed, cancelled }

/// Enum untuk status pembayaran
enum PaymentStatus { unpaid, partial, paid }

/// Entity untuk Order (Pesanan)
class Order extends Equatable {
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
  final String? receiptNumber; // Nomor kwitansi persisten
  final double shippingCost; // Ongkos kirim
  final String? paymentMethod; // Cara pembayaran
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
    this.receiptNumber,
    this.shippingCost = 0,
    this.paymentMethod,
    this.items,
  });

  /// Grand total (produk + ongkir)
  double get grandTotal => totalAmount + shippingCost;

  /// Sisa pembayaran (dari grand total)
  double get remainingPayment => grandTotal - dpAmount;

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

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
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
    String? receiptNumber,
    double? shippingCost,
    String? paymentMethod,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
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
      receiptNumber: receiptNumber ?? this.receiptNumber,
      shippingCost: shippingCost ?? this.shippingCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    customerPhone,
    customerAddress,
    orderDate,
    orderType,
    status,
    totalAmount,
    dpAmount,
    paymentStatus,
    deliveryDate,
    notes,
    createdAt,
    updatedAt,
    receiptNumber,
    shippingCost,
    paymentMethod,
    items,
  ];
}

/// Entity untuk Order Item
class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String? productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final int producedQty;
  final DateTime? createdAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.producedQty = 0,
    this.createdAt,
  });

  /// Apakah produksi sudah selesai untuk item ini
  bool get isProducedComplete => producedQty >= quantity;

  /// Sisa yang harus diproduksi
  int get remainingToProduce => quantity - producedQty;

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    int? producedQty,
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
      producedQty: producedQty ?? this.producedQty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    productId,
    productName,
    quantity,
    unitPrice,
    subtotal,
    producedQty,
    createdAt,
  ];
}

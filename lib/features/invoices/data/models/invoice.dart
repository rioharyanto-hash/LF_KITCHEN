import 'package:intl/intl.dart';

enum InvoiceStatus { unpaid, partial, paid }

/// Invoice Model - Tagihan Pelanggan
class Invoice {
  final String id;
  final String? orderId;
  final String? customerId;
  final String? customerName;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final double shippingCost;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    this.orderId,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.shippingCost = 0,
    this.dueDate,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Get shippingCost from joined orders table if available
    double shippingCost = 0;
    if (json['orders'] != null) {
      shippingCost = (json['orders']['shipping_cost'] as num?)?.toDouble() ?? 0;
    }

    return Invoice(
      id: json['id'],
      orderId: json['order_id'],
      customerId: json['customer_id'],
      customerName:
          json['customer_name'] ??
          (json['customers'] != null ? json['customers']['name'] : null),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      shippingCost: shippingCost,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'])
          : null,
      status: _parseStatus(json['status']),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  static InvoiceStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return InvoiceStatus.paid;
      case 'PARTIAL':
        return InvoiceStatus.partial;
      default:
        return InvoiceStatus.unpaid;
    }
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'order_id': orderId,
      'customer_id': customerId,
      'customer_name': customerName,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status.name.toUpperCase(),
      'notes': notes,
    };
  }

  String get formattedTotal => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(totalAmount);

  String get formattedRemaining => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(remainingAmount);

  String get formattedPaid => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(paidAmount);

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != InvoiceStatus.paid;
}

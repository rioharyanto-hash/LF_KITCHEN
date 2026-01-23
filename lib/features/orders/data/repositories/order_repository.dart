import '../../../../core/data/base_repository.dart';
import '../../../../core/services/invoice_number_service.dart';
import '../../../../core/utils/result.dart';
import '../models/order.dart';

/// Repository untuk operasi CRUD Order
class OrderRepository extends BaseRepository {
  OrderRepository(super.client);

  static const String _tableName = 'orders';
  static const String _itemsTable = 'order_items';

  /// Ambil semua orders dengan join ke customers
  Future<Result<List<Order>>> getAll({
    OrderType? type,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return safeCall(() async {
      var query = client
          .from(_tableName)
          .select(
            '*, customers(name, phone, address), order_items(*, products(name))',
          );

      if (type != null) {
        query = query.eq('order_type', type.name.toUpperCase());
      }
      if (status != null) {
        query = query.eq('status', status.name.toUpperCase());
      }
      if (fromDate != null) {
        query = query.gte('order_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('order_date', toDate.toIso8601String());
      }

      final response = await query.order('order_date', ascending: false);

      return (response as List).map((json) => Order.fromJson(json)).toList();
    });
  }

  /// Ambil orders untuk hari ini
  Future<Result<List<Order>>> getTodayOrders() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getAll(fromDate: startOfDay, toDate: endOfDay);
  }

  /// Ambil orders yang siap diambil (delivery_date = hari ini, status = READY)
  Future<Result<List<Order>>> getReadyForPickup() async {
    return safeCall(() async {
      final today = DateTime.now();
      final todayStr = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String().split('T')[0];

      final response = await client
          .from(_tableName)
          .select('*, customers(name, phone)')
          .eq('delivery_date', todayStr)
          .eq('status', 'READY')
          .order('created_at', ascending: true);

      return (response as List).map((json) => Order.fromJson(json)).toList();
    });
  }

  /// Ambil order berdasarkan ID dengan items
  Future<Result<Order>> getById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select('*, customers(name, phone), order_items(*, products(name))')
          .eq('id', id)
          .single();

      return Order.fromJson(response);
    });
  }

  /// Buat order baru dengan items
  Future<Result<Order>> create(Order order, List<OrderItem> items) async {
    return safeCall(() async {
      // Insert order
      final orderResponse = await client
          .from(_tableName)
          .insert(order.toInsertJson())
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Insert order items
      if (items.isNotEmpty) {
        final itemsJson = items.map((item) {
          final json = item.toInsertJson();
          json['order_id'] = orderId;
          return json;
        }).toList();

        await client.from(_itemsTable).insert(itemsJson);
      }

      // Fetch complete order with relations
      return await getById(orderId).then((result) => result.dataOrNull!);
    });
  }

  /// Update order with items
  /// If items is null, only updates order details
  Future<Result<Order>> update(Order order, [List<OrderItem>? items]) async {
    return safeCall(() async {
      // 1. Update order details
      await client
          .from(_tableName)
          .update(order.toInsertJson())
          .eq('id', order.id);

      // 2. Update items if provided
      if (items != null) {
        // Fetch existing items to match by product_id or product_name
        final existingItems = await client
            .from(_itemsTable)
            .select()
            .eq('order_id', order.id);

        final existingMap = <String, Map<String, dynamic>>{};
        for (final item in existingItems as List) {
          final key = (item['product_id'] as String?) ?? item['product_name'] as String;
          existingMap[key] = item as Map<String, dynamic>;
        }

        // Track which existing items are updated or deleted
        final processedKeys = <String>{};

        for (final item in items) {
          final key = item.productId ?? item.productName ?? '';
          
          if (existingMap.containsKey(key)) {
            // Update existing item (preserves id and produced_qty)
            final existing = existingMap[key]!;
            final updateJson = item.toInsertJson();
            await client
                .from(_itemsTable)
                .update(updateJson)
                .eq('id', existing['id']);
            processedKeys.add(key);
          } else {
            // Insert new item
            final insertJson = item.toInsertJson();
            insertJson['order_id'] = order.id;
            await client.from(_itemsTable).insert(insertJson);
          }
        }

        // Delete items that are no longer in the list
        final keysToDelete = existingMap.keys.where((k) => !processedKeys.contains(k));
        for (final key in keysToDelete) {
          await client
              .from(_itemsTable)
              .delete()
              .eq('id', existingMap[key]!['id']);
        }
      }

      return await getById(order.id).then((result) => result.dataOrNull!);
    });
  }

  /// Update status order (generates receipt_number on first confirm)
  Future<Result<void>> updateStatus(String id, OrderStatus status) async {
    return safeCall(() async {
      final updates = <String, dynamic>{'status': status.name.toUpperCase()};

      // Generate receipt_number saat order dikonfirmasi (jika belum ada)
      if (status == OrderStatus.confirmed) {
        // Fetch current order to check if receipt_number exists
        final currentOrder = await client
            .from(_tableName)
            .select(
              'receipt_number, order_type, notes, order_items(*, products(name))',
            )
            .eq('id', id)
            .single();

        if (currentOrder['receipt_number'] == null) {
          // Determine invoice type based on order
          String invoiceType = InvoiceNumberService.po;

          final orderType = currentOrder['order_type']
              ?.toString()
              .toUpperCase();
          if (orderType == 'DIRECT') {
            invoiceType = InvoiceNumberService.kasir;
          } else {
            final notes = currentOrder['notes']?.toString() ?? '';
            // Check for Paketan (notes contain === ===)
            if (notes.contains('=== ') && notes.contains(' ===')) {
              invoiceType = InvoiceNumberService.paketan;
            }
            // Check for Snack Box
            else if (notes.toUpperCase().contains('SNACK BOX') ||
                notes.toUpperCase().contains('SNACKBOX')) {
              invoiceType = InvoiceNumberService.snackBox;
            } else {
              // Check items for Snack Box
              final items = currentOrder['order_items'] as List? ?? [];
              final hasSnackBox = items.any((item) {
                final productName =
                    (item['products']?['name'] ?? item['product_name'] ?? '')
                        .toString()
                        .toUpperCase();
                return productName.contains('SNACK BOX') ||
                    productName.contains('SNACKBOX');
              });
              if (hasSnackBox) {
                invoiceType = InvoiceNumberService.snackBox;
              }
            }
          }

          // Generate new receipt number
          final receiptNumber = await InvoiceNumberService.getNextNumber(
            invoiceType,
          );
          updates['receipt_number'] = receiptNumber;
        }
      }

      await client.from(_tableName).update(updates).eq('id', id);
    });
  }

  /// Update payment status
  Future<Result<void>> updatePaymentStatus(
    String id,
    PaymentStatus status,
    double? dpAmount, {
    double? totalAmount,
    String? notes,
    // New field
    String? paymentMethod,
  }) async {
    return safeCall(() async {
      final updates = <String, dynamic>{
        'payment_status': status.name.toUpperCase(),
      };
      if (dpAmount != null) {
        updates['dp_amount'] = dpAmount;
      }
      if (totalAmount != null) {
        updates['total_amount'] = totalAmount;
      }
      if (notes != null) {
        updates['notes'] = notes;
      }
      if (paymentMethod != null) {
        updates['payment_method'] = paymentMethod;
      }
      await client.from(_tableName).update(updates).eq('id', id);
    });
  }

  /// Update shipping cost
  Future<Result<void>> updateShipping(String id, double shippingCost) async {
    return safeCall(() async {
      await client
          .from(_tableName)
          .update({'shipping_cost': shippingCost})
          .eq('id', id);
    });
  }

  /// Hapus order
  Future<Result<void>> delete(String id) async {
    return safeCall(() async {
      await client.from(_tableName).delete().eq('id', id);
    });
  }

  /// Hitung total penjualan hari ini
  Future<Result<double>> getTodaySalesTotal() async {
    return safeCall(() async {
      final today = DateTime.now();
      final todayStr = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String().split('T')[0];

      final response = await client
          .from(_tableName)
          .select('total_amount')
          .gte('order_date', todayStr)
          .inFilter('status', ['COMPLETED', 'READY']);

      double total = 0;
      for (final row in response as List) {
        total += (row['total_amount'] as num).toDouble();
      }
      return total;
    });
  }

  /// Hitung jumlah PO pending
  Future<Result<int>> getPendingPOCount() async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select('id')
          .eq('order_type', 'PO')
          .inFilter('status', ['DRAFT', 'CONFIRMED', 'PROCESSING']);

      return (response as List).length;
    });
  }
}

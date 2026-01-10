import '../../../../core/data/base_repository.dart';
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

  /// Update order
  Future<Result<Order>> update(Order order) async {
    return safeCall(() async {
      await client
          .from(_tableName)
          .update(order.toInsertJson())
          .eq('id', order.id);

      return await getById(order.id).then((result) => result.dataOrNull!);
    });
  }

  /// Update status order
  Future<Result<void>> updateStatus(String id, OrderStatus status) async {
    return safeCall(() async {
      await client
          .from(_tableName)
          .update({'status': status.name.toUpperCase()})
          .eq('id', id);
    });
  }

  /// Update payment status
  Future<Result<void>> updatePaymentStatus(
    String id,
    PaymentStatus status,
    double? dpAmount,
  ) async {
    return safeCall(() async {
      final updates = <String, dynamic>{
        'payment_status': status.name.toUpperCase(),
      };
      if (dpAmount != null) {
        updates['dp_amount'] = dpAmount;
      }
      await client.from(_tableName).update(updates).eq('id', id);
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

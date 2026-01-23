import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/result.dart';
import '../models/production_log.dart';

/// Repository untuk mengelola Production Logs dan Stock
class ProductionRepository {
  final SupabaseClient _client;

  ProductionRepository(this._client);

  /// Catat produksi - menambah produced_qty di order_items dan stock produk
  Future<Result<ProductionLog>> recordProduction({
    required String orderId,
    required String orderItemId,
    String? productId,
    required String productName,
    String? productSize,
    String? customerName,
    DateTime? deliveryDate,
    required int quantity,
    String? producedBy,
    String? notes,
  }) async {
    try {
      // 1. Insert production log
      final logData = {
        'order_id': orderId,
        'order_item_id': orderItemId,
        if (productId != null) 'product_id': productId,
        'product_name': productName,
        if (productSize != null) 'product_size': productSize,
        if (customerName != null) 'customer_name': customerName,
        if (deliveryDate != null)
          'delivery_date': deliveryDate.toIso8601String().split('T')[0],
        'quantity': quantity,
        if (producedBy != null) 'produced_by': producedBy,
        if (notes != null) 'notes': notes,
      };

      final logResponse = await _client
          .from('production_logs')
          .insert(logData)
          .select()
          .single();

      // 2. Update produced_qty di order_items
      await _client.rpc(
        'increment_produced_qty',
        params: {'item_id': orderItemId, 'qty': quantity},
      );

      // 3. Update stock produk (jika productId ada)
      if (productId != null) {
        await _client.rpc(
          'increment_stock',
          params: {'p_id': productId, 'qty': quantity},
        );
      }

      return Success(ProductionLog.fromJson(logResponse));
    } catch (e) {
      return Failure('Gagal mencatat produksi: $e');
    }
  }

  /// Dapatkan semua production logs dengan filter
  Future<Result<List<ProductionLog>>> getProductionLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? customerName,
    String? productName,
    String? productSize,
  }) async {
    try {
      var query = _client.from('production_logs').select();

      if (startDate != null) {
        query = query.gte(
          'delivery_date',
          startDate.toIso8601String().split('T')[0],
        );
      }
      if (endDate != null) {
        query = query.lte(
          'delivery_date',
          endDate.toIso8601String().split('T')[0],
        );
      }
      if (customerName != null && customerName.isNotEmpty) {
        query = query.ilike('customer_name', '%$customerName%');
      }
      if (productName != null && productName.isNotEmpty) {
        query = query.ilike('product_name', '%$productName%');
      }
      if (productSize != null && productSize.isNotEmpty) {
        query = query.eq('product_size', productSize);
      }

      final response = await query.order('created_at', ascending: false);

      final logs = (response as List)
          .map((json) => ProductionLog.fromJson(json))
          .toList();

      return Success(logs);
    } catch (e) {
      return Failure('Gagal memuat log produksi: $e');
    }
  }

  /// Kurangi stock saat order completed
  Future<Result<void>> decrementStockForOrder(String orderId) async {
    try {
      // Get order items
      final items = await _client
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', orderId);

      for (final item in items) {
        final productId = item['product_id'] as String?;
        final quantity = item['quantity'] as int;

        if (productId != null) {
          await _client.rpc(
            'decrement_stock',
            params: {'p_id': productId, 'qty': quantity},
          );
        }
      }

      return const Success(null);
    } catch (e) {
      return Failure('Gagal mengurangi stock: $e');
    }
  }

  /// Hapus production log (untuk koreksi)
  Future<Result<void>> deleteProductionLog(String logId) async {
    try {
      await _client.from('production_logs').delete().eq('id', logId);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menghapus log: $e');
    }
  }
}

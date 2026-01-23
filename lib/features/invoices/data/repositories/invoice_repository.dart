import '../../../../core/data/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/invoice.dart';

/// Invoice Repository - Data access for invoices table
/// Menggunakan BaseRepository untuk konsistensi error handling
class InvoiceRepository extends BaseRepository {
  static const _tableName = 'invoices';

  InvoiceRepository(super.client);

  /// Get all invoices with optional filters
  Future<Result<List<Invoice>>> getAll({
    InvoiceStatus? status,
    String? customerId,
  }) async {
    return safeCall(() async {
      var query = client
          .from(_tableName)
          .select('*, customers(name), orders(shipping_cost)');

      if (status != null) {
        query = query.eq('status', status.name.toUpperCase());
      }

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) => Invoice.fromJson(json)).toList();
    });
  }

  /// Get unpaid invoices only
  Future<Result<List<Invoice>>> getUnpaid() async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select('*, customers(name), orders(shipping_cost)')
          .neq('status', 'PAID')
          .order('due_date', ascending: true);

      return (response as List).map((json) => Invoice.fromJson(json)).toList();
    });
  }

  /// Get invoices by customer
  Future<Result<List<Invoice>>> getByCustomer(String customerId) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select('*, customers(name), orders(shipping_cost)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Invoice.fromJson(json)).toList();
    });
  }

  /// Create new invoice
  Future<Result<Invoice>> create(Invoice invoice) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .insert(invoice.toInsertJson())
          .select()
          .single();

      return Invoice.fromJson(response);
    });
  }

  /// Record payment on invoice
  Future<Result<Invoice>> recordPayment(String id, double amount) async {
    return safeCall(() async {
      // Get current invoice
      final current = await client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      final currentPaid = (current['paid_amount'] as num?)?.toDouble() ?? 0;
      final total = (current['total_amount'] as num?)?.toDouble() ?? 0;
      final newPaid = currentPaid + amount;
      final newRemaining = total - newPaid;

      String newStatus;
      if (newRemaining <= 0) {
        newStatus = 'PAID';
      } else if (newPaid > 0) {
        newStatus = 'PARTIAL';
      } else {
        newStatus = 'UNPAID';
      }

      final response = await client
          .from(_tableName)
          .update({
            'paid_amount': newPaid,
            'remaining_amount': newRemaining > 0 ? newRemaining : 0,
            'status': newStatus,
          })
          .eq('id', id)
          .select()
          .single();

      return Invoice.fromJson(response);
    });
  }

  /// Delete invoice
  Future<Result<void>> delete(String id) async {
    return safeCall(() async {
      await client.from(_tableName).delete().eq('id', id);
    });
  }

  /// Get total unpaid amount for a customer
  Future<Result<double>> getCustomerDebt(String customerId) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select('remaining_amount')
          .eq('customer_id', customerId)
          .neq('status', 'PAID');

      double total = 0;
      for (final row in response as List) {
        total += (row['remaining_amount'] as num?)?.toDouble() ?? 0;
      }

      return total;
    });
  }
}

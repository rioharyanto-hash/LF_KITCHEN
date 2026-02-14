import '../../../../core/utils/result.dart';
import '../entities/order.dart';

/// Interface untuk Order Repository
abstract class IOrderRepository {
  /// Ambil semua orders
  Future<Result<List<Order>>> getAll({
    OrderType? type,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  });

  /// Ambil orders untuk hari ini
  Future<Result<List<Order>>> getTodayOrders();

  /// Ambil orders yang siap diambil (delivery_date = hari ini, status = READY)
  Future<Result<List<Order>>> getReadyForPickup();

  /// Ambil order berdasarkan ID
  Future<Result<Order>> getById(String id);

  /// Buat order baru
  Future<Result<Order>> create(Order order, List<OrderItem> items);

  /// Update order
  Future<Result<Order>> update(Order order, [List<OrderItem>? items]);

  /// Update status order
  Future<Result<void>> updateStatus(String id, OrderStatus status);

  /// Update payment status
  Future<Result<void>> updatePaymentStatus(
    String id,
    PaymentStatus status, {
    double? dpAmount,
    double? totalAmount,
    String? notes,
    String? paymentMethod,
  });

  /// Update shipping cost
  Future<Result<void>> updateShipping(String id, double shippingCost);

  /// Hapus order
  Future<Result<void>> delete(String id);

  /// Hitung total penjualan hari ini
  Future<Result<double>> getTodaySalesTotal();

  /// Hitung jumlah PO pending
  Future<Result<int>> getPendingPOCount();
}

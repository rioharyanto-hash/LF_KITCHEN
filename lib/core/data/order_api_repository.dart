import '../services/api_service.dart';
import '../utils/result.dart';
import '../../features/orders/data/models/order.dart';

/// Repository untuk operasi CRUD Order via API
class OrderApiRepository {
  final ApiService _api;

  OrderApiRepository(this._api);

  /// Ambil semua order
  Future<Result<List<Order>>> getAll() async {
    return _api.get<List<Order>>(
      '/orders',
      (json) => (json as List).map((e) => Order.fromJson(e)).toList(),
    );
  }

  /// Ambil order hari ini
  Future<Result<List<Order>>> getToday() async {
    return _api.get<List<Order>>(
      '/orders/today',
      (json) => (json as List).map((e) => Order.fromJson(e)).toList(),
    );
  }

  /// Ambil order berdasarkan ID
  Future<Result<Order>> getById(String id) async {
    return _api.get<Order>('/orders/$id', (json) => Order.fromJson(json));
  }

  /// Filter order berdasarkan status
  Future<Result<List<Order>>> getByStatus(String status) async {
    return _api.get<List<Order>>(
      '/orders',
      (json) => (json as List).map((e) => Order.fromJson(e)).toList(),
      queryParams: {'status': status},
    );
  }

  /// Buat order baru
  Future<Result<Order>> create(Order order, List<OrderItem> items) async {
    final body = order.toJson();
    body['items'] = items.map((e) => e.toJson()).toList();

    return _api.post<Order>('/orders', body, (json) => Order.fromJson(json));
  }

  /// Update order
  Future<Result<Order>> update(Order order) async {
    return _api.put<Order>(
      '/orders/${order.id}',
      order.toJson(),
      (json) => Order.fromJson(json),
    );
  }

  /// Update status order
  Future<Result<Order>> updateStatus(String id, OrderStatus status) async {
    return _api.patch<Order>('/orders/$id/status', {
      'status': status.name,
    }, (json) => Order.fromJson(json));
  }

  /// Update payment order
  Future<Result<Order>> updatePayment(
    String id,
    PaymentStatus paymentStatus, {
    double? dpAmount,
  }) async {
    final body = <String, dynamic>{'payment_status': paymentStatus.name};
    if (dpAmount != null) {
      body['dp_amount'] = dpAmount;
    }

    return _api.patch<Order>(
      '/orders/$id/payment',
      body,
      (json) => Order.fromJson(json),
    );
  }

  /// Hapus order
  Future<Result<void>> delete(String id) async {
    return _api.delete('/orders/$id');
  }
}

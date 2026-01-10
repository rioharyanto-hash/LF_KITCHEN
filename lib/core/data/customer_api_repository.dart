import '../services/api_service.dart';
import '../utils/result.dart';
import '../../features/customers/data/models/customer.dart';

/// Repository untuk operasi CRUD Customer via API
class CustomerApiRepository {
  final ApiService _api;

  CustomerApiRepository(this._api);

  /// Ambil semua customer
  Future<Result<List<Customer>>> getAll() async {
    return _api.get<List<Customer>>(
      '/customers',
      (json) => (json as List).map((e) => Customer.fromJson(e)).toList(),
    );
  }

  /// Ambil customer berdasarkan ID
  Future<Result<Customer>> getById(String id) async {
    return _api.get<Customer>(
      '/customers/$id',
      (json) => Customer.fromJson(json),
    );
  }

  /// Cari customer
  Future<Result<List<Customer>>> search(String query) async {
    return _api.get<List<Customer>>(
      '/customers',
      (json) => (json as List).map((e) => Customer.fromJson(e)).toList(),
      queryParams: {'q': query},
    );
  }

  /// Tambah customer baru
  Future<Result<Customer>> create(Customer customer) async {
    return _api.post<Customer>(
      '/customers',
      customer.toInsertJson(),
      (json) => Customer.fromJson(json),
    );
  }

  /// Update customer
  Future<Result<Customer>> update(Customer customer) async {
    return _api.put<Customer>(
      '/customers/${customer.id}',
      customer.toInsertJson(),
      (json) => Customer.fromJson(json),
    );
  }

  /// Hapus customer
  Future<Result<void>> delete(String id) async {
    return _api.delete('/customers/$id');
  }
}

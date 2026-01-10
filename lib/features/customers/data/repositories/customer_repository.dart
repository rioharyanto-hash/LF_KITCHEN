import '../../../../core/data/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/customer.dart';

/// Repository untuk operasi CRUD Customer
class CustomerRepository extends BaseRepository {
  CustomerRepository(super.client);

  static const String _tableName = 'customers';

  /// Ambil semua customer
  Future<Result<List<Customer>>> getAll() async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .order('name', ascending: true);

      return (response as List).map((json) => Customer.fromJson(json)).toList();
    });
  }

  /// Ambil customer berdasarkan ID
  Future<Result<Customer>> getById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return Customer.fromJson(response);
    });
  }

  /// Cari customer berdasarkan nama atau nomor HP
  Future<Result<List<Customer>>> search(String query) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .order('name', ascending: true);

      return (response as List).map((json) => Customer.fromJson(json)).toList();
    });
  }

  /// Tambah customer baru
  Future<Result<Customer>> create(Customer customer) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .insert(customer.toInsertJson())
          .select()
          .single();

      return Customer.fromJson(response);
    });
  }

  /// Update customer
  Future<Result<Customer>> update(Customer customer) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .update(customer.toInsertJson())
          .eq('id', customer.id)
          .select()
          .single();

      return Customer.fromJson(response);
    });
  }

  /// Hapus customer
  Future<Result<void>> delete(String id) async {
    return safeCall(() async {
      await client.from(_tableName).delete().eq('id', id);
    });
  }
}

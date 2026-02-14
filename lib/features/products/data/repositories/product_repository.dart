import '../../../../core/data/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/product.dart';

/// Repository untuk operasi CRUD Product
/// Menggunakan Repository Pattern - tidak ada hardcoded/mock data
class ProductRepository extends BaseRepository {
  ProductRepository(super.client);

  static const String _tableName = 'products';

  /// Ambil semua produk dengan pagination
  Future<Result<List<Product>>> getAll({
    int page = 1,
    int pageSize = 20,
  }) async {
    return safeCall(() async {
      final range = getPaginationRange(page, pageSize);

      final response = await client
          .from(_tableName)
          .select()
          .order('name', ascending: true)
          .range(range.start, range.end);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    });
  }

  /// Ambil produk berdasarkan ID
  Future<Result<Product>> getById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return Product.fromJson(response);
    });
  }

  /// Ambil produk berdasarkan kategori
  Future<Result<List<Product>>> getByCategory(String category) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .eq('category', category)
          .order('name', ascending: true);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    });
  }

  /// Cari produk berdasarkan nama
  Future<Result<List<Product>>> search(String query) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    });
  }

  /// Tambah produk baru
  Future<Result<Product>> create(Product product) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .insert(product.toInsertJson())
          .select()
          .single();

      return Product.fromJson(response);
    });
  }

  /// Update produk
  Future<Result<Product>> update(Product product) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .update(product.toInsertJson())
          .eq('id', product.id)
          .select()
          .single();

      return Product.fromJson(response);
    });
  }

  /// Hapus produk
  Future<Result<void>> delete(String id) async {
    return safeCall(() async {
      await client.from(_tableName).delete().eq('id', id);
    });
  }

  /// Update stok produk
  Future<Result<Product>> updateStock(String id, int newStock) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .update({'stock_qty': newStock})
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response);
    });
  }

  /// Ambil produk dengan stok rendah (untuk alert)
  Future<Result<List<Product>>> getLowStock({int threshold = 10}) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select()
          .lte('stock_qty', threshold)
          .order('stock_qty', ascending: true);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    });
  }
}

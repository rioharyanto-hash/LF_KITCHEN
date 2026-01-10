import '../services/api_service.dart';
import '../utils/result.dart';
import '../../features/products/data/models/product.dart';

/// Repository untuk operasi CRUD Product via API
class ProductApiRepository {
  final ApiService _api;

  ProductApiRepository(this._api);

  /// Ambil semua product
  Future<Result<List<Product>>> getAll() async {
    return _api.get<List<Product>>(
      '/products',
      (json) => (json as List).map((e) => Product.fromJson(e)).toList(),
    );
  }

  /// Ambil product berdasarkan ID
  Future<Result<Product>> getById(String id) async {
    return _api.get<Product>('/products/$id', (json) => Product.fromJson(json));
  }

  /// Ambil product berdasarkan kategori
  Future<Result<List<Product>>> getByCategory(String category) async {
    return _api.get<List<Product>>(
      '/products',
      (json) => (json as List).map((e) => Product.fromJson(e)).toList(),
      queryParams: {'category': category},
    );
  }

  /// Tambah product baru
  Future<Result<Product>> create(Product product) async {
    return _api.post<Product>(
      '/products',
      product.toInsertJson(),
      (json) => Product.fromJson(json),
    );
  }

  /// Update product
  Future<Result<Product>> update(Product product) async {
    return _api.put<Product>(
      '/products/${product.id}',
      product.toInsertJson(),
      (json) => Product.fromJson(json),
    );
  }

  /// Hapus product
  Future<Result<void>> delete(String id) async {
    return _api.delete('/products/$id');
  }
}

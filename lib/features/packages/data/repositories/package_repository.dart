import '../../../../core/data/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/package.dart';

/// Repository untuk operasi CRUD Package (Paket)
class PackageRepository extends BaseRepository {
  PackageRepository(super.client);

  static const String _tableName = 'packages';
  static const String _itemsTable = 'package_items';

  /// Ambil semua paket dengan items
  Future<Result<List<Package>>> getAll({bool activeOnly = true}) async {
    return safeCall(() async {
      final query = client.from(_tableName).select('''
        *,
        package_items(*, products(name))
      ''');

      final filteredQuery = activeOnly ? query.eq('is_active', true) : query;

      final response = await filteredQuery.order('name', ascending: true);
      return (response as List).map((json) => Package.fromJson(json)).toList();
    });
  }

  /// Ambil paket berdasarkan ID dengan items
  Future<Result<Package>> getById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select('''
        *,
        package_items(*, products(name))
      ''')
          .eq('id', id)
          .single();

      return Package.fromJson(response);
    });
  }

  /// Buat paket baru
  Future<Result<Package>> create(Package package) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .insert(package.toInsertJson())
          .select()
          .single();

      return Package.fromJson(response);
    });
  }

  /// Update paket
  Future<Result<Package>> update(Package package) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .update(package.toInsertJson())
          .eq('id', package.id)
          .select()
          .single();

      return Package.fromJson(response);
    });
  }

  /// Hapus paket
  Future<Result<void>> delete(String id) async {
    return safeCall(() async {
      await client.from(_tableName).delete().eq('id', id);
    });
  }

  /// Toggle status aktif paket
  Future<Result<Package>> toggleActive(String id, bool isActive) async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .update({'is_active': isActive})
          .eq('id', id)
          .select()
          .single();

      return Package.fromJson(response);
    });
  }

  // ============ Package Items ============

  /// Tambah item ke paket
  Future<Result<PackageItem>> addItem(PackageItem item) async {
    return safeCall(() async {
      final response = await client
          .from(_itemsTable)
          .insert(item.toInsertJson())
          .select()
          .single();

      return PackageItem.fromJson(response);
    });
  }

  /// Update item paket
  Future<Result<PackageItem>> updateItem(PackageItem item) async {
    return safeCall(() async {
      final response = await client
          .from(_itemsTable)
          .update(item.toInsertJson())
          .eq('id', item.id)
          .select()
          .single();

      return PackageItem.fromJson(response);
    });
  }

  /// Hapus item dari paket
  Future<Result<void>> deleteItem(String itemId) async {
    return safeCall(() async {
      await client.from(_itemsTable).delete().eq('id', itemId);
    });
  }

  /// Hapus semua item dari paket
  Future<Result<void>> deleteAllItems(String packageId) async {
    return safeCall(() async {
      await client.from(_itemsTable).delete().eq('package_id', packageId);
    });
  }
}

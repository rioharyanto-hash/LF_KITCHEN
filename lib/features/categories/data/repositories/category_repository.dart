import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/result.dart';
import '../models/category.dart';

/// Repository untuk operasi CRUD Kategori
class CategoryRepository {
  final SupabaseClient _client;
  static const String _table = 'categories';

  CategoryRepository(this._client);

  /// Ambil semua kategori, diurutkan berdasarkan sort_order
  Future<Result<List<Category>>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      final categories = (response as List)
          .map((json) => Category.fromJson(json))
          .toList();

      return Success(categories);
    } catch (e) {
      return Failure('Gagal mengambil data kategori: $e');
    }
  }

  /// Buat kategori baru
  Future<Result<Category>> create(Category category) async {
    try {
      final response = await _client
          .from(_table)
          .insert(category.toInsertJson())
          .select()
          .single();

      return Success(Category.fromJson(response));
    } catch (e) {
      return Failure('Gagal membuat kategori: $e');
    }
  }

  /// Update kategori
  Future<Result<Category>> update(Category category) async {
    try {
      final response = await _client
          .from(_table)
          .update({'name': category.name, 'sort_order': category.sortOrder})
          .eq('id', category.id)
          .select()
          .single();

      return Success(Category.fromJson(response));
    } catch (e) {
      return Failure('Gagal mengupdate kategori: $e');
    }
  }

  /// Hapus kategori
  Future<Result<void>> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Gagal menghapus kategori: $e');
    }
  }
}

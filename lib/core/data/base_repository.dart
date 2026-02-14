import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/result.dart';

/// Base Repository untuk semua repository
/// Menyediakan akses ke Supabase client dan error handling standar
abstract class BaseRepository {
  final SupabaseClient client;

  BaseRepository(this.client);

  /// Helper untuk wrap operasi database dengan error handling
  Future<Result<T>> safeCall<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Success(result);
    } on PostgrestException catch (e) {
      return Failure(e.message, code: e.code, originalError: e);
    } on AuthException catch (e) {
      return Failure(e.message, code: e.statusCode, originalError: e);
    } on StorageException catch (e) {
      return Failure(e.message, code: e.statusCode, originalError: e);
    } catch (e) {
      return Failure('Terjadi kesalahan: ${e.toString()}', originalError: e);
    }
  }

  /// Helper untuk mendapatkan pagination range (start, end)
  /// page dimulai dari 1
  ({int start, int end}) getPaginationRange(int page, int pageSize) {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;
    return (start: start, end: end);
  }
}

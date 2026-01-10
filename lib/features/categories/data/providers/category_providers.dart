import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

/// Provider untuk CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CategoryRepository(client);
});

/// State Notifier untuk Category List
class CategoryListNotifier extends StateNotifier<AsyncState<List<Category>>> {
  final CategoryRepository _repository;

  CategoryListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadCategories() async {
    state = const AsyncState.loading();
    final result = await _repository.getAll();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> createCategory(Category category) async {
    final result = await _repository.create(category);
    if (result.isSuccess) {
      await loadCategories();
      return true;
    }
    return false;
  }

  Future<bool> updateCategory(Category category) async {
    final result = await _repository.update(category);
    if (result.isSuccess) {
      await loadCategories();
      return true;
    }
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      await loadCategories();
      return true;
    }
    return false;
  }
}

/// Provider untuk Category List State
final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncState<List<Category>>>((
      ref,
    ) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoryListNotifier(repository);
    });

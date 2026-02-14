import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

/// Provider untuk ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProductRepository(client);
});

/// State Notifier untuk Products List
/// State Notifier untuk Products List
class ProductListNotifier extends StateNotifier<AsyncState<List<Product>>> {
  final ProductRepository _repository;

  // Pagination State
  int _page = 1;
  static const int _pageSize = 1000;
  bool _hasMore = true;

  ProductListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      // Keep data for pull-to-refresh UX
      state = state.copyWithLoading();
    } else {
      _page = 1;
      _hasMore = true;
      state = const AsyncState.loading();
    }

    final result = await _repository.getAll(page: _page, pageSize: _pageSize);
    result.when(
      success: (data) {
        _hasMore = data.length >= _pageSize;
        state = AsyncState.success(data);
      },
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<void> loadMore() async {
    // Prevent duplicate calls or calls when no more data
    if (!_hasMore || state.isLoading) return;

    // Keep current data while loading next page
    state = state.copyWithLoading();

    final nextPage = _page + 1;
    final result = await _repository.getAll(
      page: nextPage,
      pageSize: _pageSize,
    );

    result.when(
      success: (newProducts) {
        if (newProducts.length < _pageSize) {
          _hasMore = false;
        } else {
          _page = nextPage;
        }

        // Append new data to existing data
        final currentList = state.data ?? [];
        state = AsyncState.success([...currentList, ...newProducts]);
      },
      failure: (message, code) {
        // In case of error, revert to success with old data + show error?
        // Or just show error state (which hides list)?
        // For better UX, we might want a 'toast' error instead of replacing the screen.
        // But AsyncState is simple. Let's just set error for now.
        // Users can Retry via UI.
        state = AsyncState.error(message, errorCode: code);
      },
    );
  }

  Future<void> refresh() async {
    await loadProducts(isRefresh: true);
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      // Reset to initial load
      await loadProducts();
      return;
    }

    // Search resets pagination context effectively
    state = const AsyncState.loading();
    final result = await _repository.search(query);
    result.when(
      success: (data) {
        // Disabling pagination for search results for now
        _hasMore = false;
        state = AsyncState.success(data);
      },
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> deleteProduct(String id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      // Refresh list to ensure consistency (keeping current page would be consistent but complex)
      // Simpler: Reload from scratch
      await loadProducts(isRefresh: true);
      return true;
    }
    return false;
  }
}

/// Provider untuk Product List State
final productListProvider =
    StateNotifierProvider<ProductListNotifier, AsyncState<List<Product>>>((
      ref,
    ) {
      final repository = ref.watch(productRepositoryProvider);
      return ProductListNotifier(repository);
    });

/// State Notifier untuk Single Product (Create/Edit)
class ProductFormNotifier extends StateNotifier<AsyncState<Product?>> {
  final ProductRepository _repository;

  ProductFormNotifier(this._repository) : super(const AsyncState.initial());

  Future<bool> createProduct(Product product) async {
    state = const AsyncState.loading();
    final result = await _repository.create(product);
    return result.when(
      success: (data) {
        state = AsyncState.success(data);
        return true;
      },
      failure: (message, code) {
        state = AsyncState.error(message, errorCode: code);
        return false;
      },
    );
  }

  Future<bool> updateProduct(Product product) async {
    state = const AsyncState.loading();
    final result = await _repository.update(product);
    return result.when(
      success: (data) {
        state = AsyncState.success(data);
        return true;
      },
      failure: (message, code) {
        state = AsyncState.error(message, errorCode: code);
        return false;
      },
    );
  }

  void reset() {
    state = const AsyncState.initial();
  }
}

/// Provider untuk Product Form State
final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, AsyncState<Product?>>((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return ProductFormNotifier(repository);
    });

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
class ProductListNotifier extends StateNotifier<AsyncState<List<Product>>> {
  final ProductRepository _repository;

  ProductListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadProducts() async {
    state = const AsyncState.loading();
    final result = await _repository.getAll();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<void> refresh() async {
    state = state.copyWithLoading();
    final result = await _repository.getAll();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }
    state = const AsyncState.loading();
    final result = await _repository.search(query);
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> deleteProduct(String id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      await loadProducts();
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

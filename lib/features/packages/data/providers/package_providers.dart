import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../models/package.dart';
import '../repositories/package_repository.dart';

/// Provider untuk PackageRepository
final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PackageRepository(client);
});

/// State Notifier untuk Packages List
class PackageListNotifier extends StateNotifier<AsyncState<List<Package>>> {
  final PackageRepository _repository;

  PackageListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadPackages({bool activeOnly = true}) async {
    state = const AsyncState.loading();
    final result = await _repository.getAll(activeOnly: activeOnly);
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<void> refresh({bool activeOnly = true}) async {
    state = state.copyWithLoading();
    final result = await _repository.getAll(activeOnly: activeOnly);
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> deletePackage(String id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      await loadPackages();
      return true;
    }
    return false;
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    final result = await _repository.toggleActive(id, isActive);
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    return false;
  }
}

/// Provider untuk Package List State
final packageListProvider =
    StateNotifierProvider<PackageListNotifier, AsyncState<List<Package>>>((
      ref,
    ) {
      final repository = ref.watch(packageRepositoryProvider);
      return PackageListNotifier(repository);
    });

/// State Notifier untuk Single Package (Create/Edit)
class PackageFormNotifier extends StateNotifier<AsyncState<Package?>> {
  final PackageRepository _repository;

  PackageFormNotifier(this._repository) : super(const AsyncState.initial());

  Future<bool> createPackage(Package package) async {
    state = const AsyncState.loading();
    final result = await _repository.create(package);
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

  Future<bool> updatePackage(Package package) async {
    state = const AsyncState.loading();
    final result = await _repository.update(package);
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

  Future<bool> addItem(PackageItem item) async {
    final result = await _repository.addItem(item);
    return result.isSuccess;
  }

  Future<bool> updateItem(PackageItem item) async {
    final result = await _repository.updateItem(item);
    return result.isSuccess;
  }

  Future<bool> deleteItem(String itemId) async {
    final result = await _repository.deleteItem(itemId);
    return result.isSuccess;
  }

  void reset() {
    state = const AsyncState.initial();
  }
}

/// Provider untuk Package Form State
final packageFormProvider =
    StateNotifierProvider<PackageFormNotifier, AsyncState<Package?>>((ref) {
      final repository = ref.watch(packageRepositoryProvider);
      return PackageFormNotifier(repository);
    });

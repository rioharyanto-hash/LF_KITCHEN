import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../models/supplier.dart';
import '../models/raw_material.dart';
import '../models/purchase.dart';
import '../repositories/purchase_repository.dart';

/// Provider untuk PurchaseRepository
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PurchaseRepository(client);
});

// ==================== SUPPLIERS PROVIDERS ====================

/// State untuk list suppliers
final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, AsyncState<List<Supplier>>>(
      (ref) => SupplierListNotifier(ref.watch(purchaseRepositoryProvider)),
    );

class SupplierListNotifier extends StateNotifier<AsyncState<List<Supplier>>> {
  final PurchaseRepository _repository;

  SupplierListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadSuppliers() async {
    state = const AsyncState.loading();
    final result = await _repository.getAllSuppliers();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> createSupplier(Supplier supplier) async {
    final result = await _repository.createSupplier(supplier);
    if (result.isSuccess) {
      await loadSuppliers();
      return true;
    }
    return false;
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    final result = await _repository.updateSupplier(supplier);
    if (result.isSuccess) {
      await loadSuppliers();
      return true;
    }
    return false;
  }

  Future<bool> deleteSupplier(String id) async {
    final result = await _repository.deleteSupplier(id);
    if (result.isSuccess) {
      await loadSuppliers();
      return true;
    }
    return false;
  }
}

// ==================== RAW MATERIALS PROVIDERS ====================

/// State untuk list materials
final materialListProvider =
    StateNotifierProvider<MaterialListNotifier, AsyncState<List<RawMaterial>>>(
      (ref) => MaterialListNotifier(ref.watch(purchaseRepositoryProvider)),
    );

class MaterialListNotifier
    extends StateNotifier<AsyncState<List<RawMaterial>>> {
  final PurchaseRepository _repository;

  MaterialListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadMaterials() async {
    state = const AsyncState.loading();
    final result = await _repository.getAllMaterials();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> createMaterial(RawMaterial material) async {
    final result = await _repository.createMaterial(material);
    if (result.isSuccess) {
      await loadMaterials();
      return true;
    }
    return false;
  }

  Future<bool> updateMaterial(RawMaterial material) async {
    final result = await _repository.updateMaterial(material);
    if (result.isSuccess) {
      await loadMaterials();
      return true;
    }
    return false;
  }

  Future<bool> deleteMaterial(String id) async {
    final result = await _repository.deleteMaterial(id);
    if (result.isSuccess) {
      await loadMaterials();
      return true;
    }
    return false;
  }
}

/// Provider untuk low stock materials count
final lowStockCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  final result = await repository.getLowStockMaterials();
  return result.dataOrNull?.length ?? 0;
});

// ==================== PURCHASES PROVIDERS ====================

/// State untuk list purchases
final purchaseListProvider =
    StateNotifierProvider<PurchaseListNotifier, AsyncState<List<Purchase>>>(
      (ref) => PurchaseListNotifier(ref.watch(purchaseRepositoryProvider)),
    );

class PurchaseListNotifier extends StateNotifier<AsyncState<List<Purchase>>> {
  final PurchaseRepository _repository;

  PurchaseListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    String? supplierId,
  }) async {
    state = const AsyncState.loading();
    final result = await _repository.getAllPurchases(
      fromDate: fromDate,
      toDate: toDate,
      supplierId: supplierId,
    );
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> createPurchase(
    Purchase purchase,
    List<PurchaseItem> items,
  ) async {
    final result = await _repository.createPurchase(purchase, items);
    if (result.isSuccess) {
      await loadPurchases();
      return true;
    }
    return false;
  }

  Future<bool> deletePurchase(String id) async {
    final result = await _repository.deletePurchase(id);
    if (result.isSuccess) {
      await loadPurchases();
      return true;
    }
    return false;
  }
}

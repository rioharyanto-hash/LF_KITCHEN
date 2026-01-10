import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

/// Provider untuk CustomerRepository
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CustomerRepository(client);
});

/// State Notifier untuk Customers List
class CustomerListNotifier extends StateNotifier<AsyncState<List<Customer>>> {
  final CustomerRepository _repository;

  CustomerListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadCustomers() async {
    state = const AsyncState.loading();
    final result = await _repository.getAll();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      await loadCustomers();
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

  Future<bool> deleteCustomer(String id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      await loadCustomers();
      return true;
    }
    return false;
  }
}

/// Provider untuk Customer List State
final customerListProvider =
    StateNotifierProvider<CustomerListNotifier, AsyncState<List<Customer>>>((
      ref,
    ) {
      final repository = ref.watch(customerRepositoryProvider);
      return CustomerListNotifier(repository);
    });

/// State Notifier untuk Single Customer (Create/Edit)
class CustomerFormNotifier extends StateNotifier<AsyncState<Customer?>> {
  final CustomerRepository _repository;

  CustomerFormNotifier(this._repository) : super(const AsyncState.initial());

  Future<bool> createCustomer(Customer customer) async {
    state = const AsyncState.loading();
    final result = await _repository.create(customer);
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

  Future<bool> updateCustomer(Customer customer) async {
    state = const AsyncState.loading();
    final result = await _repository.update(customer);
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

/// Provider untuk Customer Form State
final customerFormProvider =
    StateNotifierProvider<CustomerFormNotifier, AsyncState<Customer?>>((ref) {
      final repository = ref.watch(customerRepositoryProvider);
      return CustomerFormNotifier(repository);
    });

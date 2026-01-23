import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';

/// Provider for InvoiceRepository
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return InvoiceRepository(client);
});

/// Notifier for Invoice List
class InvoiceListNotifier extends StateNotifier<AsyncState<List<Invoice>>> {
  final InvoiceRepository _repository;

  InvoiceListNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadInvoices({InvoiceStatus? status}) async {
    state = const AsyncState.loading();
    final result = await _repository.getAll(status: status);
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (msg, code) => state = AsyncState.error(msg),
    );
  }

  Future<void> loadUnpaid() async {
    state = const AsyncState.loading();
    final result = await _repository.getUnpaid();
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (msg, code) => state = AsyncState.error(msg),
    );
  }

  Future<bool> createInvoice(Invoice invoice) async {
    final result = await _repository.create(invoice);
    final success = result.isSuccess;
    if (success) {
      await loadInvoices();
    }
    return success;
  }

  Future<bool> recordPayment(String id, double amount) async {
    final result = await _repository.recordPayment(id, amount);
    final success = result.isSuccess;
    if (success) {
      await loadInvoices();
    }
    return success;
  }

  Future<bool> deleteInvoice(String id) async {
    final result = await _repository.delete(id);
    final success = result.isSuccess;
    if (success) {
      await loadInvoices();
    }
    return success;
  }
}

/// Provider for Invoice List
final invoiceListProvider =
    StateNotifierProvider<InvoiceListNotifier, AsyncState<List<Invoice>>>((
      ref,
    ) {
      final repository = ref.watch(invoiceRepositoryProvider);
      return InvoiceListNotifier(repository);
    });

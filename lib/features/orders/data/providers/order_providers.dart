import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../../../production/data/repositories/production_repository.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

/// Provider untuk OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderRepository(client);
});

/// State Notifier untuk Orders List
class OrderListNotifier extends StateNotifier<AsyncState<List<Order>>> {
  final OrderRepository _repository;
  final ProductionRepository? _productionRepo;

  // Store last filter params for refresh
  OrderType? _lastType;
  OrderStatus? _lastStatus;

  OrderListNotifier(this._repository, [this._productionRepo])
    : super(const AsyncState.initial());

  Future<void> loadOrders({OrderType? type, OrderStatus? status}) async {
    // Store params for refresh
    _lastType = type;
    _lastStatus = status;

    state = const AsyncState.loading();
    final result = await _repository.getAll(type: type, status: status);
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<void> loadPOOrders() async {
    await loadOrders(type: OrderType.po);
  }

  Future<void> refresh() async {
    state = state.copyWithLoading();
    // Use stored params to maintain filter
    final result = await _repository.getAll(
      type: _lastType,
      status: _lastStatus,
    );
    result.when(
      success: (data) => state = AsyncState.success(data),
      failure: (message, code) =>
          state = AsyncState.error(message, errorCode: code),
    );
  }

  Future<bool> updateStatus(String id, OrderStatus status) async {
    final result = await _repository.updateStatus(id, status);
    if (result.isSuccess) {
      // Decrement stock when order is completed
      if (status == OrderStatus.completed && _productionRepo != null) {
        await _productionRepo.decrementStockForOrder(id);
      }
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> deleteOrder(String id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> updatePaymentStatus(
    String id,
    PaymentStatus status, {
    double? dpAmount,
    double? totalAmount,
    String? notes,
    String? paymentMethod,
  }) async {
    final result = await _repository.updatePaymentStatus(
      id,
      status,
      dpAmount,
      totalAmount: totalAmount,
      notes: notes,
      paymentMethod: paymentMethod,
    );
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    return false;
  }
}

/// Provider untuk Order List State
final orderListProvider =
    StateNotifierProvider<OrderListNotifier, AsyncState<List<Order>>>((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      final client = ref.watch(supabaseClientProvider);
      final productionRepo = ProductionRepository(client);
      return OrderListNotifier(repository, productionRepo);
    });

/// State class for Order Form
class OrderFormState {
  final Order? order;
  final List<OrderItem> items;
  final bool isLoading;
  final String? error;

  const OrderFormState({
    this.order,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  OrderFormState copyWith({
    Order? order,
    List<OrderItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return OrderFormState(
      order: order ?? this.order,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
}

/// State Notifier untuk Order Form (Create/Edit)
class OrderFormNotifier extends StateNotifier<OrderFormState> {
  final OrderRepository _repository;

  OrderFormNotifier(this._repository) : super(const OrderFormState());

  void addItem(OrderItem item) {
    final existingIndex = state.items.indexWhere(
      (i) => i.productId == item.productId,
    );
    if (existingIndex >= 0) {
      // Update quantity if product already exists
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        subtotal: (existing.quantity + item.quantity) * existing.unitPrice,
      );
      final newItems = [...state.items];
      newItems[existingIndex] = updated;
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    final updated = item.copyWith(
      quantity: quantity,
      subtotal: quantity * item.unitPrice,
    );
    final newItems = [...state.items];
    newItems[index] = updated;
    state = state.copyWith(items: newItems);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final newItems = [...state.items];
    newItems.removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void clearItems() {
    state = state.copyWith(items: []);
  }

  Future<Result<Order>> createOrder({
    required String? customerId,
    required OrderType orderType,
    required DateTime? deliveryDate,
    required double dpAmount,
    required String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final order = Order(
      id: '',
      customerId: customerId,
      orderDate: DateTime.now(),
      orderType: orderType,
      status: OrderStatus.draft,
      totalAmount: state.totalAmount,
      dpAmount: dpAmount,
      paymentStatus: dpAmount >= state.totalAmount
          ? PaymentStatus.paid
          : dpAmount > 0
          ? PaymentStatus.partial
          : PaymentStatus.unpaid,
      deliveryDate: deliveryDate,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final result = await _repository.create(order, state.items);

    result.when(
      success: (data) {
        state = state.copyWith(isLoading: false, order: data);
      },
      failure: (message, code) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );

    return result;
  }

  Future<Result<Order>> updateOrder({
    required String orderId,
    required String? customerId,
    required DateTime? deliveryDate,
    required double dpAmount,
    required String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final order = Order(
      id: orderId,
      customerId: customerId,
      orderDate: DateTime.now(),
      orderType: OrderType.po,
      status: OrderStatus.draft,
      totalAmount: state.totalAmount,
      dpAmount: dpAmount,
      paymentStatus: dpAmount >= state.totalAmount
          ? PaymentStatus.paid
          : dpAmount > 0
          ? PaymentStatus.partial
          : PaymentStatus.unpaid,
      deliveryDate: deliveryDate,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final result = await _repository.update(order);

    result.when(
      success: (data) {
        state = state.copyWith(isLoading: false, order: data);
      },
      failure: (message, code) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );

    return result;
  }

  void reset() {
    state = const OrderFormState();
  }
}

/// Provider untuk Order Form State
final orderFormProvider =
    StateNotifierProvider<OrderFormNotifier, OrderFormState>((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      return OrderFormNotifier(repository);
    });

/// Provider untuk Dashboard Stats
final todaySalesTotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getTodaySalesTotal();
  return result.dataOrNull ?? 0;
});

final pendingPOCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getPendingPOCount();
  return result.dataOrNull ?? 0;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../orders/domain/repositories/i_order_repository.dart';
import '../repositories/production_repository.dart';

/// Model untuk item produksi (agregasi per produk)
class ProductionItem {
  final String productId;
  final String productName;
  final String? productSize;
  final int totalQuantity;
  final List<ProductionOrderDetail> orders;

  ProductionItem({
    required this.productId,
    required this.productName,
    this.productSize,
    required this.totalQuantity,
    required this.orders,
  });
}

/// Detail pesanan per item produksi
class ProductionOrderDetail {
  final String orderId;
  final String orderItemId; // For updating produced_qty
  final String? productId; // For updating stock
  final String productName;
  final String? productSize;
  final String customerName;
  final int quantity;
  final int producedQty; // Jumlah sudah diproduksi
  final DateTime? deliveryDate;
  final DateTime? orderDate; // Tanggal pemesanan

  ProductionOrderDetail({
    required this.orderId,
    required this.orderItemId,
    this.productId,
    required this.productName,
    this.productSize,
    required this.customerName,
    required this.quantity,
    this.producedQty = 0,
    this.deliveryDate,
    this.orderDate,
  });

  /// Apakah produksi sudah selesai
  bool get isComplete => producedQty >= quantity;

  /// Sisa yang harus diproduksi
  int get remaining => quantity - producedQty;
}

/// Model untuk produksi yang dikelompokkan per tanggal
class ProductionByDate {
  final DateTime? date;
  final List<ProductionItem> items;

  ProductionByDate({this.date, required this.items});

  int get totalItems => items.fold(0, (sum, item) => sum + item.totalQuantity);
}

/// State untuk Production Dashboard
class ProductionState {
  final List<ProductionByDate> productionByDate;
  final int totalItems;
  final int pendingItems;
  final int completedItems;

  ProductionState({
    required this.productionByDate,
    required this.totalItems,
    required this.pendingItems,
    required this.completedItems,
  });

  factory ProductionState.empty() => ProductionState(
    productionByDate: [],
    totalItems: 0,
    pendingItems: 0,
    completedItems: 0,
  );
}

/// Provider untuk Production
class ProductionNotifier extends StateNotifier<AsyncState<ProductionState>> {
  final IOrderRepository _repository;

  ProductionNotifier(this._repository) : super(const AsyncState.initial());

  Future<void> loadProduction() async {
    state = const AsyncState.loading();

    // Calculate date range: overdue (last 30 days) to next 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingLimit = today.add(const Duration(days: 8)); // 7 days ahead
    final overdueLimit = today.subtract(
      const Duration(days: 30),
    ); // 30 days back

    // Fetch orders that need production (DRAFT, CONFIRMED or PROCESSING)
    final draftResult = await _repository.getAll(
      type: OrderType.po,
      status: OrderStatus.draft,
    );
    final confirmedResult = await _repository.getAll(
      type: OrderType.po,
      status: OrderStatus.confirmed,
    );
    final processingResult = await _repository.getAll(
      type: OrderType.po,
      status: OrderStatus.processing,
    );

    List<Order> allOrders = [];

    draftResult.when(
      success: (data) => allOrders.addAll(data),
      failure: (msg, code) {},
    );

    confirmedResult.when(
      success: (data) => allOrders.addAll(data),
      failure: (msg, code) {},
    );

    processingResult.when(
      success: (data) => allOrders.addAll(data),
      failure: (msg, code) {},
    );

    allOrders = allOrders.where((order) {
      if (order.deliveryDate == null) {
        return true; // Include orders without date
      }
      return order.deliveryDate!.isAfter(overdueLimit) &&
          order.deliveryDate!.isBefore(upcomingLimit);
    }).toList();

    // Aggregate by product and date
    final productionState = _aggregateOrders(allOrders);
    state = AsyncState.success(productionState);
  }

  ProductionState _aggregateOrders(List<Order> orders) {
    // Group by delivery date first
    final Map<String, Map<String, ProductionItem>> dateProductMap = {};

    int totalItems = 0;

    for (final order in orders) {
      final dateKey =
          order.deliveryDate?.toIso8601String().split('T')[0] ?? 'no_date';

      if (!dateProductMap.containsKey(dateKey)) {
        dateProductMap[dateKey] = {};
      }

      for (final item in order.items ?? []) {
        // Skip main SNACK BOX header (it's just a container)
        if (item.productName?.toUpperCase() == 'SNACK BOX') continue;

        // For snack box sub-items, clean up the name (remove "  - " prefix)
        String productName = item.productName ?? 'Produk';
        if (productName.startsWith('  -')) {
          productName = productName.substring(3).trim(); // Remove "  -" prefix
        }

        // Skip Dus/packaging - it's not a production item
        if (productName.toLowerCase() == 'dus') continue;

        final productId =
            item.productId ?? productName; // Use name as key if no productId
        final int qty = item.quantity;
        totalItems += qty;

        if (!dateProductMap[dateKey]!.containsKey(productId)) {
          dateProductMap[dateKey]![productId] = ProductionItem(
            productId: productId,
            productName: productName,
            totalQuantity: 0,
            orders: [],
          );
        }

        final existingItem = dateProductMap[dateKey]![productId]!;
        dateProductMap[dateKey]![productId] = ProductionItem(
          productId: productId,
          productName: productName,
          totalQuantity: existingItem.totalQuantity + qty,
          orders: [
            ...existingItem.orders,
            ProductionOrderDetail(
              orderId: order.id,
              orderItemId: item.id,
              productId: item.productId,
              productName: productName,
              productSize: null, // OrderItem doesn't have size yet
              customerName: order.customerName ?? 'Guest',
              quantity: qty,
              producedQty: item.producedQty,
              deliveryDate: order.deliveryDate,
              orderDate: order.orderDate,
            ),
          ],
        );
      }
    }

    // Convert to list sorted by date
    final productionByDate = dateProductMap.entries.map((entry) {
      final dateStr = entry.key;
      final products = entry.value.values.toList();

      DateTime? date;
      if (dateStr != 'no_date') {
        date = DateTime.tryParse(dateStr);
      }

      return ProductionByDate(date: date, items: products);
    }).toList();

    // Sort by date (null dates at the end)
    productionByDate.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });

    return ProductionState(
      productionByDate: productionByDate,
      totalItems: totalItems,
      pendingItems: totalItems, // For now, all are pending
      completedItems: 0,
    );
  }
}

/// Provider untuk OrderRepository (reuse dari orders)
final productionRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderRepository(client);
});

/// Provider untuk ProductionNotifier
final productionProvider =
    StateNotifierProvider<ProductionNotifier, AsyncState<ProductionState>>((
      ref,
    ) {
      final repository = ref.watch(productionRepositoryProvider);
      return ProductionNotifier(repository);
    });

/// Provider untuk ProductionRepository (untuk record produksi dan stock)
final prodLogRepoProvider = Provider<ProductionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProductionRepository(client);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';

/// Dashboard Page - Halaman utama aplikasi
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(orderListProvider.notifier).loadOrders();
      ref.read(productListProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final ordersState = ref.watch(orderListProvider);
    final productsState = ref.watch(productListProvider);

    // Calculate stats from orders
    final orders = ordersState.data ?? <Order>[];
    final products = productsState.data ?? <Product>[];

    final today = DateTime.now();
    final todayOrders = orders.where(
      (o) =>
          o.orderDate.year == today.year &&
          o.orderDate.month == today.month &&
          o.orderDate.day == today.day,
    );

    final todaySales = todayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final todayCount = todayOrders.length;

    final pendingPO = orders
        .where(
          (o) =>
              o.orderType == OrderType.po &&
              o.status != OrderStatus.completed &&
              o.status != OrderStatus.cancelled,
        )
        .length;

    final readyOrders = orders
        .where((o) => o.status == OrderStatus.ready)
        .length;

    final lowStock = products.where((p) => p.stockQty < 5).length;

    // Reminders: orders that need attention (DRAFT, CONFIRMED, PROCESSING, READY)
    // Sort by: CONFIRMED first (urgent), then PROCESSING, DRAFT, READY last
    // Within same status, sort by delivery date (nearest first)
    int _statusPriority(OrderStatus status) {
      switch (status) {
        case OrderStatus.confirmed:
          return 0; // Highest priority - needs to be processed
        case OrderStatus.processing:
          return 1;
        case OrderStatus.draft:
          return 2;
        case OrderStatus.ready:
          return 3; // Lowest priority - already done, just waiting pickup
        default:
          return 99;
      }
    }

    final reminderOrders =
        orders
            .where(
              (o) =>
                  o.status == OrderStatus.draft ||
                  o.status == OrderStatus.confirmed ||
                  o.status == OrderStatus.processing ||
                  o.status == OrderStatus.ready,
            )
            .toList()
          ..sort((a, b) {
            // First compare by status priority
            final statusCompare = _statusPriority(
              a.status,
            ).compareTo(_statusPriority(b.status));
            if (statusCompare != 0) return statusCompare;

            // Then by delivery date (nearest first, null dates at end)
            if (a.deliveryDate == null && b.deliveryDate == null) return 0;
            if (a.deliveryDate == null) return 1;
            if (b.deliveryDate == null) return -1;
            return a.deliveryDate!.compareTo(b.deliveryDate!);
          });
    final displayOrders = reminderOrders.take(10).toList(); // Show up to 10

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(orderListProvider.notifier).loadOrders();
              ref.read(productListProvider.notifier).loadProducts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(
                    isDesktop: isDesktop,
                    todaySales: todaySales,
                    todayCount: todayCount,
                    pendingPO: pendingPO,
                    readyOrders: readyOrders,
                    lowStock: lowStock,
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Aksi Cepat',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Reminders
                  Text(
                    'Reminders',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildRecentOrders(displayOrders),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards({
    required bool isDesktop,
    required double todaySales,
    required int todayCount,
    required int pendingPO,
    required int readyOrders,
    required int lowStock,
  }) {
    final cards = [
      _SummaryCard(
        title: 'Penjualan Hari Ini',
        value: _currencyFormat.format(todaySales),
        icon: Icons.attach_money,
        color: AppColors.success,
        subtitle: '$todayCount transaksi',
      ),
      _SummaryCard(
        title: 'PO Pending',
        value: '$pendingPO',
        icon: Icons.pending_actions,
        color: AppColors.warning,
        subtitle: 'Menunggu proses',
      ),
      _SummaryCard(
        title: 'Siap Diambil',
        value: '$readyOrders',
        icon: Icons.check_circle_outline,
        color: AppColors.primary,
        subtitle: 'Pesanan ready',
      ),
      _SummaryCard(
        title: 'Stok Rendah',
        value: '$lowStock',
        icon: Icons.warning_amber,
        color: AppColors.error,
        subtitle: 'Butuh restok',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.5 : 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionButton(
          icon: Icons.add_shopping_cart,
          label: 'Pesanan Baru',
          onTap: () => context.go('/orders'),
        ),
        _QuickActionButton(
          icon: Icons.point_of_sale,
          label: 'Kasir / POS',
          onTap: () => context.go('/pos'),
        ),
        _QuickActionButton(
          icon: Icons.inventory_2_outlined,
          label: 'Beli Bahan',
          onTap: () => context.go('/purchasing'),
        ),
      ],
    );
  }

  Widget _buildRecentOrders(List<Order> orders) {
    if (orders.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada pesanan',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesanan akan muncul di sini',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = orders[index];
          final isUrgent =
              order.deliveryDate != null &&
              order.deliveryDate!.isBefore(
                DateTime.now().add(const Duration(days: 2)),
              );
          final isTomorrow =
              order.deliveryDate != null &&
              order.deliveryDate!.day ==
                  DateTime.now().add(const Duration(days: 1)).day &&
              order.deliveryDate!.month ==
                  DateTime.now().add(const Duration(days: 1)).month;

          return InkWell(
            onTap: () => context.go(
              '/orders?highlight=${order.id}&status=${order.status.name}',
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Date Box on Left
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? AppColors.warning
                          : _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isTomorrow ? 'BESOK' : 'AMBIL',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          order.deliveryDate != null
                              ? DateFormat('dd').format(order.deliveryDate!)
                              : '-',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          order.deliveryDate != null
                              ? DateFormat(
                                  'MMM yyyy',
                                ).format(order.deliveryDate!).toUpperCase()
                              : '',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.customerName ?? 'Pelanggan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (isUrgent)
                              const Text('❗', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  order.status,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.status.name[0].toUpperCase() +
                                    order.status.name.substring(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(order.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PO #${order.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount on Right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(order.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Created ${DateFormat('dd/MM').format(order.orderDate)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return Colors.grey;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.processing:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.completed:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

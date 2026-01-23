import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';

/// Dashboard Page - Halaman utama aplikasi dengan desain modern
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
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

    // Reminders: orders that need attention
    int statusPriority(OrderStatus status) {
      switch (status) {
        case OrderStatus.confirmed:
          return 0;
        case OrderStatus.processing:
          return 1;
        case OrderStatus.draft:
          return 2;
        case OrderStatus.ready:
          return 3;
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
            final statusCompare = statusPriority(
              a.status,
            ).compareTo(statusPriority(b.status));
            if (statusCompare != 0) return statusCompare;
            if (a.deliveryDate == null && b.deliveryDate == null) return 0;
            if (a.deliveryDate == null) return 1;
            if (b.deliveryDate == null) return -1;
            return a.deliveryDate!.compareTo(b.deliveryDate!);
          });
    final displayOrders = reminderOrders.take(10).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Custom App Bar Header
          _buildHeader(context),

          // Main Content
          Expanded(
            child: ordersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Cards
                          _buildSummaryCards(
                            context: context,
                            isDesktop: isDesktop,
                            todaySales: todaySales,
                            todayCount: todayCount,
                            pendingPO: pendingPO,
                            readyOrders: readyOrders,
                            lowStock: lowStock,
                          ),
                          const SizedBox(height: 32),

                          // Quick Actions
                          _buildSectionTitle(
                            context,
                            icon: Icons.bolt,
                            title: 'Aksi Cepat',
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 32),

                          // Reminders
                          _buildSectionTitle(
                            context,
                            icon: Icons.event_note,
                            title: 'Pengingat Pengambilan',
                            trailing: TextButton(
                              onPressed: () => context.go('/orders'),
                              child: const Text('Lihat Semua'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildReminderList(displayOrders),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Bar
          if (isDesktop)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi, pelanggan, atau produk...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            )
          else
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

          const Spacer(),

          // Actions
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(orderListProvider.notifier).loadOrders();
              ref.read(productListProvider.notifier).loadProducts();
            },
            tooltip: 'Refresh',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifikasi',
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isDesktop) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 32,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 16),
            // User Profile
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Admin LF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'Store Manager',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: isMobile ? 18 : 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSummaryCards({
    required BuildContext context,
    required bool isDesktop,
    required double todaySales,
    required int todayCount,
    required int pendingPO,
    required int readyOrders,
    required int lowStock,
  }) {
    final cards = [
      _SummaryCardData(
        title: 'Penjualan Hari Ini',
        value: AppFormatters.formatCurrency(todaySales),
        subtitle: '$todayCount transaksi berhasil',
        icon: Icons.payments,
        color: Colors.green,
      ),
      _SummaryCardData(
        title: 'PO Pending',
        value: '$pendingPO',
        subtitle: 'Menunggu diproses',
        icon: Icons.pending_actions,
        color: Colors.amber,
      ),
      _SummaryCardData(
        title: 'Siap Diambil',
        value: '$readyOrders',
        subtitle: 'Pesanan sudah siap',
        icon: Icons.check_circle,
        color: Colors.blue,
      ),
      _SummaryCardData(
        title: 'Stok Rendah',
        value: '$lowStock',
        subtitle: 'Butuh restok segera',
        icon: Icons.warning,
        color: Colors.red,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.6 : 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _SummaryCard(data: cards[index]),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 900;
    final int crossAxisCount = isMobile ? 2 : isTablet ? 3 : 4;
    final double aspect = isMobile ? 3.5 : isTablet ? 2.8 : 2.0;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspect,
      children: [
        SizedBox(width: double.infinity, child: _QuickActionButton(icon: Icons.people, label: 'Pelanggan', onTap: () => context.go('/customers'))),
        SizedBox(width: double.infinity, child: _QuickActionButton(icon: Icons.inventory_2, label: 'Master Produk', onTap: () => context.go('/products'))),
        SizedBox(width: double.infinity, child: _QuickActionButton(icon: Icons.receipt_long, label: 'Tagihan', onTap: () => context.go('/invoices'))),
        SizedBox(width: double.infinity, child: _QuickActionButton(icon: Icons.factory, label: 'Produksi', onTap: () => context.go('/production'))),
      ],
    );
  }

  Widget _buildReminderList(List<Order> orders) {
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
                  Icons.event_available,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada pengingat',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semua pesanan sudah selesai',
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
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) => _ReminderItem(order: orders[index]),
      ),
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: data.color.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    data.icon,
                    color: data.color.shade600,
                    size: isMobile ? 14 : 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Flexible(
              child: Text(
                data.value,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: data.color.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              data.subtitle,
              style: TextStyle(
                fontSize: isMobile ? 9 : 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final Order order;

  const _ReminderItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final isToday =
        order.deliveryDate != null &&
        order.deliveryDate!.day == DateTime.now().day &&
        order.deliveryDate!.month == DateTime.now().month;
    final isTomorrow =
        order.deliveryDate != null &&
        order.deliveryDate!.difference(DateTime.now()).inDays == 0 &&
        order.deliveryDate!.day ==
            DateTime.now().add(const Duration(days: 1)).day;

    Color getStatusColor() {
      switch (order.status) {
        case OrderStatus.ready:
          return Colors.green;
        case OrderStatus.confirmed:
          return Colors.amber;
        case OrderStatus.processing:
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return InkWell(
      onTap: () => context.go(
        '/orders?view=list&highlight=${order.id}&status=${order.status.name}',
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Box
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: getStatusColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'TODAY' : (isTomorrow ? 'BESOK' : 'AMBIL'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    order.deliveryDate != null
                        ? DateFormat('dd').format(order.deliveryDate!)
                        : '-',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    order.deliveryDate != null
                        ? DateFormat(
                            'MMM',
                          ).format(order.deliveryDate!).toUpperCase()
                        : '',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Order Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.customerName ?? 'Pelanggan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PO #${order.id.substring(0, 8)} • ${order.items?.length ?? 0} items',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.formatCurrency(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Created ${DateFormat('dd/MM').format(order.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.more_vert, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case OrderStatus.ready:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case OrderStatus.confirmed:
        bgColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        break;
      case OrderStatus.processing:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

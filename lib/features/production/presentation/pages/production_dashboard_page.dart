import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/production_providers.dart';

/// Production Dashboard Page - Dashboard Produksi
class ProductionDashboardPage extends ConsumerStatefulWidget {
  const ProductionDashboardPage({super.key});

  @override
  ConsumerState<ProductionDashboardPage> createState() =>
      _ProductionDashboardPageState();
}

class _ProductionDashboardPageState
    extends ConsumerState<ProductionDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productionProvider.notifier).loadProduction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productionState = ref.watch(productionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(productionProvider.notifier).loadProduction(),
          ),
        ],
      ),
      body: productionState.when(
        initial: () => const Center(child: Text('Memuat data...')),
        loading: () => const Center(child: CircularProgressIndicator()),
        success: (data) => _buildContent(context, data),
        error: (message, code) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $message'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(productionProvider.notifier).loadProduction(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductionState data) {
    if (data.productionByDate.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Tidak ada item yang perlu diproduksi',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Pesanan untuk 3 hari ke depan akan muncul di sini',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Bar
        _SummaryBar(
          totalItems: data.totalItems,
          pendingItems: data.pendingItems,
          completedItems: data.completedItems,
        ),
        // Production List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(productionProvider.notifier).loadProduction(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.productionByDate.length,
              itemBuilder: (context, index) {
                final dateGroup = data.productionByDate[index];
                return _DateGroupCard(dateGroup: dateGroup);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int totalItems;
  final int pendingItems;
  final int completedItems;

  const _SummaryBar({
    required this.totalItems,
    required this.pendingItems,
    required this.completedItems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Produksi',
              value: totalItems.toString(),
              subtitle: 'Semua item',
              icon: Icons.assignment_outlined,
              iconBgColor: AppColors.primary.withValues(alpha: 0.15),
              iconColor: AppColors.primary,
              valueColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Pending',
              value: pendingItems.toString(),
              subtitle: 'Dalam proses',
              icon: Icons.hourglass_empty,
              iconBgColor: Colors.orange.withValues(alpha: 0.15),
              iconColor: Colors.orange,
              valueColor: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Selesai',
              value: completedItems.toString(),
              subtitle: 'Finished',
              icon: Icons.check_circle_outline,
              iconBgColor: Colors.green.withValues(alpha: 0.15),
              iconColor: Colors.green,
              valueColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color valueColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.valueColor,
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateGroupCard extends StatelessWidget {
  final ProductionByDate dateGroup;

  const _DateGroupCard({required this.dateGroup});

  static final _dateFormat = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

  String get _dateLabel {
    if (dateGroup.date == null) return 'Tanggal Belum Ditentukan';

    final now = DateTime.now();
    final date = dateGroup.date!;
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Hari Ini (${_dateFormat.format(date)})';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Besok (${_dateFormat.format(date)})';
    }
    return _dateFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _dateLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${dateGroup.totalItems} items',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        ...dateGroup.items.map((item) => _ProductionItemCard(item: item)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ProductionItemCard extends StatefulWidget {
  final ProductionItem item;

  const _ProductionItemCard({required this.item});

  @override
  State<_ProductionItemCard> createState() => _ProductionItemCardState();
}

class _ProductionItemCardState extends State<_ProductionItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.item.totalQuantity} pcs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) _buildExpandedSection(),
        ],
      ),
    );
  }

  Widget _buildExpandedSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            'Detail Pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.item.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.customerName,
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${order.quantity} pcs',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

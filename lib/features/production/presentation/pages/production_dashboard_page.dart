import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../data/providers/production_providers.dart';

/// Group/Filter options for production
enum ProductionGroupBy { byPickupDate, byCustomer, byProduct, bySize }

extension ProductionGroupByExtension on ProductionGroupBy {
  String get label {
    switch (this) {
      case ProductionGroupBy.byPickupDate:
        return 'Per Tanggal Ambil';
      case ProductionGroupBy.byCustomer:
        return 'Per Nama Pemesan';
      case ProductionGroupBy.byProduct:
        return 'Per Jenis Produk';
      case ProductionGroupBy.bySize:
        return 'Per Ukuran';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductionGroupBy.byPickupDate:
        return Icons.calendar_today;
      case ProductionGroupBy.byCustomer:
        return Icons.person;
      case ProductionGroupBy.byProduct:
        return Icons.cake;
      case ProductionGroupBy.bySize:
        return Icons.straighten;
    }
  }
}

/// Production Dashboard Page - Dashboard Produksi
class ProductionDashboardPage extends ConsumerStatefulWidget {
  const ProductionDashboardPage({super.key});

  @override
  ConsumerState<ProductionDashboardPage> createState() =>
      _ProductionDashboardPageState();
}

class _ProductionDashboardPageState
    extends ConsumerState<ProductionDashboardPage> {
  ProductionGroupBy _groupBy = ProductionGroupBy.byPickupDate;

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
      body: Column(
        children: [
          // Header - Consistent with Dashboard
          _buildHeader(context),

          // Content
          Expanded(
            child: productionState.when(
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
                      onPressed: () => ref
                          .read(productionProvider.notifier)
                          .loadProduction(),
                      child: const Text('Coba Lagi'),
                    ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          Text(
            'Produksi',
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // Group By Dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProductionGroupBy>(
                value: _groupBy,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: isMobile ? 16 : 18,
                  color: Colors.white,
                ),
                dropdownColor: AppColors.primary,
                items: ProductionGroupBy.values.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(group.icon, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          group.label,
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _groupBy = value);
                  }
                },
              ),
            ),
          ),
          SizedBox(width: isMobile ? 4 : 8),

          // Print Button - hide on mobile
          if (!isMobile) ...[
            OutlinedButton.icon(
              onPressed: _printProduction,
              icon: const Icon(Icons.print, size: 18, color: Colors.white),
              label: const Text('Print', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Refresh
          SizedBox(
            width: isMobile ? 32 : 40,
            height: isMobile ? 32 : 40,
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: isMobile ? 18 : 24,
              ),
              padding: EdgeInsets.zero,
              onPressed: () =>
                  ref.read(productionProvider.notifier).loadProduction(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printProduction() async {
    final productionState = ref.read(productionProvider);

    productionState.when(
      initial: () {},
      loading: () {},
      success: (data) async {
        final doc = pw.Document();

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Daftar Produksi',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'LF Kitchen - ${AppFormatters.dateMedium.format(DateTime.now())}',
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Total: ${data.totalItems} item'),
                  pw.Text('Pending: ${data.pendingItems} item'),
                  pw.Text('Selesai: ${data.completedItems} item'),
                  pw.SizedBox(height: 24),
                  ...data.productionByDate.map((dateGroup) {
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          dateGroup.date != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(dateGroup.date!)
                              : 'Belum ditentukan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        ...dateGroup.items.map((item) {
                          return pw.Text(
                            '  • ${item.productName}: ${item.totalQuantity} pcs',
                          );
                        }),
                        pw.SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        );

        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => doc.save(),
        );
      },
      error: (message, code) {},
    );
  }

  Widget _buildContent(BuildContext context, ProductionState data) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.productionByDate.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: isMobile ? 48 : 64,
                color: Colors.green,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Tidak ada item yang perlu diproduksi',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                'Pesanan untuk 3 hari ke depan akan muncul di sini',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isMobile ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Flatten all items
    final allItems = <_FlattenedProductionItem>[];
    for (final dateGroup in data.productionByDate) {
      for (final item in dateGroup.items) {
        for (final order in item.orders) {
          allItems.add(
            _FlattenedProductionItem(
              pickupDate: dateGroup.date,
              orderDate: order.orderDate,
              productName: order.productName,
              productSize: order.productSize,
              productId: order.productId,
              customerName: order.customerName,
              quantity: order.quantity,
              producedQty: order.producedQty,
              orderId: order.orderId,
              orderItemId: order.orderItemId,
            ),
          );
        }
      }
    }

    // Group items based on _groupBy
    final groups = _groupItems(allItems);

    return Column(
      children: [
        // Summary Bar
        _SummaryBar(
          totalItems: data.totalItems,
          pendingItems: data.pendingItems,
          completedItems: data.completedItems,
        ),
        // Grouped Production List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(productionProvider.notifier).loadProduction(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _ProductionGroup(
                  groupBy: _groupBy,
                  groupKey: group.key,
                  items: group.items,
                  onRecorded: () =>
                      ref.read(productionProvider.notifier).loadProduction(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<_GroupedData> _groupItems(List<_FlattenedProductionItem> items) {
    final Map<String, List<_FlattenedProductionItem>> grouped = {};

    for (final item in items) {
      String key;
      switch (_groupBy) {
        case ProductionGroupBy.byPickupDate:
          key = item.pickupDate != null
              ? DateFormat('dd MMM yyyy').format(item.pickupDate!)
              : 'Tanpa Tanggal';
          break;
        case ProductionGroupBy.byCustomer:
          key = item.customerName;
          break;
        case ProductionGroupBy.byProduct:
          key = item.productName;
          break;
        case ProductionGroupBy.bySize:
          key = item.productSize ?? 'Tanpa Ukuran';
          break;
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    // Sort keys
    final sortedKeys = grouped.keys.toList()..sort();

    return sortedKeys
        .map((key) => _GroupedData(key: key, items: grouped[key]!))
        .toList();
  }
}

/// Helper class for grouped data
class _GroupedData {
  final String key;
  final List<_FlattenedProductionItem> items;

  _GroupedData({required this.key, required this.items});

  int get totalQty => items.fold(0, (sum, item) => sum + item.quantity);
  int get completedQty => items.fold(0, (sum, item) => sum + item.producedQty);
}

class _FlattenedProductionItem {
  final DateTime? pickupDate;
  final DateTime? orderDate;
  final String productName;
  final String? productSize;
  final String? productId;
  final String customerName;
  final int quantity;
  final int producedQty;
  final String orderId;
  final String orderItemId;

  _FlattenedProductionItem({
    required this.pickupDate,
    this.orderDate,
    required this.productName,
    this.productSize,
    this.productId,
    required this.customerName,
    required this.quantity,
    this.producedQty = 0,
    required this.orderId,
    required this.orderItemId,
  });

  bool get isComplete => producedQty >= quantity;
  int get remaining => quantity - producedQty;
}

/// Widget for displaying a production group with expandable items
class _ProductionGroup extends StatefulWidget {
  final ProductionGroupBy groupBy;
  final String groupKey;
  final List<_FlattenedProductionItem> items;
  final VoidCallback? onRecorded;

  const _ProductionGroup({
    required this.groupBy,
    required this.groupKey,
    required this.items,
    this.onRecorded,
  });

  @override
  State<_ProductionGroup> createState() => _ProductionGroupState();
}

class _ProductionGroupState extends State<_ProductionGroup> {
  bool _isExpanded = false;

  int get _totalQty => widget.items.fold(0, (sum, item) => sum + item.quantity);
  int get _completedQty =>
      widget.items.fold(0, (sum, item) => sum + item.producedQty);
  bool get _isAllComplete => _completedQty >= _totalQty;

  // Get unique pickup dates from items
  List<String> get _pickupDates {
    final dates = widget.items
        .where((item) => item.pickupDate != null)
        .map((item) => DateFormat('dd/MM').format(item.pickupDate!))
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  // Get display info based on group type
  String get _subInfo {
    switch (widget.groupBy) {
      case ProductionGroupBy.byPickupDate:
        // Show unique customers
        final customers = widget.items.map((e) => e.customerName).toSet();
        return '${customers.length} pemesan';
      case ProductionGroupBy.byCustomer:
        // Show unique products
        final products = widget.items.map((e) => e.productName).toSet();
        return '${products.length} produk • ${_pickupDates.join(', ')}';
      case ProductionGroupBy.byProduct:
        // Show unique customers
        final customers = widget.items.map((e) => e.customerName).toSet();
        return '${customers.length} pemesan • ${_pickupDates.join(', ')}';
      case ProductionGroupBy.bySize:
        // Show unique products
        final products = widget.items.map((e) => e.productName).toSet();
        return '${products.length} produk • ${_pickupDates.join(', ')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isAllComplete ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Group Header - Clickable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon based on group type
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isAllComplete
                          ? Colors.green.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.groupBy.icon,
                      color: _isAllComplete ? Colors.green : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Group Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupKey,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isAllComplete ? Colors.green : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Qty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isAllComplete
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_completedQty / $_totalQty',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isAllComplete ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand Icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Expanded Items
          if (_isExpanded) ...[
            const Divider(height: 1),
            ...widget.items.map(
              (item) => _ProductionSubItem(
                item: item,
                groupBy: widget.groupBy,
                onRecorded: widget.onRecorded,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sub-item row inside a group
class _ProductionSubItem extends ConsumerWidget {
  final _FlattenedProductionItem item;
  final ProductionGroupBy groupBy;
  final VoidCallback? onRecorded;

  const _ProductionSubItem({
    required this.item,
    required this.groupBy,
    this.onRecorded,
  });

  // Display label depends on group type
  String get _label {
    switch (groupBy) {
      case ProductionGroupBy.byPickupDate:
        return '${item.productName} • ${item.customerName}';
      case ProductionGroupBy.byCustomer:
        return item.productName;
      case ProductionGroupBy.byProduct:
        return item.customerName;
      case ProductionGroupBy.bySize:
        return '${item.productName} • ${item.customerName}';
    }
  }

  String get _dateLabel {
    if (item.pickupDate == null) return '-';
    return DateFormat('dd/MM').format(item.pickupDate!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isComplete = item.isComplete;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.withValues(alpha: 0.03) : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Date Badge
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _dateLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Text(
              _label,
              style: TextStyle(
                fontSize: 13,
                color: isComplete ? Colors.green : null,
                decoration: isComplete ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          // Qty
          Text(
            '${item.producedQty}/${item.quantity}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isComplete ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          // Production buttons
          if (!isComplete) ...[
            _QuickAddButton(
              label: '+1',
              onPressed: () => _recordProduction(context, ref, 1),
            ),
            if (item.remaining > 1) ...[
              const SizedBox(width: 4),
              _QuickAddButton(
                label: '+${item.remaining}',
                onPressed: () =>
                    _recordProduction(context, ref, item.remaining),
              ),
            ],
          ] else
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Future<void> _recordProduction(
    BuildContext context,
    WidgetRef ref,
    int qty,
  ) async {
    final repo = ref.read(prodLogRepoProvider);
    final result = await repo.recordProduction(
      orderId: item.orderId,
      orderItemId: item.orderItemId,
      productId: item.productId,
      productName: item.productName,
      productSize: item.productSize,
      customerName: item.customerName,
      deliveryDate: item.pickupDate,
      quantity: qty,
    );

    result.when(
      success: (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tercatat: $qty ${item.productName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        onRecorded?.call();
      },
      failure: (msg, _) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $msg'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickAddButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Pending',
              value: pendingItems.toString(),
              subtitle: 'Dalam proses',
              icon: Icons.hourglass_empty,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Selesai',
              value: completedItems.toString(),
              subtitle: 'Finished',
              icon: Icons.check_circle_outline,
              color: Colors.green,
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
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
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
                      color: color,
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

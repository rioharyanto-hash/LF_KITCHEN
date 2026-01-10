import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/production_providers.dart';

/// Sort options for production
enum ProductionSortBy { pickupDate, customerName, productName, productSize }

extension ProductionSortByExtension on ProductionSortBy {
  String get label {
    switch (this) {
      case ProductionSortBy.pickupDate:
        return 'Tanggal Ambil';
      case ProductionSortBy.customerName:
        return 'Nama Pemesan';
      case ProductionSortBy.productName:
        return 'Nama Kue';
      case ProductionSortBy.productSize:
        return 'Ukuran';
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
  ProductionSortBy _sortBy = ProductionSortBy.pickupDate;
  bool _sortAscending = true;

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
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          const Text(
            'Produksi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProductionSortBy>(
                value: _sortBy,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.white,
                ),
                dropdownColor: AppColors.primary,
                items: ProductionSortBy.values.map((sort) {
                  return DropdownMenuItem(
                    value: sort,
                    child: Text(
                      sort.label,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort Direction
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
              color: Colors.white,
            ),
            tooltip: _sortAscending ? 'Ascending' : 'Descending',
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
            },
          ),

          // Print Button
          OutlinedButton.icon(
            onPressed: _printProduction,
            icon: const Icon(Icons.print, size: 18, color: Colors.white),
            label: const Text('Print', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(productionProvider.notifier).loadProduction(),
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
      error: (_, __) {},
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

    // Flatten all items for sorting
    final allItems = <_FlattenedProductionItem>[];
    for (final dateGroup in data.productionByDate) {
      for (final item in dateGroup.items) {
        for (final order in item.orders) {
          allItems.add(
            _FlattenedProductionItem(
              pickupDate: dateGroup.date,
              productName: item.productName,
              productSize: item.productSize,
              customerName: order.customerName,
              quantity: order.quantity,
              orderId: order.orderId,
            ),
          );
        }
      }
    }

    // Sort items
    allItems.sort((a, b) {
      int result;
      switch (_sortBy) {
        case ProductionSortBy.pickupDate:
          if (a.pickupDate == null && b.pickupDate == null) {
            result = 0;
          } else if (a.pickupDate == null) {
            result = 1;
          } else if (b.pickupDate == null) {
            result = -1;
          } else {
            result = a.pickupDate!.compareTo(b.pickupDate!);
          }
          break;
        case ProductionSortBy.customerName:
          result = a.customerName.compareTo(b.customerName);
          break;
        case ProductionSortBy.productName:
          result = a.productName.compareTo(b.productName);
          break;
        case ProductionSortBy.productSize:
          result = (a.productSize ?? '').compareTo(b.productSize ?? '');
          break;
      }
      return _sortAscending ? result : -result;
    });

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
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                return _ProductionItemRow(item: allItems[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FlattenedProductionItem {
  final DateTime? pickupDate;
  final String productName;
  final String? productSize;
  final String customerName;
  final int quantity;
  final String orderId;

  _FlattenedProductionItem({
    required this.pickupDate,
    required this.productName,
    this.productSize,
    required this.customerName,
    required this.quantity,
    required this.orderId,
  });
}

class _ProductionItemRow extends StatelessWidget {
  final _FlattenedProductionItem item;

  const _ProductionItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Box
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.pickupDate != null
                        ? DateFormat('dd').format(item.pickupDate!)
                        : '-',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    item.pickupDate != null
                        ? DateFormat('MMM').format(item.pickupDate!)
                        : '',
                    style: TextStyle(fontSize: 10, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.customerName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (item.productSize != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.straighten,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.productSize!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Quantity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${item.quantity} pcs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
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

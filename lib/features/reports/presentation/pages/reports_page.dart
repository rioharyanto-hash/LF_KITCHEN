import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/async_state.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../purchasing/data/providers/purchase_providers.dart';

/// Reports Page - Halaman Laporan
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateRange;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(orderListProvider.notifier).loadOrders();
      ref.read(purchaseListProvider.notifier).loadPurchases();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Penjualan'),
            Tab(text: 'Pembelian'),
            Tab(text: 'Keuntungan'),
            Tab(text: 'Pesanan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pilih Periode',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onSelected: (value) => _handleExport(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Cetak / Print'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Display
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Periode: ${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SalesReportTab(
                  dateRange: _dateRange!,
                  currencyFormat: _currencyFormat,
                ),
                _PurchaseReportTab(
                  dateRange: _dateRange!,
                  currencyFormat: _currencyFormat,
                ),
                _ProfitReportTab(
                  dateRange: _dateRange!,
                  currencyFormat: _currencyFormat,
                ),
                _OrderReportTab(
                  dateRange: _dateRange!,
                  currencyFormat: _currencyFormat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  void _handleExport(String type) {
    final tabNames = ['Penjualan', 'Pembelian', 'Keuntungan', 'Pesanan'];
    final currentTab = tabNames[_tabController.index];

    if (type == 'csv') {
      _exportToCsv(currentTab);
    } else if (type == 'print') {
      _printReport(currentTab);
    }
  }

  Future<void> _exportToCsv(String reportType) async {
    try {
      List<List<dynamic>> rows = [];
      final orderState = ref.read(orderListProvider);
      final purchaseState = ref.read(purchaseListProvider);

      // Add header based on report type
      switch (reportType) {
        case 'Penjualan':
          rows.add(['Tanggal', 'Pelanggan', 'Total', 'DP', 'Status']);
          orderState.when(
            initial: () {},
            loading: () {},
            success: (orders) {
              for (final o in orders.where(
                (o) => o.status == OrderStatus.completed,
              )) {
                rows.add([
                  DateFormat('dd/MM/yyyy').format(o.orderDate ?? o.createdAt),
                  o.customerName ?? '-',
                  o.totalAmount,
                  o.dpAmount,
                  o.paymentStatus.name,
                ]);
              }
            },
            error: (_, __) {},
          );
          break;
        case 'Pembelian':
          rows.add(['Tanggal', 'Supplier', 'Total', 'Status']);
          purchaseState.when(
            initial: () {},
            loading: () {},
            success: (purchases) {
              for (final p in purchases) {
                rows.add([
                  DateFormat('dd/MM/yyyy').format(p.purchaseDate),
                  p.supplierName ?? '-',
                  p.totalCost,
                  'Completed',
                ]);
              }
            },
            error: (_, __) {},
          );
          break;
        case 'Keuntungan':
          double totalRevenue = 0;
          double totalCost = 0;
          orderState.when(
            initial: () {},
            loading: () {},
            success: (orders) {
              totalRevenue = orders
                  .where((o) => o.status == OrderStatus.completed)
                  .fold(0.0, (sum, o) => sum + o.totalAmount);
            },
            error: (_, __) {},
          );
          purchaseState.when(
            initial: () {},
            loading: () {},
            success: (purchases) {
              totalCost = purchases.fold(0.0, (sum, p) => sum + p.totalCost);
            },
            error: (_, __) {},
          );
          rows.add(['Kategori', 'Jumlah']);
          rows.add(['Pendapatan', totalRevenue]);
          rows.add(['Pengeluaran', totalCost]);
          rows.add(['Keuntungan', totalRevenue - totalCost]);
          break;
        case 'Pesanan':
          rows.add(['Tanggal Ambil', 'Pelanggan', 'Tipe', 'Total', 'Status']);
          orderState.when(
            initial: () {},
            loading: () {},
            success: (orders) {
              for (final o in orders) {
                rows.add([
                  DateFormat(
                    'dd/MM/yyyy',
                  ).format(o.deliveryDate ?? o.createdAt),
                  o.customerName ?? '-',
                  o.orderType.name,
                  o.totalAmount,
                  o.status.name,
                ]);
              }
            },
            error: (_, __) {},
          );
          break;
      }

      final csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Laporan_${reportType}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File berhasil disimpan: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Buka Folder',
              textColor: Colors.white,
              onPressed: () {
                Process.run('explorer.exe', [directory.path]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printReport(String reportType) {
    // Show print preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cetak Laporan $reportType'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.print, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Laporan $reportType akan dicetak'),
              Text(
                'Periode: ${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fitur cetak menggunakan printer sistem.\nPastikan printer sudah terhubung.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Export to CSV first, then user can print from there
              _exportToCsv(reportType);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'File CSV telah dibuat. Buka file untuk mencetak.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Export & Cetak'),
          ),
        ],
      ),
    );
  }
}

/// Tab Laporan Penjualan
class _SalesReportTab extends ConsumerWidget {
  final DateTimeRange dateRange;
  final NumberFormat currencyFormat;

  const _SalesReportTab({
    required this.dateRange,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderListProvider);

    return orderState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (orders) {
        // Filter orders by date range and completed status
        final filteredOrders = orders.where((o) {
          final orderDate = o.orderDate ?? o.createdAt;
          return orderDate.isAfter(
                dateRange.start.subtract(const Duration(days: 1)),
              ) &&
              orderDate.isBefore(dateRange.end.add(const Duration(days: 1))) &&
              o.status == OrderStatus.completed;
        }).toList();

        if (filteredOrders.isEmpty) {
          return _buildEmptyState('Belum ada penjualan pada periode ini');
        }

        final totalSales = filteredOrders.fold<double>(
          0,
          (sum, o) => sum + o.totalAmount,
        );
        final totalDp = filteredOrders.fold<double>(
          0,
          (sum, o) => sum + o.dpAmount,
        );
        final orderCount = filteredOrders.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Penjualan',
                    value: currencyFormat.format(totalSales),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Jumlah Pesanan',
                    value: '$orderCount pesanan',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total DP Diterima',
                    value: currencyFormat.format(totalDp),
                    icon: Icons.payments,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Detail Penjualan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Sales Table
            Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Pelanggan')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('DP')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filteredOrders
                    .take(20)
                    .map(
                      (o) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              DateFormat(
                                'dd/MM/yy',
                              ).format(o.orderDate ?? o.createdAt),
                            ),
                          ),
                          DataCell(Text(o.customerName ?? '-')),
                          DataCell(Text(currencyFormat.format(o.totalAmount))),
                          DataCell(Text(currencyFormat.format(o.dpAmount))),
                          DataCell(_StatusChip(status: o.paymentStatus.name)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
      error: (msg, _) => Center(child: Text('Error: $msg')),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Tab Laporan Pembelian Bahan Baku
class _PurchaseReportTab extends ConsumerWidget {
  final DateTimeRange dateRange;
  final NumberFormat currencyFormat;

  const _PurchaseReportTab({
    required this.dateRange,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseListProvider);

    return purchaseState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (purchases) {
        final filteredPurchases = purchases.where((p) {
          return p.purchaseDate.isAfter(
                dateRange.start.subtract(const Duration(days: 1)),
              ) &&
              p.purchaseDate.isBefore(
                dateRange.end.add(const Duration(days: 1)),
              );
        }).toList();

        if (filteredPurchases.isEmpty) {
          return _buildEmptyState('Belum ada pembelian pada periode ini');
        }

        final totalPurchases = filteredPurchases.fold<double>(
          0,
          (sum, p) => sum + p.totalCost,
        );
        final purchaseCount = filteredPurchases.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Pembelian',
                    value: currencyFormat.format(totalPurchases),
                    icon: Icons.shopping_cart,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Jumlah Transaksi',
                    value: '$purchaseCount transaksi',
                    icon: Icons.receipt,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Detail Pembelian',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Supplier')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filteredPurchases
                    .take(20)
                    .map(
                      (p) => DataRow(
                        cells: [
                          DataCell(
                            Text(DateFormat('dd/MM/yy').format(p.purchaseDate)),
                          ),
                          DataCell(Text(p.supplierName ?? '-')),
                          DataCell(Text(currencyFormat.format(p.totalCost))),
                          DataCell(_StatusChip(status: 'completed')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
      error: (msg, _) => Center(child: Text('Error: $msg')),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Tab Laporan Keuntungan
class _ProfitReportTab extends ConsumerWidget {
  final DateTimeRange dateRange;
  final NumberFormat currencyFormat;

  const _ProfitReportTab({
    required this.dateRange,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderListProvider);
    final purchaseState = ref.watch(purchaseListProvider);

    return orderState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (orders) {
        final filteredOrders = orders.where((o) {
          final orderDate = o.orderDate ?? o.createdAt;
          return orderDate.isAfter(
                dateRange.start.subtract(const Duration(days: 1)),
              ) &&
              orderDate.isBefore(dateRange.end.add(const Duration(days: 1))) &&
              o.status == OrderStatus.completed;
        }).toList();

        final totalRevenue = filteredOrders.fold<double>(
          0,
          (sum, o) => sum + o.totalAmount,
        );

        double totalCost = 0;
        purchaseState.when(
          initial: () {},
          loading: () {},
          success: (purchases) {
            final filteredPurchases = purchases.where((p) {
              return p.purchaseDate.isAfter(
                    dateRange.start.subtract(const Duration(days: 1)),
                  ) &&
                  p.purchaseDate.isBefore(
                    dateRange.end.add(const Duration(days: 1)),
                  );
            });
            totalCost = filteredPurchases.fold<double>(
              0,
              (sum, p) => sum + p.totalCost,
            );
          },
          error: (_, __) {},
        );

        final profit = totalRevenue - totalCost;
        final profitMargin = totalRevenue > 0
            ? (profit / totalRevenue * 100)
            : 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Pendapatan',
                    value: currencyFormat.format(totalRevenue),
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Pengeluaran',
                    value: currencyFormat.format(totalCost),
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'KEUNTUNGAN BERSIH',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(profit),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: profit >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Margin: ${profitMargin.toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      error: (msg, _) => Center(child: Text('Error: $msg')),
    );
  }
}

/// Tab Laporan Pesanan dengan Filter
class _OrderReportTab extends ConsumerStatefulWidget {
  final DateTimeRange dateRange;
  final NumberFormat currencyFormat;

  const _OrderReportTab({
    required this.dateRange,
    required this.currencyFormat,
  });

  @override
  ConsumerState<_OrderReportTab> createState() => _OrderReportTabState();
}

class _OrderReportTabState extends ConsumerState<_OrderReportTab> {
  String _groupBy = 'tanggal'; // tanggal, pemesan, kue, ukuran

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderListProvider);

    return Column(
      children: [
        // Filter Options
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Kelompokkan: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Tgl Ambil'),
                selected: _groupBy == 'tanggal',
                onSelected: (_) => setState(() => _groupBy = 'tanggal'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pemesan'),
                selected: _groupBy == 'pemesan',
                onSelected: (_) => setState(() => _groupBy = 'pemesan'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Nama Kue'),
                selected: _groupBy == 'kue',
                onSelected: (_) => setState(() => _groupBy = 'kue'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ukuran'),
                selected: _groupBy == 'ukuran',
                onSelected: (_) => setState(() => _groupBy = 'ukuran'),
              ),
            ],
          ),
        ),
        // Report Content
        Expanded(
          child: orderState.when(
            initial: () => const Center(child: Text('Memuat...')),
            loading: () => const Center(child: CircularProgressIndicator()),
            success: (orders) {
              final filteredOrders = orders.where((o) {
                final date = o.deliveryDate ?? o.orderDate ?? o.createdAt;
                return date.isAfter(
                      widget.dateRange.start.subtract(const Duration(days: 1)),
                    ) &&
                    date.isBefore(
                      widget.dateRange.end.add(const Duration(days: 1)),
                    );
              }).toList();

              if (filteredOrders.isEmpty) {
                return const Center(
                  child: Text('Tidak ada pesanan pada periode ini'),
                );
              }

              return _buildGroupedReport(filteredOrders);
            },
            error: (msg, _) => Center(child: Text('Error: $msg')),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedReport(List<Order> orders) {
    Map<String, List<Order>> grouped = {};

    for (final order in orders) {
      String key;
      switch (_groupBy) {
        case 'tanggal':
          key = DateFormat(
            'dd MMM yyyy',
          ).format(order.deliveryDate ?? order.createdAt);
          break;
        case 'pemesan':
          key = order.customerName ?? 'Tanpa Nama';
          break;
        case 'kue':
          // Group by first item's product name
          key = order.items?.isNotEmpty == true
              ? order.items!.first.productName ?? 'Tanpa Kue'
              : 'Tanpa Kue';
          break;
        case 'ukuran':
          // Assuming size is in notes or product name
          key = order.orderType == OrderType.direct ? 'Langsung' : 'PO';
          break;
        default:
          key = 'Lainnya';
      }
      grouped.putIfAbsent(key, () => []).add(order);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final groupOrders = grouped[key]!;
        final total = groupOrders.fold<double>(
          0,
          (sum, o) => sum + o.totalAmount,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${groupOrders.length} pesanan • ${widget.currencyFormat.format(total)}',
            ),
            children: groupOrders
                .map(
                  (o) => ListTile(
                    dense: true,
                    title: Text(o.customerName ?? '-'),
                    subtitle: Text(
                      DateFormat(
                        'dd/MM/yy',
                      ).format(o.deliveryDate ?? o.createdAt),
                    ),
                    trailing: Text(widget.currencyFormat.format(o.totalAmount)),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'partial':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'delivered':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

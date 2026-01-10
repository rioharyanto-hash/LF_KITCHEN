import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../purchasing/data/providers/purchase_providers.dart';

/// Reports Page - Halaman Laporan (tanpa tabs)
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTimeRange? _dateRange;
  String _selectedReport = 'penjualan';

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderListProvider);
    final purchaseState = ref.watch(purchaseListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Type Selector
                    _buildReportSelector(),
                    const SizedBox(height: 24),

                    // Report Content
                    _buildReportContent(orderState, purchaseState),
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
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Laporan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),

          // Date Range
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${AppFormatters.dateMedium.format(_dateRange!.start)} - ${AppFormatters.dateMedium.format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Export Button
          PopupMenuButton<String>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.download, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Export',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (value) => _handleExport(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Cetak / Print'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
    );
  }

  Widget _buildReportSelector() {
    final reports = [
      {'id': 'penjualan', 'label': 'Penjualan', 'icon': Icons.attach_money},
      {'id': 'pembelian', 'label': 'Pembelian', 'icon': Icons.shopping_cart},
      {'id': 'keuntungan', 'label': 'Keuntungan', 'icon': Icons.trending_up},
      {'id': 'pesanan', 'label': 'Pesanan', 'icon': Icons.receipt_long},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: reports.map((report) {
        final isSelected = _selectedReport == report['id'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                report['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(report['label'] as String),
            ],
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          onSelected: (_) {
            setState(() => _selectedReport = report['id'] as String);
          },
        );
      }).toList(),
    );
  }

  Widget _buildReportContent(orderState, purchaseState) {
    switch (_selectedReport) {
      case 'penjualan':
        return _buildSalesReport(orderState);
      case 'pembelian':
        return _buildPurchaseReport(purchaseState);
      case 'keuntungan':
        return _buildProfitReport(orderState, purchaseState);
      case 'pesanan':
        return _buildOrderReport(orderState);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSalesReport(orderState) {
    return orderState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (orders) {
        final filteredOrders = (orders as List<Order>).where((o) {
          final orderDate = o.orderDate;
          return orderDate.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              orderDate.isBefore(
                _dateRange!.end.add(const Duration(days: 1)),
              ) &&
              o.status == OrderStatus.completed;
        }).toList();

        final totalSales = filteredOrders.fold<double>(
          0,
          (sum, o) => sum + o.totalAmount,
        );
        final totalDp = filteredOrders.fold<double>(
          0,
          (sum, o) => sum + o.dpAmount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Penjualan',
                    value: AppFormatters.formatCurrency(totalSales),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Jumlah Pesanan',
                    value: '${filteredOrders.length} pesanan',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total DP',
                    value: AppFormatters.formatCurrency(totalDp),
                    icon: Icons.payments,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data Table
            _buildDataTable(
              columns: ['Tanggal', 'Pelanggan', 'Total', 'DP', 'Status'],
              rows: filteredOrders
                  .take(20)
                  .map(
                    (o) => [
                      AppFormatters.dateShort.format(o.orderDate),
                      o.customerName ?? '-',
                      AppFormatters.formatCurrency(o.totalAmount),
                      AppFormatters.formatCurrency(o.dpAmount),
                      o.paymentStatus.name,
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
      error: (msg, _) => Center(child: Text('Error: $msg')),
    );
  }

  Widget _buildPurchaseReport(purchaseState) {
    return purchaseState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (purchases) {
        final filteredPurchases = purchases.where((p) {
          return p.purchaseDate.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              p.purchaseDate.isBefore(
                _dateRange!.end.add(const Duration(days: 1)),
              );
        }).toList();

        final totalPurchases = filteredPurchases.fold<double>(
          0,
          (sum, p) => sum + p.totalCost,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Pembelian',
                    value: AppFormatters.formatCurrency(totalPurchases),
                    icon: Icons.shopping_cart,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Jumlah Transaksi',
                    value: '${filteredPurchases.length} transaksi',
                    icon: Icons.receipt,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 24),

            _buildDataTable(
              columns: ['Tanggal', 'Supplier', 'Total', 'Status'],
              rows: filteredPurchases
                  .take(20)
                  .map(
                    (p) => [
                      AppFormatters.dateShort.format(p.purchaseDate),
                      p.supplierName ?? '-',
                      AppFormatters.formatCurrency(p.totalCost),
                      'Completed',
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      },
      error: (msg, _) => Center(child: Text('Error: $msg')),
    );
  }

  Widget _buildProfitReport(orderState, purchaseState) {
    double totalRevenue = 0;
    double totalCost = 0;

    orderState.when(
      initial: () {},
      loading: () {},
      success: (orders) {
        totalRevenue = (orders as List<Order>)
            .where(
              (o) =>
                  o.status == OrderStatus.completed &&
                  o.orderDate.isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  o.orderDate.isBefore(
                    _dateRange!.end.add(const Duration(days: 1)),
                  ),
            )
            .fold(0.0, (sum, o) => sum + o.totalAmount);
      },
      error: (_, __) {},
    );

    purchaseState.when(
      initial: () {},
      loading: () {},
      success: (purchases) {
        totalCost = purchases
            .where(
              (p) =>
                  p.purchaseDate.isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  p.purchaseDate.isBefore(
                    _dateRange!.end.add(const Duration(days: 1)),
                  ),
            )
            .fold(0.0, (sum, p) => sum + p.totalCost);
      },
      error: (_, __) {},
    );

    final profit = totalRevenue - totalCost;
    final profitMargin = totalRevenue > 0 ? (profit / totalRevenue * 100) : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pendapatan',
                value: AppFormatters.formatCurrency(totalRevenue),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Pengeluaran',
                value: AppFormatters.formatCurrency(totalCost),
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Profit Card
        Card(
          elevation: 0,
          color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: profit >= 0 ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Text(
                  'KEUNTUNGAN BERSIH',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatCurrency(profit),
                  style: TextStyle(
                    fontSize: 36,
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
  }

  Widget _buildOrderReport(orderState) {
    return orderState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (orders) {
        final filteredOrders = (orders as List<Order>).where((o) {
          final date = o.deliveryDate ?? o.createdAt;
          return date.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }).toList();

        return _buildDataTable(
          columns: ['Tanggal Ambil', 'Pelanggan', 'Tipe', 'Total', 'Status'],
          rows: filteredOrders
              .take(20)
              .map(
                (o) => [
                  o.deliveryDate != null
                      ? AppFormatters.dateShort.format(o.deliveryDate!)
                      : '-',
                  o.customerName ?? '-',
                  o.orderType.name,
                  AppFormatters.formatCurrency(o.totalAmount),
                  o.status.name,
                ],
              )
              .toList(),
        );
      },
      error: (msg, _) => Center(child: Text('Error: $msg')),
    );
  }

  Widget _buildDataTable({
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: Text(
              'Tidak ada data untuk periode ini',
              style: TextStyle(color: Colors.grey),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                ),
              )
              .toList(),
        ),
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

  void _handleExport(String type) {
    if (type == 'csv') {
      _exportToCsv();
    } else if (type == 'print') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur print dalam pengembangan')),
      );
    }
  }

  Future<void> _exportToCsv() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(['Laporan ${_selectedReport.toUpperCase()}']);
      rows.add([
        'Periode: ${AppFormatters.dateMedium.format(_dateRange!.start)} - ${AppFormatters.dateMedium.format(_dateRange!.end)}',
      ]);
      rows.add([]);

      // Add data based on selected report
      final orderState = ref.read(orderListProvider);
      orderState.when(
        initial: () {},
        loading: () {},
        success: (orders) {
          rows.add(['Tanggal', 'Pelanggan', 'Total', 'Status']);
          for (final o in (orders as List<Order>).take(100)) {
            rows.add([
              AppFormatters.dateShort.format(o.orderDate),
              o.customerName ?? '-',
              o.totalAmount,
              o.status.name,
            ]);
          }
        },
        error: (_, __) {},
      );

      final csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Laporan_${_selectedReport}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File berhasil disimpan: $fileName'),
            backgroundColor: Colors.green,
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
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCard({
    required this.title,
    required this.value,
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../purchasing/data/models/purchase.dart';
import '../../../purchasing/data/providers/purchase_providers.dart';

/// Reports Page - Halaman Laporan (tanpa tabs, tanpa menu Pesanan)
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
          // Header - Consistent with Dashboard
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
                    // Report Type Selector (3 types only, no Pesanan)
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          const Text(
            'Laporan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),

          // Date Range Picker
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${AppFormatters.dateMedium.format(_dateRange!.start)} - ${AppFormatters.dateMedium.format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Print Button
          OutlinedButton.icon(
            onPressed: _printReport,
            icon: const Icon(Icons.print, size: 18, color: Colors.white),
            label: const Text('Print', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 8),

          // Export Button
          ElevatedButton.icon(
            onPressed: _exportToCsv,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildReportSelector() {
    // Only 3 report types: Penjualan, Pembelian, Keuntungan
    final reports = [
      {'id': 'penjualan', 'label': 'Penjualan', 'icon': Icons.attach_money},
      {'id': 'pembelian', 'label': 'Pembelian', 'icon': Icons.shopping_cart},
      {'id': 'keuntungan', 'label': 'Keuntungan', 'icon': Icons.trending_up},
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

  Widget _buildReportContent(
    AsyncState<List<Order>> orderState,
    AsyncState<List<Purchase>> purchaseState,
  ) {
    switch (_selectedReport) {
      case 'penjualan':
        return _buildSalesReport(orderState);
      case 'pembelian':
        return _buildPurchaseReport(purchaseState);
      case 'keuntungan':
        return _buildProfitReport(orderState, purchaseState);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSalesReport(AsyncState<List<Order>> orderState) {
    return orderState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (orders) {
        final filteredOrders = orders.where((o) {
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
            _buildDataTable(
              columns: ['Tanggal', 'Pelanggan', 'Total', 'DP', 'Status'],
              rows: filteredOrders
                  .take(50)
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

  Widget _buildPurchaseReport(AsyncState<List<Purchase>> purchaseState) {
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

        // Safe conversion to double
        double totalPurchases = 0;
        for (final p in filteredPurchases) {
          totalPurchases += p.totalCost;
        }

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
              columns: ['Tanggal', 'Supplier', 'Total', 'No. Invoice'],
              rows: filteredPurchases
                  .take(50)
                  .map(
                    (p) => [
                      AppFormatters.dateShort.format(p.purchaseDate),
                      p.supplierName ?? '-',
                      AppFormatters.formatCurrency(p.totalCost),
                      p.invoiceNumber ?? '-',
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

  Widget _buildProfitReport(
    AsyncState<List<Order>> orderState,
    AsyncState<List<Purchase>> purchaseState,
  ) {
    double totalRevenue = 0;
    double totalCost = 0;

    orderState.when(
      initial: () {},
      loading: () {},
      success: (orders) {
        for (final o in orders) {
          if (o.status == OrderStatus.completed &&
              o.orderDate.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              o.orderDate.isBefore(
                _dateRange!.end.add(const Duration(days: 1)),
              )) {
            totalRevenue += o.totalAmount;
          }
        }
      },
      error: (_, __) {},
    );

    purchaseState.when(
      initial: () {},
      loading: () {},
      success: (purchases) {
        for (final p in purchases) {
          if (p.purchaseDate.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              p.purchaseDate.isBefore(
                _dateRange!.end.add(const Duration(days: 1)),
              )) {
            totalCost += p.totalCost;
          }
        }
      },
      error: (_, __) {},
    );

    final profit = totalRevenue - totalCost;
    final profitMargin = totalRevenue > 0 ? (profit / totalRevenue * 100) : 0.0;

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

  Future<void> _printReport() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan ${_selectedReport[0].toUpperCase()}${_selectedReport.substring(1)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Periode: ${AppFormatters.dateMedium.format(_dateRange!.start)} - ${AppFormatters.dateMedium.format(_dateRange!.end)}',
              ),
              pw.SizedBox(height: 16),
              pw.Text('LF Kitchen'),
              pw.SizedBox(height: 24),
              pw.Text('Silakan lihat detail di aplikasi.'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> _exportToCsv() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add([
        'Laporan ${_selectedReport[0].toUpperCase()}${_selectedReport.substring(1)}',
      ]);
      rows.add([
        'Periode: ${AppFormatters.dateMedium.format(_dateRange!.start)} - ${AppFormatters.dateMedium.format(_dateRange!.end)}',
      ]);
      rows.add([]);

      final orderState = ref.read(orderListProvider);
      orderState.when(
        initial: () {},
        loading: () {},
        success: (orders) {
          rows.add(['Tanggal', 'Pelanggan', 'Total', 'Status']);
          for (final o in orders.take(100)) {
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

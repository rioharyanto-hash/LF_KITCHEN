import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/invoice.dart';
import '../../data/providers/invoice_providers.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../orders/domain/entities/order.dart';

/// Model untuk akumulasi tagihan per pelanggan
class _CustomerAccumulation {
  final String customerName;
  final String? customerId;
  final List<Invoice> invoices;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;
  final int invoiceCount;

  _CustomerAccumulation({
    required this.customerName,
    this.customerId,
    required this.invoices,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
    required this.invoiceCount,
  });
}

/// Model untuk akumulasi produk
class _ProductAccumulation {
  final String productName;
  int quantity;
  double subtotal;

  _ProductAccumulation({
    required this.productName,
    required this.quantity,
    required this.subtotal,
  });
}

/// View akumulasi tagihan yang belum dibayar per pelanggan
class InvoiceAccumulationView extends ConsumerStatefulWidget {
  const InvoiceAccumulationView({super.key});

  @override
  ConsumerState<InvoiceAccumulationView> createState() =>
      _InvoiceAccumulationViewState();
}

class _InvoiceAccumulationViewState
    extends ConsumerState<InvoiceAccumulationView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invoiceListProvider.notifier).loadInvoices();
      ref.read(orderListProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceListProvider);
    final orderState = ref.watch(orderListProvider);

    return invoiceState.when(
      initial: () => const Center(child: Text('Memuat data...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (invoices) {
        // Filter hanya yang belum lunas
        final unpaidInvoices = invoices
            .where(
              (i) =>
                  i.status == InvoiceStatus.unpaid ||
                  i.status == InvoiceStatus.partial,
            )
            .toList();

        if (unpaidInvoices.isEmpty) {
          return _buildEmptyState();
        }

        // Group by customer name
        final grouped = <String, List<Invoice>>{};
        for (final invoice in unpaidInvoices) {
          final name = invoice.customerName ?? 'Pelanggan Tanpa Nama';
          grouped.putIfAbsent(name, () => []).add(invoice);
        }

        // Build accumulation list
        final accumulations = grouped.entries.map((entry) {
          final invoiceList = entry.value;
          return _CustomerAccumulation(
            customerName: entry.key,
            customerId: invoiceList.first.customerId,
            invoices: invoiceList,
            totalAmount: invoiceList.fold(0, (sum, i) => sum + i.totalAmount),
            totalPaid: invoiceList.fold(0, (sum, i) => sum + i.paidAmount),
            totalRemaining: invoiceList.fold(
              0,
              (sum, i) => sum + i.remainingAmount,
            ),
            invoiceCount: invoiceList.length,
          );
        }).toList();

        // Sort by remaining amount descending
        accumulations.sort(
          (a, b) => b.totalRemaining.compareTo(a.totalRemaining),
        );

        // Hitung total semua sisa tagihan
        final grandTotalRemaining = accumulations.fold<double>(
          0,
          (sum, a) => sum + a.totalRemaining,
        );

        // Ambil data orders (untuk product details)
        List<Order> allOrders = [];
        orderState.when(
          initial: () {},
          loading: () {},
          success: (orders) => allOrders = orders,
          error: (msg, code) {},
        );

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(invoiceListProvider.notifier).loadInvoices();
            await ref.read(orderListProvider.notifier).loadOrders();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              _buildSummaryCard(
                totalCustomers: accumulations.length,
                totalRemaining: grandTotalRemaining,
                totalInvoices: unpaidInvoices.length,
              ),
              const SizedBox(height: 16),

              // Customer List
              ...accumulations.map(
                (acc) =>
                    _AccumulationCard(accumulation: acc, orders: allOrders),
              ),
            ],
          ),
        );
      },
      error: (msg, code) => Center(child: Text('Error: $msg')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          Text(
            'Semua tagihan sudah lunas!',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada tagihan yang belum dibayar',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int totalCustomers,
    required double totalRemaining,
    required int totalInvoices,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.summarize_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Akumulasi Tagihan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatCurrency(totalRemaining),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryChip(
                  Icons.people_outline,
                  '$totalCustomers pelanggan',
                ),
                const SizedBox(width: 16),
                _buildSummaryChip(
                  Icons.receipt_outlined,
                  '$totalInvoices tagihan',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// Card akumulasi per pelanggan (expandable)
class _AccumulationCard extends StatefulWidget {
  final _CustomerAccumulation accumulation;
  final List<Order> orders;

  const _AccumulationCard({required this.accumulation, required this.orders});

  @override
  State<_AccumulationCard> createState() => _AccumulationCardState();
}

class _AccumulationCardState extends State<_AccumulationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final acc = widget.accumulation;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header - Customer Info
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          acc.customerName.isNotEmpty
                              ? acc.customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name & Invoice Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${acc.invoiceCount} tagihan belum lunas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total Remaining
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(acc.totalRemaining),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.red.shade700,
                            ),
                          ),
                          if (acc.totalPaid > 0)
                            Text(
                              'Dibayar: ${currencyFormat.format(acc.totalPaid)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Expand Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Sembunyikan detail' : 'Lihat detail',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details - Product Breakdown
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildProductBreakdown(currencyFormat),
            const Divider(height: 1),
            _buildInvoiceList(currencyFormat),
          ],
        ],
      ),
    );
  }

  /// Perincian produk yang diakumulasi dari semua tagihan
  Widget _buildProductBreakdown(NumberFormat currencyFormat) {
    // Collect all order IDs from invoices
    final orderIds = widget.accumulation.invoices
        .where((i) => i.orderId != null)
        .map((i) => i.orderId!)
        .toSet();

    // Find matching orders
    final matchedOrders = widget.orders
        .where((o) => orderIds.contains(o.id))
        .toList();

    // Accumulate products
    final productMap = <String, _ProductAccumulation>{};
    for (final order in matchedOrders) {
      if (order.items != null) {
        for (final item in order.items!) {
          final name = item.productName ?? 'Produk Tidak Dikenal';
          if (productMap.containsKey(name)) {
            productMap[name]!.quantity += item.quantity;
            productMap[name]!.subtotal += item.subtotal;
          } else {
            productMap[name] = _ProductAccumulation(
              productName: name,
              quantity: item.quantity,
              subtotal: item.subtotal,
            );
          }
        }
      }
    }

    final products = productMap.values.toList();

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Detail produk tidak tersedia',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by subtotal descending
    products.sort((a, b) => b.subtotal.compareTo(a.subtotal));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Perincian Produk',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Product list
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    'x${product.quantity}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Text(
                      currencyFormat.format(product.subtotal),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Produk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                currencyFormat.format(
                  products.fold<double>(0, (sum, p) => sum + p.subtotal),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Daftar tagihan per customer
  Widget _buildInvoiceList(NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Daftar Tagihan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.accumulation.invoices.map(
            (invoice) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Status badge
                  Container(
                    width: 8,
                    height: 36,
                    decoration: BoxDecoration(
                      color: invoice.status == InvoiceStatus.unpaid
                          ? Colors.red
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.dueDate != null
                              ? 'Jatuh tempo: ${AppFormatters.dateMedium.format(invoice.dueDate!)}'
                              : 'Dibuat: ${AppFormatters.dateMedium.format(invoice.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.status == InvoiceStatus.unpaid
                              ? 'Belum Bayar'
                              : 'Bayar Sebagian',
                          style: TextStyle(
                            fontSize: 11,
                            color: invoice.status == InvoiceStatus.unpaid
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(invoice.remainingAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                      if (invoice.paidAmount > 0)
                        Text(
                          'dari ${currencyFormat.format(invoice.totalAmount)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
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

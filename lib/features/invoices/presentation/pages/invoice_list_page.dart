import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/invoice.dart';
import '../../data/providers/invoice_providers.dart';
import '../../../orders/data/providers/order_providers.dart';

/// Invoice List Page - Daftar Tagihan Pelanggan
class InvoiceListPage extends ConsumerStatefulWidget {
  const InvoiceListPage({super.key});

  @override
  ConsumerState<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends ConsumerState<InvoiceListPage> {
  InvoiceStatus? _selectedStatus;
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invoiceListProvider.notifier).loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(invoiceListProvider.notifier).loadInvoices(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _FilterChips(
            selectedStatus: _selectedStatus,
            onStatusChanged: (status) {
              setState(() => _selectedStatus = status);
              ref
                  .read(invoiceListProvider.notifier)
                  .loadInvoices(status: status);
            },
          ),
          // Invoice List
          Expanded(
            child: invoiceState.when(
              initial: () => const Center(child: Text('Memuat data...')),
              loading: () => const Center(child: CircularProgressIndicator()),
              success: (invoices) {
                if (invoices.isEmpty) {
                  return _EmptyState(selectedStatus: _selectedStatus);
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(invoiceListProvider.notifier).loadInvoices(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) => _ExpandableInvoiceCard(
                      invoice: invoices[index],
                      onPayment: () =>
                          _showPaymentDialog(context, invoices[index]),
                    ),
                  ),
                );
              },
              error: (msg, _) => Center(child: Text('Error: $msg')),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Invoice invoice) {
    final controller = TextEditingController(
      text: invoice.remainingAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bayar Tagihan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${invoice.customerName ?? "-"}'),
            const SizedBox(height: 8),
            Text('Sisa Tagihan: ${invoice.formattedRemaining}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                final success = await ref
                    .read(invoiceListProvider.notifier)
                    .recordPayment(invoice.id, amount);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pembayaran berhasil!')),
                  );
                }
              }
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final InvoiceStatus? selectedStatus;
  final Function(InvoiceStatus?) onStatusChanged;

  const _FilterChips({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip(context, null, 'Semua'),
          const SizedBox(width: 8),
          _buildChip(context, InvoiceStatus.unpaid, 'Belum Lunas'),
          const SizedBox(width: 8),
          _buildChip(context, InvoiceStatus.partial, 'Sebagian'),
          const SizedBox(width: 8),
          _buildChip(context, InvoiceStatus.paid, 'Lunas'),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, InvoiceStatus? status, String label) {
    final isSelected = selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onStatusChanged(status),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final InvoiceStatus? selectedStatus;

  const _EmptyState({this.selectedStatus});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            selectedStatus == null
                ? 'Belum ada tagihan'
                : 'Tidak ada tagihan ${selectedStatus!.name}',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Expandable Invoice Card with order details dropdown
class _ExpandableInvoiceCard extends ConsumerStatefulWidget {
  final Invoice invoice;
  final VoidCallback onPayment;

  const _ExpandableInvoiceCard({
    required this.invoice,
    required this.onPayment,
  });

  @override
  ConsumerState<_ExpandableInvoiceCard> createState() =>
      _ExpandableInvoiceCardState();
}

class _ExpandableInvoiceCardState
    extends ConsumerState<_ExpandableInvoiceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final isOverdue = invoice.isOverdue;
    final isPaid = invoice.status == InvoiceStatus.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverdue ? Colors.red.shade50 : null,
      child: Column(
        children: [
          // Main Content
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Customer Name & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.customerName ?? 'Pelanggan',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _StatusBadge(status: invoice.status),
                                if (isOverdue) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'JATUH TEMPO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            invoice.formattedTotal,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (!isPaid)
                            Text(
                              'Sisa: ${invoice.formattedRemaining}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Due Date & Expand Button
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        invoice.dueDate != null
                            ? 'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(invoice.dueDate!)}'
                            : 'Tanpa batas waktu',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildOrderDetails(),
            const Divider(height: 1),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isPaid)
                    FilledButton.icon(
                      onPressed: widget.onPayment,
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Bayar'),
                    ),
                  if (isPaid)
                    const Chip(
                      label: Text('LUNAS'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (widget.invoice.orderId == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Detail pesanan tidak tersedia'),
      );
    }

    final orderState = ref.watch(orderListProvider);

    return orderState.when(
      initial: () =>
          const Padding(padding: EdgeInsets.all(16), child: Text('Memuat...')),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      success: (orders) {
        final order = orders
            .where((o) => o.id == widget.invoice.orderId)
            .firstOrNull;

        if (order == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Pesanan tidak ditemukan'),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              if (order.items != null && order.items!.isNotEmpty)
                ...order.items!.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName ?? "Produk"} x${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item.subtotal),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pesanan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(order.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DP Dibayar'),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(order.dpAmount),
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      error: (msg, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $msg'),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case InvoiceStatus.paid:
        color = Colors.green;
        label = 'Lunas';
        break;
      case InvoiceStatus.partial:
        color = Colors.orange;
        label = 'Sebagian';
        break;
      case InvoiceStatus.unpaid:
        color = Colors.red;
        label = 'Belum Lunas';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

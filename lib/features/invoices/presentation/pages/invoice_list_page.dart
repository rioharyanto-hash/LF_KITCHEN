import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../data/models/invoice.dart';
import '../../data/providers/invoice_providers.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../widgets/invoice_accumulation_view.dart';

/// Invoice List Page - Daftar Tagihan Pelanggan
class InvoiceListPage extends ConsumerStatefulWidget {
  const InvoiceListPage({super.key});

  @override
  ConsumerState<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends ConsumerState<InvoiceListPage>
    with SingleTickerProviderStateMixin {
  InvoiceStatus? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  String _sortBy = 'created_at';
  bool _ascending = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(invoiceListProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan'),
        actions: [
          // Sort Button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = value;
                  _ascending =
                      (value == 'customer_name'); // Default A-Z for name
                }
              });
              _loadInvoices();
            },
            itemBuilder: (context) => [
              _buildSortItem('created_at', 'Tanggal Dibuat'),
              _buildSortItem('due_date', 'Jatuh Tempo'),
              _buildSortItem('total_amount', 'Total Tagihan'),
              _buildSortItem('customer_name', 'Nama Pelanggan'),
            ],
          ),
          // Date Filter
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: _selectedDateRange != null ? AppColors.primary : null,
            ),
            tooltip: 'Filter Tanggal',
            onPressed: _pickDateRange,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInvoices),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long, size: 20),
              text: 'Daftar Tagihan',
            ),
            Tab(icon: Icon(Icons.group_outlined, size: 20), text: 'Akumulasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Daftar Tagihan (existing)
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Filter Chips
                  _FilterChips(
                    selectedStatus: _selectedStatus,
                    selectedDateRange: _selectedDateRange,
                    onStatusChanged: (status) {
                      setState(() => _selectedStatus = status);
                      _loadInvoices();
                    },
                    onClearDate: () {
                      setState(() => _selectedDateRange = null);
                      _loadInvoices();
                    },
                  ),
                  // Invoice List
                  Expanded(
                    child: invoiceState.when(
                      initial: () =>
                          const Center(child: Text('Memuat data...')),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      success: (invoices) {
                        if (invoices.isEmpty) {
                          return _EmptyState(selectedStatus: _selectedStatus);
                        }
                        return RefreshIndicator(
                          onRefresh: () => ref
                              .read(invoiceListProvider.notifier)
                              .loadInvoices(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: invoices.length,
                            itemBuilder: (context, index) =>
                                _ExpandableInvoiceCard(
                                  invoice: invoices[index],
                                  onPayment: () => _showPaymentDialog(
                                    context,
                                    invoices[index],
                                  ),
                                ),
                          ),
                        );
                      },
                      error: (msg, code) => Center(child: Text('Error: $msg')),
                    ),
                  ),
                ],
              );
            },
          ),

          // Tab 2: Akumulasi Pelanggan (new)
          const InvoiceAccumulationView(),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Invoice invoice) {
    final controller = TextEditingController(
      text: invoice.remainingAmount.toStringAsFixed(0),
    );
    String selectedMethod = 'Cash';
    final methods = ['Cash', 'Transfer', 'QRIS'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              const SizedBox(height: 16),
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: methods.map((method) {
                  final isSelected = selectedMethod == method;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          method == 'Cash'
                              ? Icons.money
                              : method == 'Transfer'
                              ? Icons.account_balance
                              : Icons.qr_code,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(method),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setDialogState(() => selectedMethod = method);
                    },
                  );
                }).toList(),
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
                    CustomToast.showSuccess(
                      context: context,
                      title: 'Pembayaran Berhasil',
                      subtitle:
                          'Dibayar via $selectedMethod • Rp ${controller.text}',
                    );
                  }
                }
              },
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppColors.primary,
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
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadInvoices();
    }
  }

  void _loadInvoices() {
    ref
        .read(invoiceListProvider.notifier)
        .loadInvoices(
          status: _selectedStatus,
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
          sortBy: _sortBy,
          ascending: _ascending,
        );
  }
}

class _FilterChips extends StatelessWidget {
  final InvoiceStatus? selectedStatus;
  final DateTimeRange? selectedDateRange;
  final Function(InvoiceStatus?) onStatusChanged;
  final VoidCallback onClearDate;

  const _FilterChips({
    required this.selectedStatus,
    required this.selectedDateRange,
    required this.onStatusChanged,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (selectedDateRange != null) ...[
              InputChip(
                label: Text(
                  '${DateFormat('dd MMM').format(selectedDateRange!.start)} - ${DateFormat('dd MMM').format(selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 12),
                ),
                selected: true,
                onDeleted: onClearDate,
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppColors.primary),
                deleteIconColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
            ],
            _buildChip(context, null, 'Semua'),
            const SizedBox(width: 8),
            _buildChip(context, InvoiceStatus.unpaid, 'Belum Lunas'),
            const SizedBox(width: 8),
            _buildChip(context, InvoiceStatus.partial, 'Sebagian'),
            const SizedBox(width: 8),
            _buildChip(context, InvoiceStatus.paid, 'Lunas'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, InvoiceStatus? status, String label) {
    final isSelected = selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onStatusChanged(status),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
                          if (invoice.shippingCost > 0)
                            Text(
                              'Ongkir: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(invoice.shippingCost)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
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
      error: (msg, code) => Padding(
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
        color: color.withValues(alpha: 0.15),
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

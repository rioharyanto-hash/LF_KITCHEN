import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/utils/result.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_providers.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../invoices/data/providers/invoice_providers.dart';
import '../dialogs/receipt_print_dialog.dart';

/// Order List Page - Daftar Pesanan PO
class OrderListPage extends ConsumerStatefulWidget {
  final String? highlightOrderId;
  final String? initialStatus;

  const OrderListPage({super.key, this.highlightOrderId, this.initialStatus});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

/// Sort options for order list
enum OrderSortOption {
  orderDateDesc,
  orderDateAsc,
  deliveryDateAsc,
  deliveryDateDesc,
  customerName,
}

class _OrderListPageState extends ConsumerState<OrderListPage> {
  OrderStatus? _selectedStatus;
  OrderSortOption _sortOption = OrderSortOption.deliveryDateAsc;

  @override
  void initState() {
    super.initState();
    // Parse initial status from parameter
    if (widget.initialStatus != null) {
      try {
        _selectedStatus = OrderStatus.values.firstWhere(
          (s) => s.name == widget.initialStatus,
        );
      } catch (_) {
        _selectedStatus = null;
      }
    }
    Future.microtask(() {
      ref
          .read(orderListProvider.notifier)
          .loadOrders(type: OrderType.po, status: _selectedStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan (PO)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(orderListProvider.notifier).loadPOOrders(),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              scrollInfo.metrics.axis == Axis.vertical) {
            ref.read(orderListProvider.notifier).loadMore();
          }
          return false;
        },
        child: Column(
          children: [
            // Filter Chips with Add Button
            _FilterChips(
              selectedStatus: _selectedStatus,
              onStatusChanged: (status) {
                setState(() => _selectedStatus = status);
                ref
                    .read(orderListProvider.notifier)
                    .loadOrders(type: OrderType.po, status: status);
              },
              onAdd: () => _showAddOrderDialog(context),
            ),
            // Sort Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Urutkan: ', style: TextStyle(color: Colors.grey)),
                  DropdownButton<OrderSortOption>(
                    value: _sortOption,
                    underline: const SizedBox(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: OrderSortOption.deliveryDateAsc,
                        child: Text('Tgl Ambil (Terdekat)'),
                      ),
                      DropdownMenuItem(
                        value: OrderSortOption.deliveryDateDesc,
                        child: Text('Tgl Ambil (Terjauh)'),
                      ),
                      DropdownMenuItem(
                        value: OrderSortOption.orderDateDesc,
                        child: Text('Tgl Pesan (Terbaru)'),
                      ),
                      DropdownMenuItem(
                        value: OrderSortOption.orderDateAsc,
                        child: Text('Tgl Pesan (Terlama)'),
                      ),
                      DropdownMenuItem(
                        value: OrderSortOption.customerName,
                        child: Text('Nama Pelanggan'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortOption = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Order List
            Expanded(
              child: orderState.whenWithData(
                initial: () => const Center(child: Text('Memuat data...')),
                loading: (data) {
                  if (data != null && data.isNotEmpty) {
                    // Show previous data while loading
                    return _buildOrderList(data);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                success: (orders) {
                  if (orders.isEmpty) {
                    return _EmptyState(selectedStatus: _selectedStatus);
                  }
                  return _buildOrderList(orders);
                },
                error: (message, code) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $message'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(orderListProvider.notifier).loadPOOrders(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading More Indicator
            if (orderState.isLoading &&
                orderState.hasData &&
                orderState.data!.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    // Sort orders based on selected option
    final sortedOrders = List<Order>.from(orders);
    switch (_sortOption) {
      case OrderSortOption.deliveryDateAsc:
        sortedOrders.sort((a, b) {
          if (a.deliveryDate == null && b.deliveryDate == null) {
            return 0;
          }
          if (a.deliveryDate == null) {
            return 1;
          }
          if (b.deliveryDate == null) {
            return -1;
          }
          return a.deliveryDate!.compareTo(b.deliveryDate!);
        });
        break;
      case OrderSortOption.deliveryDateDesc:
        sortedOrders.sort((a, b) {
          if (a.deliveryDate == null && b.deliveryDate == null) {
            return 0;
          }
          if (a.deliveryDate == null) {
            return 1;
          }
          if (b.deliveryDate == null) {
            return -1;
          }
          return b.deliveryDate!.compareTo(a.deliveryDate!);
        });
        break;
      case OrderSortOption.orderDateDesc:
        sortedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        break;
      case OrderSortOption.orderDateAsc:
        sortedOrders.sort((a, b) => a.orderDate.compareTo(b.orderDate));
        break;
      case OrderSortOption.customerName:
        sortedOrders.sort(
          (a, b) => (a.customerName ?? '').compareTo(b.customerName ?? ''),
        );
        break;
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(orderListProvider.notifier).loadPOOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedOrders.length,
        itemBuilder: (context, index) {
          final order = sortedOrders[index];
          final isHighlighted = widget.highlightOrderId == order.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.1)
                : null,
            shape: isHighlighted
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primary, width: 2),
                  )
                : null,
            child: _OrderRow(
              order: order,
              onEdit: () => _showEditOrderDialog(context, order),
              onStatusChange: (status) => _updateStatus(order, status),
              onPayment: () => _showPaymentDialog(context, order),
            ),
          );
        },
      ),
    );
  }

  void _showAddOrderDialog(BuildContext context) {
    // Navigate to order form (default view of /orders)
    context.go('/orders');
  }

  void _showEditOrderDialog(BuildContext context, Order order) {
    // Navigate to order form with order data
    context.go('/orders', extra: order);
  }

  Future<void> _updateStatus(Order order, OrderStatus status) async {
    // Validasi: Jika selesai dan belum lunas, tawarkan buat tagihan
    if (status == OrderStatus.completed &&
        order.paymentStatus != PaymentStatus.paid) {
      if (mounted) {
        final remainingAmount = order.grandTotal - order.dpAmount;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.warning_amber, color: AppColors.warning, size: 48),
            title: const Text('Pesanan Belum Lunas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.paymentStatus == PaymentStatus.unpaid
                      ? 'Pesanan ini belum dibayar sama sekali.'
                      : 'Pesanan ini belum lunas (masih DP).',
                ),
                const SizedBox(height: 8),
                Text(
                  'Sisa yang harus dibayar: Rp ${remainingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Pilih tindakan:'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _createInvoiceAndComplete(order, remainingAmount);
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Buat Tagihan'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPaymentDialog(context, order, completeAfterPaid: true);
                },
                icon: const Icon(Icons.payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                label: const Text('Bayar Sekarang'),
              ),
            ],
          ),
        );
      }
      return;
    }
    await ref.read(orderListProvider.notifier).updateStatus(order.id, status);
  }

  Future<void> _createInvoiceAndComplete(
    Order order,
    double remainingAmount,
  ) async {
    // Import invoice repository
    final invoiceRepo = ref.read(invoiceRepositoryProvider);

    // Create invoice
    final invoice = Invoice(
      id: '',
      orderId: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      totalAmount: remainingAmount,
      paidAmount: 0,
      remainingAmount: remainingAmount,
      dueDate:
          order.deliveryDate ?? DateTime.now().add(const Duration(days: 7)),
      status: InvoiceStatus.unpaid,
      notes: 'Sisa pembayaran pesanan PO',
      createdAt: DateTime.now(),
    );

    final result = await invoiceRepo.create(invoice);

    if (result.isSuccess) {
      // Update order to completed
      await ref
          .read(orderListProvider.notifier)
          .updateStatus(order.id, OrderStatus.completed);

      if (mounted) {
        CustomToast.showSuccess(
          context: context,
          title: 'Pesanan Selesai',
          subtitle:
              'Tagihan Rp ${remainingAmount.toStringAsFixed(0)} telah dibuat.',
        );
      }
    } else {
      if (mounted) {
        CustomToast.showError(
          context: context,
          title: 'Gagal Membuat Tagihan',
          subtitle: result.errorMessage ?? 'Terjadi kesalahan',
        );
      }
    }
  }

  void _showPaymentDialog(
    BuildContext context,
    Order order, {
    bool completeAfterPaid = false,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PaymentDialog(
        order: order,
        completeAfterPaid: completeAfterPaid,
        onPay: (amount, method, shipping) async {
          final newDp = order.dpAmount + amount;
          final isPaid = newDp >= order.grandTotal;
          final newStatus = isPaid ? PaymentStatus.paid : PaymentStatus.partial;

          await ref
              .read(orderListProvider.notifier)
              .updatePaymentStatus(
                order.id,
                newStatus,
                dpAmount: newDp,
                paymentMethod: method,
              );

          // Complete order if flag is set (user clicked "Bayar & Selesaikan")
          if (completeAfterPaid) {
            await ref
                .read(orderListProvider.notifier)
                .updateStatus(order.id, OrderStatus.completed);
          }

          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Order order;
  final bool completeAfterPaid;
  final Future<void> Function(double amount, String method, double shipping)
  onPay;

  const _PaymentDialog({
    required this.order,
    required this.completeAfterPaid,
    required this.onPay,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late TextEditingController _amountController;
  String _selectedMethod = 'Tunai';
  bool _isLoading = false;
  bool _isFreeShipping = false;

  static const _paymentMethods = ['Tunai', 'Transfer', 'QRIS'];

  // Parse existing shipping from notes
  double get _existingShipping {
    if (widget.order.notes == null) return 0;
    final match = RegExp(r'SHIPPING:(\d+)').firstMatch(widget.order.notes!);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  bool get _hasShipping => _existingShipping > 0;

  @override
  void initState() {
    super.initState();
    final remaining = widget.order.grandTotal - widget.order.dpAmount;
    _amountController = TextEditingController(
      text: remaining.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.order.grandTotal - widget.order.dpAmount;

    return AlertDialog(
      title: const Text('Pembayaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Text(
              'Total Pesanan: Rp ${widget.order.totalAmount.toStringAsFixed(0)}',
            ),
            if (widget.order.dpAmount > 0)
              Text('DP: Rp ${widget.order.dpAmount.toStringAsFixed(0)}'),
            if (_hasShipping)
              Text(
                '(Termasuk ongkir: Rp ${_existingShipping.toStringAsFixed(0)})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 12),

            // Warning if no shipping
            if (!_hasShipping && !_isFreeShipping)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ongkos kirim belum diisi.\nIsi melalui Cetak Kwitansi.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _isFreeShipping = true),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_box_outline_blank,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Free Ongkir (gratis)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Free ongkir indicator
            if (_isFreeShipping || (_hasShipping && _existingShipping == 0))
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Free Ongkir',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_isFreeShipping)
                      InkWell(
                        onTap: () => setState(() => _isFreeShipping = false),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),

            // Remaining Amount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sisa Bayar:'),
                  Text(
                    'Rp ${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: remaining > 0 ? AppColors.error : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selection
            const Text('Metode Pembayaran:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _paymentMethods.map((method) {
                final isSelected = _selectedMethod == method;
                return ChoiceChip(
                  label: Text(method),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMethod = method);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  avatar: Icon(
                    _getMethodIcon(method),
                    size: 16,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar',
                prefixText: 'Rp ',
              ),
            ),
            if (widget.completeAfterPaid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '* Pesanan akan otomatis selesai setelah lunas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handlePayment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.completeAfterPaid ? 'Bayar & Selesaikan' : 'Bayar'),
        ),
      ],
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'Transfer':
        return Icons.account_balance;
      case 'QRIS':
        return Icons.qr_code;
      default:
        return Icons.payments;
    }
  }

  Future<void> _handlePayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    // Pass 0 for shipping as it's already included in totalAmount
    await widget.onPay(amount, _selectedMethod, 0);
    setState(() => _isLoading = false);
  }
}

class _FilterChips extends StatelessWidget {
  final OrderStatus? selectedStatus;
  final ValueChanged<OrderStatus?> onStatusChanged;
  final VoidCallback onAdd;

  const _FilterChips({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Chips (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: selectedStatus == null,
                    onSelected: (selected) => onStatusChanged(null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Draft'),
                    selected: selectedStatus == OrderStatus.draft,
                    onSelected: (selected) =>
                        onStatusChanged(selected ? OrderStatus.draft : null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Dikonfirmasi'),
                    selected: selectedStatus == OrderStatus.confirmed,
                    onSelected: (selected) => onStatusChanged(
                      selected ? OrderStatus.confirmed : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Proses'),
                    selected: selectedStatus == OrderStatus.processing,
                    onSelected: (selected) => onStatusChanged(
                      selected ? OrderStatus.processing : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Siap Ambil'),
                    selected: selectedStatus == OrderStatus.ready,
                    onSelected: (selected) =>
                        onStatusChanged(selected ? OrderStatus.ready : null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Selesai'),
                    selected: selectedStatus == OrderStatus.completed,
                    onSelected: (selected) => onStatusChanged(
                      selected ? OrderStatus.completed : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Add Button (fixed right)
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Pesanan Baru'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final OrderStatus? selectedStatus;

  const _EmptyState({this.selectedStatus});

  String get _emptyMessage {
    switch (selectedStatus) {
      case OrderStatus.processing:
        return 'Tidak ada pesanan dalam proses';
      case OrderStatus.ready:
        return 'Tidak ada pesanan siap diambil';
      case OrderStatus.completed:
        return 'Tidak ada pesanan selesai';
      case OrderStatus.cancelled:
        return 'Tidak ada pesanan dibatalkan';
      default:
        return 'Belum ada pesanan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _emptyMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  final Order order;
  final VoidCallback onEdit;
  final void Function(OrderStatus) onStatusChange;
  final VoidCallback onPayment;

  const _OrderRow({
    required this.order,
    required this.onEdit,
    required this.onStatusChange,
    required this.onPayment,
  });

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _isExpanded = false;

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact Row - Always visible
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Name + Total Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Name & Status badges
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            widget.order.customerName ?? 'Guest',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          _StatusBadge(status: widget.order.status),
                          // Snack Box indicator
                          if (widget.order.items?.any(
                                (item) =>
                                    item.productName?.toUpperCase() ==
                                    'SNACK BOX',
                              ) ??
                              false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: 10,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Snack Box',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Right: Total Price + Shipping
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(widget.order.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        if (widget.order.shippingCost > 0)
                          Text(
                            'Ongkir: ${_currencyFormat.format(widget.order.shippingCost)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Second Row: Phone info
                Row(
                  children: [
                    Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      widget.order.customerPhone ?? '-',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    // Payment badge on right
                    _PaymentBadge(
                      status: widget.order.paymentStatus,
                      dpAmount: widget.order.dpAmount,
                      totalAmount: widget.order.totalAmount,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Third Row: Dates (stacked for mobile)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_calendar,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pesan: ${_dateFormat.format(widget.order.orderDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Ambil: ${widget.order.deliveryDate != null ? _dateFormat.format(widget.order.deliveryDate!) : '-'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Expanded Detail Section
        if (_isExpanded) _buildExpandedSection(),
      ],
    );
  }

  Widget _buildExpandedSection() {
    final items = widget.order.items ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'Tidak ada item',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.productName ?? 'Produk',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _currencyFormat.format(item.unitPrice),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _currencyFormat.format(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.order.notes!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Action Buttons Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Print button - always available
              OutlinedButton.icon(
                onPressed: () => ReceiptPrintDialog.show(context, widget.order),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Cetak Kwitansi'),
              ),
              // Status-based buttons
              if (widget.order.status != OrderStatus.completed &&
                  widget.order.status != OrderStatus.cancelled)
                ..._buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];

    // Payment button removed - payments only via Invoice menu

    switch (widget.order.status) {
      case OrderStatus.draft:
        buttons.add(
          OutlinedButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
          ),
        );
        buttons.add(
          FilledButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.confirmed),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Konfirmasi'),
          ),
        );
        buttons.add(
          TextButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.cancelled),
            icon: Icon(Icons.close, size: 16, color: AppColors.error),
            label: Text('Batal', style: TextStyle(color: AppColors.error)),
          ),
        );
        break;
      case OrderStatus.confirmed:
        // Uang Muka (DP) button
        if (widget.order.paymentStatus != PaymentStatus.paid) {
          buttons.add(
            OutlinedButton.icon(
              onPressed: widget.onPayment,
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Uang Muka'),
            ),
          );
        }
        buttons.add(
          FilledButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.processing),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Proses'),
          ),
        );
        buttons.add(
          TextButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.cancelled),
            icon: Icon(Icons.close, size: 16, color: AppColors.error),
            label: Text('Batal', style: TextStyle(color: AppColors.error)),
          ),
        );
        break;
      case OrderStatus.processing:
        // Uang Muka (DP) button
        if (widget.order.paymentStatus != PaymentStatus.paid) {
          buttons.add(
            OutlinedButton.icon(
              onPressed: widget.onPayment,
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Uang Muka'),
            ),
          );
        }
        buttons.add(
          FilledButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.ready),
            icon: const Icon(Icons.done, size: 16),
            label: const Text('Siap Ambil'),
          ),
        );
        buttons.add(
          TextButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.cancelled),
            icon: Icon(Icons.close, size: 16, color: AppColors.error),
            label: Text('Batal', style: TextStyle(color: AppColors.error)),
          ),
        );
        break;
      case OrderStatus.ready:
        // Uang Muka (DP) button
        if (widget.order.paymentStatus != PaymentStatus.paid) {
          buttons.add(
            OutlinedButton.icon(
              onPressed: widget.onPayment,
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Uang Muka'),
            ),
          );
        }
        buttons.add(
          FilledButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.completed),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Selesai'),
          ),
        );
        buttons.add(
          TextButton.icon(
            onPressed: () => widget.onStatusChange(OrderStatus.cancelled),
            icon: Icon(Icons.close, size: 16, color: AppColors.error),
            label: Text('Batal', style: TextStyle(color: AppColors.error)),
          ),
        );
        break;
      default:
        break;
    }
    return buttons;
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final void Function(OrderStatus) onStatusChange;

  const _OrderCard({required this.order, required this.onStatusChange});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.order.customerName ?? 'Guest',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: widget.order.status),
                      // Snack Box indicator - detect from item names
                      if (widget.order.items?.any(
                            (item) =>
                                item.productName?.toUpperCase() == 'SNACK BOX',
                          ) ??
                          false) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 10,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Snack Box',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.order.customerPhone ?? '-',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.edit_calendar,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pesan: ${_dateFormat.format(widget.order.orderDate)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.event,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ambil: ${widget.order.deliveryDate != null ? _dateFormat.format(widget.order.deliveryDate!) : '-'}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currencyFormat.format(widget.order.totalAmount),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                          _PaymentBadge(
                            status: widget.order.paymentStatus,
                            dpAmount: widget.order.dpAmount,
                            totalAmount: widget.order.totalAmount,
                          ),
                        ],
                      ),
                      if (widget.order.status != OrderStatus.completed &&
                          widget.order.status != OrderStatus.cancelled)
                        PopupMenuButton<OrderStatus>(
                          tooltip: 'Update Status',
                          icon: const Icon(Icons.more_vert),
                          onSelected: widget.onStatusChange,
                          itemBuilder: (context) =>
                              _getNextStatusOptions(widget.order.status),
                        ),
                    ],
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
    final items = widget.order.items ?? [];
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
          if (items.isEmpty)
            Text(
              'Tidak ada item',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.productName ?? 'Produk',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _currencyFormat.format(item.unitPrice),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _currencyFormat.format(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.order.notes!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
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

  List<PopupMenuEntry<OrderStatus>> _getNextStatusOptions(OrderStatus current) {
    final options = <PopupMenuEntry<OrderStatus>>[];
    switch (current) {
      case OrderStatus.draft:
        options.add(
          const PopupMenuItem(
            value: OrderStatus.confirmed,
            child: Text('✓ Konfirmasi'),
          ),
        );
        options.add(
          const PopupMenuItem(
            value: OrderStatus.cancelled,
            child: Text('✗ Batalkan'),
          ),
        );
        break;
      case OrderStatus.confirmed:
        options.add(
          const PopupMenuItem(
            value: OrderStatus.processing,
            child: Text('→ Proses'),
          ),
        );
        break;
      case OrderStatus.processing:
        options.add(
          const PopupMenuItem(
            value: OrderStatus.ready,
            child: Text('✓ Siap Ambil'),
          ),
        );
        break;
      case OrderStatus.ready:
        options.add(
          const PopupMenuItem(
            value: OrderStatus.completed,
            child: Text('✓ Selesai'),
          ),
        );
        break;
      default:
        break;
    }
    return options;
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.draft:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Draft';
        break;
      case OrderStatus.confirmed:
        bgColor = AppColors.info.withValues(alpha: 0.15);
        textColor = AppColors.info;
        label = 'Dikonfirmasi';
        break;
      case OrderStatus.processing:
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'Proses';
        break;
      case OrderStatus.ready:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = 'Siap Ambil';
        break;
      case OrderStatus.completed:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = 'Selesai';
        break;
      case OrderStatus.cancelled:
        bgColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        label = 'Dibatalkan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final PaymentStatus status;
  final double dpAmount;
  final double totalAmount;

  const _PaymentBadge({
    required this.status,
    required this.dpAmount,
    required this.totalAmount,
  });

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case PaymentStatus.unpaid:
        label = 'Belum Bayar';
        color = AppColors.error;
        break;
      case PaymentStatus.partial:
        label = 'DP ${_currencyFormat.format(dpAmount)}';
        color = AppColors.warning;
        break;
      case PaymentStatus.paid:
        label = 'Lunas';
        color = AppColors.success;
        break;
    }

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}

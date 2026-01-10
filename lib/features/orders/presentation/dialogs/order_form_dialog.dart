import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../../../customers/data/models/customer.dart';
import '../../../customers/data/providers/customer_providers.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_providers.dart';

/// Order Form Dialog - Buat/Edit Pesanan
class OrderFormDialog extends ConsumerStatefulWidget {
  final Order? order;

  const OrderFormDialog({super.key, this.order});

  @override
  ConsumerState<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends ConsumerState<OrderFormDialog> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;
  final _dpController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  bool get isEditMode => widget.order != null;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(orderFormProvider.notifier).reset();

      await ref.read(customerListProvider.notifier).loadCustomers();
      ref.read(productListProvider.notifier).loadProducts();

      if (widget.order != null) {
        final order = widget.order!;
        _orderDate = order.orderDate;
        _deliveryDate = order.deliveryDate;
        _dpController.text = order.dpAmount.toStringAsFixed(0);
        _notesController.text = order.notes ?? '';

        if (order.customerId != null) {
          final customersState = ref.read(customerListProvider);
          customersState.when(
            initial: () {},
            loading: () {},
            success: (customers) {
              final customer = customers.firstWhere(
                (c) => c.id == order.customerId,
                orElse: () => customers.first,
              );
              if (mounted) setState(() => _selectedCustomer = customer);
            },
            error: (message, code) {},
          );
        }

        if (order.items != null) {
          for (final item in order.items!) {
            ref.read(orderFormProvider.notifier).addItem(item);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _dpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(orderFormProvider);
    final customersState = ref.watch(customerListProvider);
    final productsState = ref.watch(productListProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(isEditMode ? 'Edit Pesanan' : 'Pesanan Baru'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
                Text(
                  'Pelanggan',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                customersState.when(
                  initial: () => const LinearProgressIndicator(),
                  loading: () => const LinearProgressIndicator(),
                  success: (customers) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Autocomplete<Customer>(
                              displayStringForOption: (c) =>
                                  '${c.name} (${c.phone})',
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return customers;
                                }
                                final query = textEditingValue.text
                                    .toLowerCase();
                                return customers.where(
                                  (c) =>
                                      c.name.toLowerCase().contains(query) ||
                                      c.phone.contains(query),
                                );
                              },
                              onSelected: (customer) {
                                setState(() => _selectedCustomer = customer);
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    // Set initial value if editing
                                    if (_selectedCustomer != null &&
                                        controller.text.isEmpty) {
                                      controller.text =
                                          '${_selectedCustomer!.name} (${_selectedCustomer!.phone})';
                                    }
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Ketik untuk cari atau tap untuk lihat semua',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                          ),
                                          onPressed: () {
                                            // Show all options by clearing and refocusing
                                            controller.clear();
                                            focusNode.requestFocus();
                                          },
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (_) =>
                                          _selectedCustomer == null
                                          ? 'Pilih pelanggan'
                                          : null,
                                    );
                                  },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                            maxWidth: 400,
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final c = options.elementAt(
                                                index,
                                              );
                                              return ListTile(
                                                dense: true,
                                                title: Text(c.name),
                                                subtitle: Text(c.phone),
                                                onTap: () => onSelected(c),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.person_add),
                            tooltip: 'Tambah Pelanggan Baru',
                            onPressed: () => _showAddCustomerDialog(context),
                          ),
                        ],
                      ),
                      if (_selectedCustomer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Terpilih: ${_selectedCustomer!.name}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  error: (message, code) => Text('Error: $message'),
                ),
                const SizedBox(height: 16),

                // Order Date & Delivery Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Pesanan',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectOrderDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today),
                                isDense: true,
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_orderDate),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Pengambilan',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDeliveryDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.event),
                                isDense: true,
                              ),
                              child: Text(
                                _deliveryDate != null
                                    ? DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_deliveryDate!)
                                    : 'Pilih Tanggal',
                                style: TextStyle(
                                  color: _deliveryDate != null
                                      ? null
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Products Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Item Pesanan',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: AppColors.primary,
                      onPressed: () => _showAddProductDialog(productsState),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  // Filter out snack box sub-items (they start with "  -")
                  child:
                      formState.items
                          .where((i) => !i.productName!.startsWith('  -'))
                          .isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada item.\nTekan + untuk menambah.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: formState.items
                              .where((i) => !i.productName!.startsWith('  -'))
                              .length,
                          itemBuilder: (context, index) {
                            // Get only main items (exclude sub-items)
                            final mainItems = formState.items
                                .where((i) => !i.productName!.startsWith('  -'))
                                .toList();
                            final item = mainItems[index];
                            return Card(
                              child: ListTile(
                                dense: true,
                                title: Text(item.productName ?? 'Produk'),
                                subtitle: Text(
                                  '${item.quantity} x ${_currencyFormat.format(item.unitPrice)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currencyFormat.format(item.subtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        // Find actual index in formState.items
                                        final realIndex = formState.items
                                            .indexOf(item);
                                        ref
                                            .read(orderFormProvider.notifier)
                                            .removeItem(realIndex);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),

                // Total & DP
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ${_currencyFormat.format(formState.totalAmount)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _dpController,
                        decoration: const InputDecoration(
                          labelText: 'DP (Rp)',
                          prefixText: 'Rp ',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Catatan tambahan...',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: formState.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: formState.isLoading || formState.items.isEmpty
              ? null
              : _submitOrder,
          child: formState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditMode ? 'Update Pesanan' : 'Simpan Pesanan'),
        ),
      ],
    );
  }

  Future<void> _selectOrderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _orderDate = date);
    }
  }

  Future<void> _selectDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _deliveryDate = date);
    }
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Pelanggan Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'No. telepon wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newCustomer = Customer(
                  id: '',
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  createdAt: DateTime.now(),
                );
                final success = await ref
                    .read(customerFormProvider.notifier)
                    .createCustomer(newCustomer);
                if (success) {
                  await ref.read(customerListProvider.notifier).loadCustomers();
                  // Get the newly created customer
                  final customers = ref.read(customerListProvider).data ?? [];
                  final created = customers.firstWhere(
                    (c) => c.phone == phoneController.text.trim(),
                    orElse: () => customers.last,
                  );
                  if (mounted) {
                    setState(() => _selectedCustomer = created);
                  }
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pelanggan berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(AsyncState<List<Product>> productsState) {
    productsState.when(
      initial: () {},
      loading: () {},
      success: (products) {
        showDialog(
          context: context,
          builder: (context) => _AddProductDialog(
            products: products,
            onAdd: (item) {
              ref.read(orderFormProvider.notifier).addItem(item);
            },
          ),
        );
      },
      error: (message, code) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $message')),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal pengambilan')),
      );
      return;
    }

    final dpAmount =
        double.tryParse(_dpController.text.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;

    Result<Order> result;

    if (isEditMode) {
      result = await ref
          .read(orderFormProvider.notifier)
          .updateOrder(
            orderId: widget.order!.id,
            customerId: _selectedCustomer?.id,
            deliveryDate: _deliveryDate,
            dpAmount: dpAmount,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
    } else {
      result = await ref
          .read(orderFormProvider.notifier)
          .createOrder(
            customerId: _selectedCustomer?.id,
            orderType: OrderType.po,
            deliveryDate: _deliveryDate,
            dpAmount: dpAmount,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
    }

    if (result.isSuccess && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Pesanan berhasil diupdate'
                : 'Pesanan berhasil dibuat',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${result.errorMessage}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _AddProductDialog extends StatefulWidget {
  final List<Product> products;
  final void Function(OrderItem) onAdd;

  const _AddProductDialog({required this.products, required this.onAdd});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 1;

  /// Mengurutkan produk berdasarkan kategori lalu nama
  List<Product> _getSortedProducts() {
    final sorted = List<Product>.from(widget.products);
    sorted.sort((a, b) {
      // Sort by category first
      final catCompare = (a.category ?? '').compareTo(b.category ?? '');
      if (catCompare != 0) return catCompare;
      // Then by name
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Produk'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              hint: const Text('Pilih Produk'),
              isExpanded: true,
              items: _getSortedProducts()
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.name} - Rp ${p.unitPrice.toStringAsFixed(0)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedProduct = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Jumlah: '),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Up/Down Arrow Buttons
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 1;
                        setState(() {
                          _quantityController.text = (current + 1).toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        child: const Icon(Icons.arrow_drop_up, size: 20),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 1;
                        if (current > 1) {
                          setState(() {
                            _quantityController.text = (current - 1).toString();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          ),
                        ),
                        child: const Icon(Icons.arrow_drop_down, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _selectedProduct == null
              ? null
              : () {
                  final item = OrderItem(
                    id: '',
                    orderId: '',
                    productId: _selectedProduct!.id,
                    productName: _selectedProduct!.name,
                    quantity: _quantity,
                    unitPrice: _selectedProduct!.unitPrice,
                    subtotal: _quantity * _selectedProduct!.unitPrice,
                    createdAt: DateTime.now(),
                  );
                  widget.onAdd(item);
                  Navigator.pop(context);
                },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}

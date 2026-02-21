import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/utils/async_state.dart';
import '../../data/models/supplier.dart';
import '../../data/models/raw_material.dart';
import '../../data/models/purchase.dart';
import '../../data/providers/purchase_providers.dart';
import 'supplier_form_dialog.dart';

/// Dialog untuk membuat pembelian baru
class PurchaseFormDialog extends ConsumerStatefulWidget {
  const PurchaseFormDialog({super.key});

  @override
  ConsumerState<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends ConsumerState<PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  Supplier? _selectedSupplier;
  final List<_PurchaseItemEntry> _items = [];
  bool _isLoading = false;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supplierListProvider.notifier).loadSuppliers();
      ref.read(materialListProvider.notifier).loadMaterials();
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalCost {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final supplierState = ref.watch(supplierListProvider);
    final materialState = ref.watch(materialListProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      child: Container(
        width: isDesktop ? 600 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_shopping_cart, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Catat Pembelian Bahan',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date & Invoice Row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Pembelian',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_purchaseDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceController,
                              decoration: const InputDecoration(
                                labelText: 'No. Invoice',
                                prefixIcon: Icon(Icons.receipt),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Supplier Dropdown
                      supplierState.when(
                        initial: () => const LinearProgressIndicator(),
                        loading: () => const LinearProgressIndicator(),
                        success: (suppliers) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Supplier>(
                                initialValue: _selectedSupplier,
                                decoration: const InputDecoration(
                                  labelText: 'Supplier',
                                  prefixIcon: Icon(Icons.store),
                                ),
                                items: suppliers.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedSupplier = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const SupplierFormDialog(),
                                  );
                                  if (result == true) {
                                    // Refresh list and keep dialog open
                                    ref
                                        .read(supplierListProvider.notifier)
                                        .loadSuppliers();
                                  }
                                },
                                icon: Icon(Icons.add, color: AppColors.primary),
                                tooltip: 'Tambah Supplier Baru',
                              ),
                            ),
                          ],
                        ),
                        error: (msg, code) => Text('Error: $msg'),
                      ),
                      const SizedBox(height: 24),

                      // Items Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Item Pembelian',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          FilledButton.icon(
                            onPressed: () => _addItem(materialState),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 22,
                            ),
                            label: const Text('Tambah Item'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Belum ada item',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_items.length, (index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.material.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => _items.removeAt(index),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  // Responsive layout: vertical on mobile, horizontal on desktop
                                  if (isDesktop)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.quantity
                                                .toString(),
                                            decoration: InputDecoration(
                                              labelText: 'Qty',
                                              suffixText: item.material.unit,
                                              isDense: true,
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                item.quantity =
                                                    double.tryParse(value) ?? 0;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            initialValue: item.unitCost
                                                .toStringAsFixed(0),
                                            decoration: const InputDecoration(
                                              labelText: 'Harga Satuan',
                                              prefixText: 'Rp ',
                                              isDense: true,
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                item.unitCost =
                                                    double.tryParse(value) ?? 0;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            _currencyFormat.format(
                                              item.subtotal,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    // Mobile: Qty full width
                                    TextFormField(
                                      initialValue: item.quantity.toString(),
                                      decoration: InputDecoration(
                                        labelText: 'Jumlah (Qty)',
                                        suffixText: item.material.unit,
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          item.quantity =
                                              double.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Mobile: Harga Satuan full width
                                    TextFormField(
                                      initialValue: item.unitCost
                                          .toStringAsFixed(0),
                                      decoration: const InputDecoration(
                                        labelText: 'Harga Satuan',
                                        prefixText: 'Rp ',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          item.unitCost =
                                              double.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Mobile: Subtotal row
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Subtotal: ${_currencyFormat.format(item.subtotal)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 16),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(_totalCost),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading || _items.isEmpty
                        ? null
                        : _savePurchase,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  void _addItem(AsyncState<List<RawMaterial>> materialState) {
    if (materialState.isSuccess && materialState.data != null) {
      final materials = materialState.data!;
      if (materials.isEmpty) {
        CustomToast.showWarning(
          context: context,
          title: 'Belum Ada Bahan Baku',
          subtitle: 'Tambahkan bahan baku terlebih dahulu.',
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => _SelectMaterialDialog(
          materials: materials,
          existingMaterialIds: _items.map((i) => i.material.id).toList(),
        ),
      ).then((material) {
        if (material != null) {
          setState(() {
            _items.add(
              _PurchaseItemEntry(
                material: material,
                quantity: 1,
                unitCost: material.lastPurchasePrice ?? 0,
              ),
            );
          });
        }
      });
    }
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) return;

    setState(() => _isLoading = true);

    final purchase = Purchase(
      id: '',
      supplierId: _selectedSupplier?.id,
      purchaseDate: _purchaseDate,
      totalCost: _totalCost,
      invoiceNumber: _invoiceController.text.trim().isEmpty
          ? null
          : _invoiceController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final purchaseItems = _items.map((item) {
      return PurchaseItem(
        id: '',
        purchaseId: '',
        materialId: item.material.id,
        quantity: item.quantity,
        unitCost: item.unitCost,
        subtotal: item.subtotal,
      );
    }).toList();

    final success = await ref
        .read(purchaseListProvider.notifier)
        .createPurchase(purchase, purchaseItems);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      CustomToast.showSuccess(
        context: context,
        title: 'Pembelian Berhasil Dicatat',
        subtitle: 'Data pembelian telah disimpan.',
      );
    } else if (mounted) {
      CustomToast.showError(
        context: context,
        title: 'Gagal Menyimpan Pembelian',
        subtitle: 'Silakan coba lagi.',
      );
    }
  }
}

class _PurchaseItemEntry {
  final RawMaterial material;
  double quantity;
  double unitCost;

  _PurchaseItemEntry({
    required this.material,
    required this.quantity,
    required this.unitCost,
  });

  double get subtotal => quantity * unitCost;
}

class _SelectMaterialDialog extends StatelessWidget {
  final List<RawMaterial> materials;
  final List<String> existingMaterialIds;

  const _SelectMaterialDialog({
    required this.materials,
    required this.existingMaterialIds,
  });

  @override
  Widget build(BuildContext context) {
    final availableMaterials = materials
        .where((m) => !existingMaterialIds.contains(m.id))
        .toList();

    return AlertDialog(
      title: const Text('Pilih Bahan'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: availableMaterials.isEmpty
            ? const Center(child: Text('Semua bahan sudah ditambahkan'))
            : ListView.builder(
                itemCount: availableMaterials.length,
                itemBuilder: (context, index) {
                  final material = availableMaterials[index];
                  return ListTile(
                    title: Text(material.name),
                    subtitle: Text('Stok: ${material.stockDisplay}'),
                    onTap: () => Navigator.pop(context, material),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/utils/result.dart';
import '../../data/models/raw_material.dart';
import '../../data/providers/purchase_providers.dart';

/// Raw Materials Page - Daftar Bahan Baku
class RawMaterialsPage extends ConsumerStatefulWidget {
  const RawMaterialsPage({super.key});

  @override
  ConsumerState<RawMaterialsPage> createState() => _RawMaterialsPageState();
}

class _RawMaterialsPageState extends ConsumerState<RawMaterialsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(materialListProvider.notifier).loadMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialState = ref.watch(materialListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bahan Baku'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showAddMaterialDialog(context),
            icon: const Icon(Icons.add_circle, size: 22),
            label: const Text('Tambah Bahan'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(materialListProvider.notifier).loadMaterials(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: materialState.when(
        initial: () => const Center(child: Text('Memuat data...')),
        loading: () => const Center(child: CircularProgressIndicator()),
        success: (materials) => materials.isEmpty
            ? _EmptyState(onAdd: () => _showAddMaterialDialog(context))
            : _MaterialGrid(
                materials: materials,
                onEdit: (m) => _showEditMaterialDialog(context, m),
                onDelete: _deleteMaterial,
              ),
        error: (message, code) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $message'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(materialListProvider.notifier).loadMaterials(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMaterialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MaterialFormDialog(),
    ).then((result) {
      if (result == true) {
        ref.read(materialListProvider.notifier).loadMaterials();
      }
    });
  }

  void _showEditMaterialDialog(BuildContext context, RawMaterial material) {
    showDialog(
      context: context,
      builder: (context) => _MaterialFormDialog(material: material),
    ).then((result) {
      if (result == true) {
        ref.read(materialListProvider.notifier).loadMaterials();
      }
    });
  }

  Future<void> _deleteMaterial(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Bahan'),
        content: const Text('Apakah Anda yakin ingin menghapus bahan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(materialListProvider.notifier).deleteMaterial(id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada bahan baku',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan bahan baku untuk mencatat pembelian',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Bahan'),
          ),
        ],
      ),
    );
  }
}

class _MaterialGrid extends StatelessWidget {
  final List<RawMaterial> materials;
  final void Function(RawMaterial) onEdit;
  final Future<void> Function(String) onDelete;

  const _MaterialGrid({
    required this.materials,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MaterialCard(
                  material: material,
                  onEdit: () => onEdit(material),
                  onDelete: () => onDelete(material.id),
                ),
              );
            },
          );
        }

        final crossAxisCount = constraints.maxWidth < 1000 ? 2 : 4;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return _MaterialCard(
              material: material,
              onEdit: () => onEdit(material),
              onDelete: () => onDelete(material.id),
            );
          },
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final RawMaterial material;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.onEdit,
    required this.onDelete,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    material.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildPriceTrend(material),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stok',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      material.stockDisplay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: material.isLowStock
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                    if (material.baseUnit != null &&
                        material.unit != material.baseUnit)
                      Text(
                        '1 ${material.unit} = ${material.unitConversion.toStringAsFixed(0)} ${material.baseUnit}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                if (material.isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Stok Rendah',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPriceHistory(context, material),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Riwayat', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit Bahan',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                  onPressed: onDelete,
                  tooltip: 'Hapus Bahan',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTrend(RawMaterial material) {
    if (material.lastPurchasePrice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            'Rp ${material.lastPurchasePrice?.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceHistory(BuildContext context, RawMaterial material) {
    showDialog(
      context: context,
      builder: (context) => _PriceHistoryDialog(material: material),
    );
  }
}

class _PriceHistoryDialog extends ConsumerWidget {
  final RawMaterial material;

  const _PriceHistoryDialog({required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(purchaseRepositoryProvider);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Harga'),
          Text(
            material.name,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: FutureBuilder<Result<List<Map<String, dynamic>>>>(
          future: repository.getMaterialPriceHistory(material.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data;
            if (result == null || result.isFailure) {
              return Center(
                child: Text('Gagal memuat data: ${result?.errorMessage}'),
              );
            }

            final history = result.dataOrNull ?? [];
            if (history.isEmpty) {
              return const Center(child: Text('Belum ada riwayat pembelian.'));
            }

            return ListView.separated(
              itemCount: history.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = history[index];
                final cost = (item['unit_cost'] as num).toDouble();
                final dateStr =
                    item['material_purchases']['purchase_date'] as String;
                final date = DateTime.parse(dateStr);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Rp ${cost.toStringAsFixed(0)} / ${material.unit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Tanggal: ${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: index > 0
                      ? _buildPriceChangeIndicator(
                          cost,
                          (history[index - 1]['unit_cost'] as num).toDouble(),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildPriceChangeIndicator(double current, double previous) {
    if (current == previous) {
      return const Icon(Icons.remove, color: Colors.grey, size: 16);
    }

    final isUp = current > previous;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          color: isUp ? Colors.red : Colors.green,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${((current - previous) / previous * 100).abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: isUp ? Colors.red : Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MaterialFormDialog extends ConsumerStatefulWidget {
  final RawMaterial? material;

  const _MaterialFormDialog({this.material});

  @override
  ConsumerState<_MaterialFormDialog> createState() =>
      _MaterialFormDialogState();
}

class _MaterialFormDialogState extends ConsumerState<_MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _conversionController;
  String _selectedUnit = 'pcs';
  String? _selectedBaseUnit;
  bool _isLoading = false;

  static const _units = [
    'pcs',
    'kg',
    'gr',
    'mg',
    'liter',
    'ml',
    'pack',
    'dus',
    'ikat',
    'lembar',
    'butir',
    'sdm',
    'sdt',
    'cup',
  ];

  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.material?.name ?? '');
    _stockController = TextEditingController(
      text: widget.material?.stockQty.toString() ?? '0',
    );
    _minStockController = TextEditingController(
      text: widget.material?.minStockAlert?.toString() ?? '10',
    );
    _conversionController = TextEditingController(
      text: widget.material?.unitConversion.toString() ?? '1',
    );
    _selectedUnit = widget.material?.unit ?? 'pcs';
    _selectedBaseUnit = widget.material?.baseUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _conversionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Bahan' : 'Tambah Bahan Baru'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bahan *',
                  hintText: 'Contoh: Tepung Terigu',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama bahan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stok Awal'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Satuan'),
                      items: _units.map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Alert Stok Minimum',
                  helperText: 'Notifikasi jika stok di bawah angka ini',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
              ),
              const Divider(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Konversi Satuan Resep',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBaseUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit di Resep',
                        hintText: 'Misal: butir',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('- SAMA -'),
                        ),
                        ..._units.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedBaseUnit = value);
                      },
                    ),
                  ),
                  if (_selectedBaseUnit != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _conversionController,
                        decoration: InputDecoration(
                          labelText: '1 $_selectedUnit = ...',
                          suffixText: _selectedBaseUnit,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (_selectedBaseUnit != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Contoh: Jika beli Telur per KG, tapi di resep pakai "Butir". \nSet 1 kg = 16 butir.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveMaterial,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final material = RawMaterial(
      id: widget.material?.id ?? '',
      name: _nameController.text.trim(),
      unit: _selectedUnit,
      baseUnit: _selectedBaseUnit,
      unitConversion: double.tryParse(_conversionController.text) ?? 1.0,
      stockQty: double.tryParse(_stockController.text) ?? 0,
      minStockAlert: double.tryParse(_minStockController.text),
      createdAt: widget.material?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(materialListProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateMaterial(material);
    } else {
      success = await notifier.createMaterial(material);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      CustomToast.showSuccess(
        context: context,
        title: _isEditing
            ? 'Bahan Berhasil Diupdate'
            : 'Bahan Berhasil Ditambahkan',
        subtitle: 'Data bahan baku telah disimpan.',
      );
    }
  }
}

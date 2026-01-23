import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(materialListProvider.notifier).loadMaterials(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMaterialDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
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
              ],
            ),
            const Spacer(),
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
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: onEdit,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
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
  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  static const _units = ['pcs', 'kg', 'gr', 'liter', 'ml', 'pack'];

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
    _selectedUnit = widget.material?.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
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

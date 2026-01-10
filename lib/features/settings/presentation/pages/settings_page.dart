import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/providers/category_providers.dart';
import '../../data/providers/product_settings_provider.dart';

/// Settings Page - Halaman Pengaturan
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryListProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoryListProvider);
    final productSettings = ref.watch(productSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Config Warning Banner if not configured
          if (!SupabaseConfig.isConfigured)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supabase Belum Dikonfigurasi',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Buka lib/core/config/supabase_config.dart dan isi URL & Anon Key.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Category Management
          _SettingsSection(
            title: 'Kategori Produk',
            trailing: IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _showCategoryDialog(),
            ),
            children: [
              categoriesState.when(
                initial: () =>
                    const ListTile(title: Text('Memuat kategori...')),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                success: (categories) => categories.isEmpty
                    ? const ListTile(
                        leading: Icon(Icons.category_outlined),
                        title: Text('Belum ada kategori'),
                        subtitle: Text('Tap + untuk menambah'),
                      )
                    : Column(
                        children: categories
                            .map(
                              (cat) => _buildItemTile(
                                icon: Icons.label_outline,
                                text: cat.name,
                                onEdit: () =>
                                    _showCategoryDialog(category: cat),
                                onDelete: () => _confirmDeleteCategory(cat),
                              ),
                            )
                            .toList(),
                      ),
                error: (message, code) => ListTile(
                  leading: const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                  ),
                  title: Text('Error: $message'),
                ),
              ),
            ],
          ),

          // Jenis Produk (Product Types)
          _SettingsSection(
            title: 'Jenis Produk',
            trailing: IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _showSimpleInputDialog(
                title: 'Tambah Jenis Produk',
                hint: 'Contoh: Cake, Pastry, Bread',
                onSave: (value) => ref
                    .read(productSettingsProvider.notifier)
                    .addProductType(value),
              ),
            ),
            children: [
              if (productSettings.productTypes.isEmpty)
                const ListTile(
                  leading: Icon(Icons.cake_outlined),
                  title: Text('Belum ada jenis produk'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: productSettings.productTypes.map((type) {
                    return _SettingChip(
                      label: type,
                      onEdit: () => _showSimpleInputDialog(
                        title: 'Edit Jenis Produk',
                        hint: 'Nama Jenis',
                        initialValue: type,
                        onSave: (value) => ref
                            .read(productSettingsProvider.notifier)
                            .updateProductType(type, value),
                      ),
                      onDelete: () => ref
                          .read(productSettingsProvider.notifier)
                          .removeProductType(type),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Ukuran Produk (Product Sizes)
          _SettingsSection(
            title: 'Ukuran Produk',
            trailing: IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _showSimpleInputDialog(
                title: 'Tambah Ukuran Produk',
                hint: 'Contoh: 22 cm, Large, Regular',
                onSave: (value) =>
                    ref.read(productSettingsProvider.notifier).addSize(value),
              ),
            ),
            children: [
              if (productSettings.sizes.isEmpty)
                const ListTile(
                  leading: Icon(Icons.straighten),
                  title: Text('Belum ada ukuran'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: productSettings.sizes.map((size) {
                    return _SettingChip(
                      label: size,
                      onEdit: () => _showSimpleInputDialog(
                        title: 'Edit Ukuran',
                        hint: 'Ukuran',
                        initialValue: size,
                        onSave: (value) => ref
                            .read(productSettingsProvider.notifier)
                            .updateSize(size, value),
                      ),
                      onDelete: () => ref
                          .read(productSettingsProvider.notifier)
                          .removeSize(size),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Satuan Produk (Product Units)
          _SettingsSection(
            title: 'Satuan Produk',
            trailing: IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _showSimpleInputDialog(
                title: 'Tambah Satuan Produk',
                hint: 'Contoh: pcs, box, slice',
                onSave: (value) =>
                    ref.read(productSettingsProvider.notifier).addUnit(value),
              ),
            ),
            children: [
              if (productSettings.units.isEmpty)
                const ListTile(
                  leading: Icon(Icons.straighten),
                  title: Text('Belum ada satuan'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: productSettings.units.map((unit) {
                    return _SettingChip(
                      label: unit,
                      onEdit: () => _showSimpleInputDialog(
                        title: 'Edit Satuan',
                        hint: 'Satuan',
                        initialValue: unit,
                        onSave: (value) => ref
                            .read(productSettingsProvider.notifier)
                            .updateUnit(unit, value),
                      ),
                      onDelete: () => ref
                          .read(productSettingsProvider.notifier)
                          .removeUnit(unit),
                    );
                  }).toList(),
                ),
            ],
          ),

          // App Info
          _SettingsSection(
            title: 'Aplikasi',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Tentang LF Kitchen'),
                subtitle: const Text('Versi 1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'LF Kitchen',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 LF Kitchen',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset Pengaturan Produk'),
                subtitle: const Text('Kembalikan ke nilai default'),
                onTap: () => _confirmResetSettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required IconData icon,
    required String text,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  void _showSimpleInputDialog({
    required String title,
    required String hint,
    String? initialValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: hint),
            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSave(controller.text.trim());
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil disimpan'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({Category? category}) {
    final isEdit = category != null;
    final controller = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'contoh: Snack Box, Kue Kering',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nama kategori wajib diisi' : null,
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
                bool success;
                if (isEdit) {
                  success = await ref
                      .read(categoryListProvider.notifier)
                      .updateCategory(
                        category!.copyWith(name: controller.text.trim()),
                      );
                } else {
                  success = await ref
                      .read(categoryListProvider.notifier)
                      .createCategory(
                        Category(id: '', name: controller.text.trim()),
                      );
                }

                Navigator.pop(dialogContext);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Kategori berhasil diupdate'
                            : 'Kategori berhasil ditambahkan',
                      ),
                      backgroundColor: AppColors.success,
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

  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final success = await ref
                  .read(categoryListProvider.notifier)
                  .deleteCategory(category.id);
              Navigator.pop(dialogContext);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori berhasil dihapus'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmResetSettings() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Pengaturan'),
        content: const Text(
          'Kembalikan semua jenis, ukuran, dan satuan produk ke nilai default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(productSettingsProvider.notifier).resetToDefaults();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan berhasil direset'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _SettingChip extends StatelessWidget {
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SettingChip({
    required this.label,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDelete,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: AppColors.primary),
      deleteIconColor: Colors.grey.shade600,
    );
  }
}

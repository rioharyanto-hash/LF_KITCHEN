import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/providers/category_providers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
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
                          'Buka lib/core/config/supabase_config.dart dan isi URL & Anon Key dari project Supabase Anda.',
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
                        subtitle: Text('Tap + untuk menambah kategori'),
                      )
                    : Column(
                        children: categories
                            .map(
                              (cat) => ListTile(
                                leading: const Icon(Icons.label_outline),
                                title: Text(cat.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _showCategoryDialog(category: cat),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: AppColors.error,
                                      onPressed: () => _confirmDelete(cat),
                                    ),
                                  ],
                                ),
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
            ],
          ),

          // Data Settings
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Backup Data'),
                subtitle: const Text('Export semua data ke file'),
                onTap: () {
                  // TODO: Implement backup
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore Data'),
                subtitle: const Text('Import data dari file backup'),
                onTap: () {
                  // TODO: Implement restore
                },
              ),
            ],
          ),

          // Theme Settings
          _SettingsSection(
            title: 'Tampilan',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Mode Gelap'),
                value: false, // TODO: Connect to theme provider
                onChanged: (value) {
                  // TODO: Toggle theme
                },
              ),
            ],
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

  void _confirmDelete(Category category) {
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
        ...children,
        const Divider(),
      ],
    );
  }
}

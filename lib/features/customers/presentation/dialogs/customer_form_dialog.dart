import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../data/models/customer.dart';
import '../../data/providers/customer_providers.dart';

/// Customer Form Dialog for Create/Edit
class CustomerFormDialog extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  bool _isSpecialPrice = false;

  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    _notesController = TextEditingController(
      text: widget.customer?.notes ?? '',
    );
    _isSpecialPrice = widget.customer?.isSpecialPrice ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.person_add,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(_isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
        ],
      ),
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
                  labelText: 'Nama *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP/WA *',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '08xxxxxxxxxx',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor HP wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 16),
              // Special Price Checkbox
              CheckboxListTile(
                value: _isSpecialPrice,
                onChanged: (value) =>
                    setState(() => _isSpecialPrice = value ?? false),
                title: const Text('Harga Spesial'),
                subtitle: const Text('Pelanggan ini mendapat harga spesial'),
                secondary: Icon(
                  Icons.star,
                  color: _isSpecialPrice ? Colors.amber : Colors.grey,
                ),
                contentPadding: EdgeInsets.zero,
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
          onPressed: _isLoading ? null : _saveCustomer,
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

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = Customer(
      id: widget.customer?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isSpecialPrice: _isSpecialPrice,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(customerFormProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateCustomer(customer);
    } else {
      success = await notifier.createCustomer(customer);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      CustomToast.showSuccess(
        context: context,
        title: _isEditing
            ? 'Pelanggan Berhasil Diupdate'
            : 'Pelanggan Berhasil Ditambahkan',
        subtitle: 'Data pelanggan telah disimpan.',
      );
    } else if (mounted) {
      final state = ref.read(customerFormProvider);
      final errorMsg = state.isError ? state.errorMessage : 'Unknown error';
      CustomToast.showError(
        context: context,
        title: 'Gagal Menyimpan Pelanggan',
        subtitle: errorMsg ?? 'Terjadi kesalahan',
      );
    }
  }
}

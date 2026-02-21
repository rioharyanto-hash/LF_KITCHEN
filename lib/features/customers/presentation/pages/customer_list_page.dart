import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/customer.dart';
import '../../data/providers/customer_providers.dart';
import '../dialogs/customer_form_dialog.dart';

/// Customer List Page - Daftar Pelanggan
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerListProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        actions: [
          IconButton(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Tambah Pelanggan',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(customerListProvider.notifier).loadCustomers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor HP...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(customerListProvider.notifier)
                              .loadCustomers();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(customerListProvider.notifier).searchCustomers(value);
              },
            ),
          ),
          // Customer List
          Expanded(
            child: customerState.when(
              initial: () => const Center(child: Text('Memuat data...')),
              loading: () => const Center(child: CircularProgressIndicator()),
              success: (customers) {
                if (customers.isEmpty) {
                  return _EmptyState(
                    onAddCustomer: () => _showAddCustomerDialog(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(customerListProvider.notifier).loadCustomers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) => _CustomerCard(
                      customer: customers[index],
                      onEdit: () =>
                          _showEditCustomerDialog(context, customers[index]),
                      onDelete: () => _deleteCustomer(customers[index].id),
                      onWhatsApp: () => _openWhatsApp(customers[index]),
                    ),
                  ),
                );
              },
              error: (message, code) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error: $message'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(customerListProvider.notifier)
                          .loadCustomers(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CustomerFormDialog(),
    ).then((result) {
      if (result == true) {
        ref.read(customerListProvider.notifier).loadCustomers();
      }
    });
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(customer: customer),
    ).then((result) {
      if (result == true) {
        ref.read(customerListProvider.notifier).loadCustomers();
      }
    });
  }

  Future<void> _deleteCustomer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: const Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
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
      await ref.read(customerListProvider.notifier).deleteCustomer(id);
    }
  }

  Future<void> _openWhatsApp(Customer customer) async {
    final uri = Uri.parse(customer.waLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddCustomer;

  const _EmptyState({required this.onAddCustomer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Belum ada pelanggan',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddCustomer,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Pelanggan'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWhatsApp;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 16,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          radius: isMobile ? 18 : 20,
          child: Text(
            customer.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone, size: isMobile ? 12 : 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customer.phone,
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (customer.address != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: isMobile ? 12 : 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 11 : 14),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: SizedBox(
          width: isMobile ? 70 : 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: isMobile ? 32 : 40,
                height: isMobile ? 32 : 40,
                child: IconButton(
                  icon: Icon(
                    Icons.message,
                    color: Colors.green,
                    size: isMobile ? 18 : 24,
                  ),
                  onPressed: onWhatsApp,
                  tooltip: 'WhatsApp',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: isMobile ? 32 : 40,
                height: isMobile ? 32 : 40,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: isMobile ? 18 : 24),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

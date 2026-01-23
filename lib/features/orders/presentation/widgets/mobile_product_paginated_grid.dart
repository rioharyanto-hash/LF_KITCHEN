import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/models/product.dart';

class MobileProductPaginatedGrid extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product)? onDecrement;
  final bool Function(Product) isSelected;
  final int Function(Product)? getQuantity;
  final bool useProductTypeAsFilter;

  const MobileProductPaginatedGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.onDecrement,
    required this.isSelected,
    this.getQuantity,
    this.useProductTypeAsFilter = false,
  });

  @override
  State<MobileProductPaginatedGrid> createState() =>
      _MobileProductPaginatedGridState();
}

class _MobileProductPaginatedGridState
    extends State<MobileProductPaginatedGrid> {
  String _selectedCategory = 'Semua';

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    // 1. Get Categories
    final Set<String> categories = {'Semua'};
    for (final p in widget.products) {
      final cat = widget.useProductTypeAsFilter
          ? (p.productType ?? 'Lainnya')
          : (p.category ?? 'Lainnya');
      if (cat.trim().isNotEmpty) categories.add(cat);
    }
    final sortedCategories = categories.toList()..sort();

    // 2. Filter Products
    final filteredProducts = _selectedCategory == 'Semua'
        ? widget.products
        : widget.products.where((p) {
            final cat = widget.useProductTypeAsFilter
                ? (p.productType ?? 'Lainnya')
                : (p.category ?? 'Lainnya');
            return cat == _selectedCategory;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category Tabs (Pill)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: sortedCategories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),

                  // Style
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: Colors.white,

                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal Paged Grid
        SizedBox(
          height: 300, // Fixed height for 3 rows x 2 cols
          child: filteredProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk'))
              : PageView.builder(
                  itemCount: (filteredProducts.length / 6).ceil(),
                  // viewportFraction 0.92 gives a peek of next page
                  controller: PageController(viewportFraction: 0.92),
                  padEnds: false,
                  itemBuilder: (context, pageIndex) {
                    final startIndex = pageIndex * 6;
                    final endIndex = (startIndex + 6) < filteredProducts.length
                        ? startIndex + 6
                        : filteredProducts.length;
                    final pageItems = filteredProducts.sublist(
                      startIndex,
                      endIndex,
                    );

                    return Container(
                      margin: const EdgeInsets.only(right: 8, left: 4),
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2, // Wide card layout
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        physics: const NeverScrollableScrollPhysics(),
                        children: pageItems.map((p) => _buildCard(p)).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCard(Product product) {
    final isSelected = widget.isSelected(product);
    final qty = widget.getQuantity?.call(product) ?? 0;

    return InkWell(
      onTap: () => widget.onProductTap(product),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (c, o, s) =>
                            Icon(Icons.cake, color: Colors.grey.shade300),
                      ),
                    )
                  : Icon(Icons.cake, color: Colors.grey.shade300),
            ),
            const SizedBox(width: 8),

            // Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  // Size Badge
                  if (product.size != null && product.size!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.size!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  // Price
                  const SizedBox(height: 2),
                  Text(
                    _currencyFormat.format(product.unitPrice),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Action Icon or Qty Control
            if (isSelected && qty > 0)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onDecrement != null)
                    InkWell(
                      onTap: () => widget.onDecrement!(product),
                      child: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                    ),
                ],
              )
            else if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24)
            else
              Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade300,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

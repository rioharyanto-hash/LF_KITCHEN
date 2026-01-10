import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/models/product.dart';

/// Cart item for POS
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

/// Cart state
class CartState {
  final List<CartItem> items;
  final bool isProcessing;

  const CartState({this.items = const [], this.isProcessing = false});

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({List<CartItem>? items, bool? isProcessing}) {
    return CartState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// POS Cart Notifier
class PosCartNotifier extends StateNotifier<CartState> {
  PosCartNotifier() : super(const CartState());

  void addProduct(Product product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Increase quantity
      final newItems = [...state.items];
      newItems[existingIndex] = newItems[existingIndex].copyWith(
        quantity: newItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: newItems);
    } else {
      // Add new item
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(product: product),
        ],
      );
    }
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final newItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: newItems);
  }

  void incrementQuantity(String productId) {
    final item = state.items.firstWhere(
      (i) => i.product.id == productId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(productId, item.quantity + 1);
  }

  void decrementQuantity(String productId) {
    final item = state.items.firstWhere(
      (i) => i.product.id == productId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(productId, item.quantity - 1);
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  void clearCart() {
    state = const CartState();
  }
}

/// Provider for POS Cart
final posCartProvider = StateNotifierProvider<PosCartNotifier, CartState>((
  ref,
) {
  return PosCartNotifier();
});

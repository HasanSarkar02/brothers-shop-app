import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_model.dart';
import '../repository/cart_repository.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';

final cartRepositoryProvider = Provider((_) => CartRepository());

// ── Cart State ─────────────────────────────────────
class CartState {
  final List<CartModel> items;
  final double cartTotal;
  final double savings;
  final bool isLoading;
  final String? error;

  const CartState({
    this.items = const [],
    this.cartTotal = 0,
    this.savings = 0,
    this.isLoading = false,
    this.error,
  });

  int get cartCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartModel>? items,
    double? cartTotal,
    double? savings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => CartState(
    items: items ?? this.items,
    cartTotal: cartTotal ?? this.cartTotal,
    savings: savings ?? this.savings,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

// ── Cart Notifier ──────────────────────────────────
class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repo;

  CartNotifier(this._repo) : super(const CartState());

  // ── Load cart from API ─────────────────────────
  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _repo.getCart();
      state = state.copyWith(
        items: summary.items,
        cartTotal: summary.cartTotal,
        savings: summary.savings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Add to cart (Optimistic UI) ────────────────
  Future<void> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    try {
      final result = await _repo.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );

      if (result['status'] == true) {
        await loadCart();
      } else {
        throw ApiException(result['message'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Update quantity (Optimistic UI) ───────────
  Future<void> updateQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final oldItems = state.items;
    final newItems = state.items.map((item) {
      if (item.cartId == cartId) {
        return item.copyWith(
          quantity: quantity,
          itemTotal: item.price * quantity,
        );
      }
      return item;
    }).toList();

    final newTotal = newItems.fold<double>(0, (sum, i) => sum + i.itemTotal);

    state = state.copyWith(items: newItems, cartTotal: newTotal);

    try {
      await _repo.updateCart(cartId: cartId, quantity: quantity);
    } catch (e) {
      state = state.copyWith(items: oldItems);
      rethrow;
    }
  }

  // ── Remove item (Optimistic UI) ───────────────
  Future<void> removeItem(int cartId) async {
    final oldItems = state.items;
    final newItems = state.items
        .where((item) => item.cartId != cartId)
        .toList();
    final newTotal = newItems.fold<double>(0, (sum, i) => sum + i.itemTotal);

    state = state.copyWith(items: newItems, cartTotal: newTotal);

    try {
      await _repo.removeFromCart(cartId);
    } catch (e) {
      state = state.copyWith(items: oldItems);
      rethrow;
    }
  }

  // ── Clear cart ─────────────────────────────────
  Future<void> clearCart() async {
    final oldItems = state.items;
    state = state.copyWith(items: [], cartTotal: 0, savings: 0);
    try {
      await _repo.clearCart();
    } catch (e) {
      state = state.copyWith(items: oldItems);
      rethrow;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.read(cartRepositoryProvider));
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cartCount;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';
import '../../product/models/product_model.dart';
import '../repository/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider((_) => WishlistRepository());

// ── Wishlist State ─────────────────────────────────
class WishlistState {
  final List<ProductModel> items;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    List<ProductModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isWishlisted(int productId) {
    return items.any((item) => item.id == productId);
  }
}

// ── Wishlist Notifier ──────────────────────────────
class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repo;

  // TODO: Replace this with your actual Auth check (e.g., from SharedPrefs or AuthProvider)
  bool get _isLoggedIn => false;

  WishlistNotifier(this._repo) : super(const WishlistState()) {
    _initWishlist();
  }

  Future<void> _initWishlist() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_isLoggedIn) {
        // ১. লগইন থাকলে সার্ভার থেকে ডেটা আনবে
        final items = await _repo.getWishlist();
        state = state.copyWith(items: items, isLoading: false);
        _saveIdsToLocal(items);
      } else {
        // ২. লগইন না থাকলে লোকাল স্টোরেজ থেকে আইডি নিয়ে সার্ভারে ডিটেইলস চাইবে
        final localIds = await LocalStorage.getLocalWishlistIds();
        if (localIds.isNotEmpty) {
          final items = await _repo.getGuestWishlistItems(localIds);
          state = state.copyWith(items: items, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Toggle Wishlist (Optimistic UI) ──────────────
  Future<void> toggleWishlist(ProductModel product) async {
    final isExisting = state.isWishlisted(product.id);
    final oldItems = state.items;

    // ✅ Optimistic update: সাথে সাথে UI চেঞ্জ
    List<ProductModel> newItems;
    if (isExisting) {
      newItems = state.items.where((p) => p.id != product.id).toList();
    } else {
      newItems = [...state.items, product];
    }

    state = state.copyWith(items: newItems);
    _saveIdsToLocal(newItems);

    // ✅ যদি লগইন করা থাকে, তবেই সার্ভারে টগল রিকোয়েস্ট পাঠাবে
    if (_isLoggedIn) {
      try {
        await _repo.toggleWishlist(product.id);
      } catch (e) {
        // ❌ API Fail হলে আগের অবস্থায় ফিরিয়ে আনা
        state = state.copyWith(items: oldItems);
        _saveIdsToLocal(oldItems);
        print('🔴 Wishlist Toggle Failed: $e');
      }
    } else {
      // গেস্ট ইউজার হলে শুধু লোকাল স্টোরেজেই সেভ থাকবে, কোনো এরর থ্রো করবে না!
      print('🟢 Guest User: Item saved locally to wishlist.');
    }
  }

  void _saveIdsToLocal(List<ProductModel> items) {
    final ids = items.map((e) => e.id).toList();
    LocalStorage.saveLocalWishlistIds(ids);
  }
}

// ── Providers ──────────────────────────────────────
final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    return WishlistNotifier(ref.read(wishlistRepositoryProvider));
  },
);

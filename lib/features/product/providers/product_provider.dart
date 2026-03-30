import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../repository/product_repository.dart';

final productRepositoryProvider = Provider((_) => ProductRepository());

// ── Filter State ───────────────────────────────────
class ProductFilter {
  final String? category;
  final String? search;
  final String sort;
  final double? minPrice;
  final double? maxPrice;

  const ProductFilter({
    this.category,
    this.search,
    this.sort = 'new',
    this.minPrice,
    this.maxPrice,
  });

  ProductFilter copyWith({
    String? category,
    String? search,
    String? sort,
    double? minPrice,
    double? maxPrice,
  }) => ProductFilter(
    category: category ?? this.category,
    search: search ?? this.search,
    sort: sort ?? this.sort,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
  );
}

final productFilterProvider = StateProvider<ProductFilter>(
  (_) => const ProductFilter(),
);

// ── Product List State ─────────────────────────────
class ProductListState {
  final List<ProductModel> products;
  final ProductListMeta? meta;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const ProductListState({
    this.products = const [],
    this.meta,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  ProductListState copyWith({
    List<ProductModel>? products,
    ProductListMeta? meta,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) => ProductListState(
    products: products ?? this.products,
    meta: meta ?? this.meta,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error ?? this.error,
  );
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repo;
  final Ref _ref;
  int _currentPage = 1;

  ProductListNotifier(this._repo, this._ref) : super(const ProductListState());

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = state.copyWith(isLoading: true, error: null);
    }

    final filter = _ref.read(productFilterProvider);

    try {
      final result = await _repo.getProducts(
        page: _currentPage,
        category: filter.category,
        search: filter.search,
        sort: filter.sort,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
      );

      final newProducts = result['products'] as List<ProductModel>;
      final meta = result['meta'] as ProductListMeta;

      state = state.copyWith(
        products: refresh ? newProducts : [...state.products, ...newProducts],
        meta: meta,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      print('❌ Product Error: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    if (!(state.meta?.hasMore ?? false)) return;

    _currentPage++;
    state = state.copyWith(isLoadingMore: true);
    await load();
  }

  Future<void> applyFilter(ProductFilter filter) async {
    _ref.read(productFilterProvider.notifier).state = filter;
    await load(refresh: true);
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
      return ProductListNotifier(ref.read(productRepositoryProvider), ref);
    });

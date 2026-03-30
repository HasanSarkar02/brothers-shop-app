import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_header.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialSearch;

  const ProductListScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _selectedSort = 'new';

  final _sortOptions = {
    'new': 'Newest',
    'price_low': 'Price: Low to High',
    'price_high': 'Price: High to Low',
    'trending': 'Trending',
  };

  @override
  void initState() {
    super.initState();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).load(refresh: true);
    });

    // Infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter({String? sort}) {
    final current = ref.read(productFilterProvider);
    ref
        .read(productListProvider.notifier)
        .applyFilter(
          current.copyWith(
            sort: sort ?? _selectedSort,
            search: _searchController.text.isEmpty
                ? null
                : _searchController.text,
            category: widget.initialCategory,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.initialCategory != null
              ? widget.initialCategory!.toUpperCase()
              : 'All Products',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: Row(
              children: [
                // Search bar
                Expanded(
                  child: Container(
                    height: 42.h,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.inkLight,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18.sp,
                          color: AppColors.inkLight,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      onSubmitted: (_) => _applyFilter(),
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // Sort button
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    height: 42.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Sort',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: state.isLoading
          ? _buildShimmer()
          : state.error != null
          ? _buildError(state.error!)
          : state.products.isEmpty
          ? _buildEmpty()
          : _buildProductGrid(state),
    );
  }

  Widget _buildProductGrid(ProductListState state) {
    return Column(
      children: [
        // Result count
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: Row(
            children: [
              Text(
                '${state.meta?.total ?? 0} products found',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.65,
            ),
            itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
            itemBuilder: (_, i) {
              if (i >= state.products.length) {
                return _shimmerCard();
              }
              return ProductCard(product: state.products[i]);
            },
          ),
        ),
      ],
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 16.h),
            ..._sortOptions.entries.map((e) {
              final selected = _selectedSort == e.key;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSort = e.key);
                  Navigator.pop(context);
                  _applyFilter(sort: e.key);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 16.w,
                  ),
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? AppColors.primary : AppColors.ink,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 18.sp,
                        ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48.sp,
            color: AppColors.inkLight,
          ),
          SizedBox(height: 12.h),
          Text(
            error,
            style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () =>
                ref.read(productListProvider.notifier).load(refresh: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56.sp,
            color: AppColors.border,
          ),
          SizedBox(height: 12.h),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Try different filters or search terms',
            style: TextStyle(fontSize: 13.sp, color: AppColors.inkLight),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';

// ── Provider ───────────────────────────────────────
final productDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, slug) async {
      return ref.read(productRepositoryProvider).getProductDetail(slug);
    });

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  VariantModel? _selectedVariant;
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const _ProductDetailShimmer(),
        error: (e, _) => _buildError(),
        data: (data) {
          final product = data['product'] as ProductModel;
          final reviews = data['reviews'] as List;
          final relatedProducts =
              data['related_products'] as List<ProductModel>;
          final starDist = data['star_distribution'] as Map;

          // All images: main + extra
          final allImages = [
            if (product.image != null) product.image!,
            ...product.images,
          ];

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Image Gallery ─────────────────
                  SliverToBoxAdapter(
                    child: _ImageGallery(
                      images: allImages,
                      selectedIndex: _selectedImageIndex,
                      onIndexChanged: (i) =>
                          setState(() => _selectedImageIndex = i),
                      onBack: () => context.pop(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24.r),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Badge & Category ──
                                Row(
                                  children: [
                                    if (product.badge != null)
                                      _Badge(label: product.badge!),
                                    if (product.category != null) ...[
                                      SizedBox(width: 8.w),
                                      Text(
                                        product.category!,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                SizedBox(height: 8.h),

                                // ── Product Name ──────
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),

                                SizedBox(height: 10.h),

                                // ── Rating ────────────
                                if (product.reviewsCount > 0)
                                  _RatingRow(
                                    rating: product.avgRating,
                                    count: product.reviewsCount,
                                  ),

                                SizedBox(height: 12.h),

                                // ── Price ─────────────
                                _PriceRow(product: product),

                                SizedBox(height: 16.h),

                                // ── Stock Status ──────
                                _StockBadge(inStock: product.inStock),

                                SizedBox(height: 20.h),

                                // ── Variants ──────────
                                if (product.variants.isNotEmpty) ...[
                                  _VariantSelector(
                                    variants: product.variants,
                                    selectedVariant: _selectedVariant,
                                    onSelect: (v) =>
                                        setState(() => _selectedVariant = v),
                                  ),
                                  SizedBox(height: 20.h),
                                ],

                                // ── Quantity ──────────
                                _QuantitySelector(
                                  quantity: _quantity,
                                  onChanged: (q) =>
                                      setState(() => _quantity = q),
                                ),

                                SizedBox(height: 20.h),

                                // ── Description ───────
                                if (product.description != null) ...[
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    product.description!,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppColors.inkLight,
                                      height: 1.6,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                ],

                                // ── Star Distribution ─
                                if (product.reviewsCount > 0) ...[
                                  Text(
                                    'Customer Reviews',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  _StarDistribution(
                                    distribution: starDist,
                                    total: product.reviewsCount,
                                    avg: product.avgRating,
                                  ),
                                  SizedBox(height: 16.h),

                                  // Reviews list
                                  ...reviews
                                      .take(5)
                                      .map((r) => _ReviewCard(review: r)),

                                  SizedBox(height: 20.h),
                                ],

                                // ── Related Products ──
                                if (relatedProducts.isNotEmpty) ...[
                                  Text(
                                    'Related Products',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  SizedBox(
                                    height: 260.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: relatedProducts.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(width: 12.w),
                                      itemBuilder: (_, i) {
                                        final p = relatedProducts[i];
                                        return _RelatedProductCard(product: p);
                                      },
                                    ),
                                  ),
                                ],

                                // Bottom padding for FAB
                                SizedBox(height: 100.h),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom Action Bar ─────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomActionBar(
                  product: product,
                  selectedVariant: _selectedVariant,
                  quantity: _quantity,
                  isLoading: _addingToCart,
                  onAddToCart: () => _addToCart(product),
                  onBuyNow: () => _buyNow(product),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addToCart(ProductModel product) async {
    // Variant required check
    if (product.variants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a variant first',
            style: TextStyle(fontSize: 13.sp),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _addingToCart = true);

    try {
      await ref
          .read(cartProvider.notifier)
          .addToCart(
            productId: product.id,
            variantId: _selectedVariant?.id,
            quantity: _quantity,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${product.name} added to cart!',
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add to cart',
              style: TextStyle(fontSize: 13.sp),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _buyNow(ProductModel product) async {
    await _addToCart(product);
    if (mounted) context.push('/checkout');
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
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
              'Product not found',
              style: TextStyle(fontSize: 16.sp, color: AppColors.inkLight),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => ref.refresh(productDetailProvider(widget.slug)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image Gallery ──────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onBack;

  const _ImageGallery({
    required this.images,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340.h,
      child: Stack(
        children: [
          // Main image
          PageView.builder(
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: onIndexChanged,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images.isEmpty ? '' : images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: AppColors.surface),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surface,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 48.sp,
                  color: AppColors.border,
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 16.w,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20.sp,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),

          // Image dots
          if (images.length > 1)
            Positioned(
              bottom: 12.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((e) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: selectedIndex == e.key ? 20.w : 6.w,
                    height: 6.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99.r),
                      color: selectedIndex == e.key
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.6),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Price Row ──────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final ProductModel product;
  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '৳${product.displayPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: -1,
          ),
        ),
        if (product.discountPrice != null) ...[
          SizedBox(width: 8.w),
          Text(
            '৳${product.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15.sp,
              color: AppColors.inkLight,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '${product.discountPercent}% OFF',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Rating Row ─────────────────────────────────────
class _RatingRow extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingRow({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < rating.floor()
                ? Icons.star_rounded
                : (i < rating
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            color: AppColors.amber,
            size: 16.sp,
          );
        }),
        SizedBox(width: 6.w),
        Text(
          '$rating ($count reviews)',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.inkLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Stock Badge ────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final bool inStock;
  const _StockBadge({required this.inStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: inStock
            ? AppColors.green.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: inStock ? AppColors.green : AppColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            size: 13.sp,
            color: inStock ? AppColors.green : AppColors.primary,
          ),
          SizedBox(width: 5.w),
          Text(
            inStock ? 'In Stock' : 'Out of Stock',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: inStock ? AppColors.green : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Variant Selector ───────────────────────────────
class _VariantSelector extends StatelessWidget {
  final List<VariantModel> variants;
  final VariantModel? selectedVariant;
  final ValueChanged<VariantModel> onSelect;

  const _VariantSelector({
    required this.variants,
    required this.selectedVariant,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Variant',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: variants.map((v) {
            final selected = selectedVariant?.id == v.id;
            final outOfStock = (v.stock ?? 1) <= 0;
            return GestureDetector(
              onTap: outOfStock ? null : () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.ink
                      : outOfStock
                      ? AppColors.surface
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: selected
                        ? AppColors.ink
                        : outOfStock
                        ? AppColors.border
                        : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  v.value ?? v.name ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : outOfStock
                        ? AppColors.inkLight
                        : AppColors.ink,
                    decoration: outOfStock ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Quantity Selector ──────────────────────────────
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        SizedBox(width: 16.w),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              _QtyBtn(
                icon: Icons.remove_rounded,
                onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _QtyBtn(
                icon: Icons.add_rounded,
                onTap: quantity < 99 ? () => onChanged(quantity + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.h,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18.sp,
          color: onTap != null ? AppColors.ink : AppColors.border,
        ),
      ),
    );
  }
}

// ── Badge ──────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: label == 'NEW' ? AppColors.green : AppColors.primary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Star Distribution ──────────────────────────────
class _StarDistribution extends StatelessWidget {
  final Map starDist;
  final int total;
  final double avg;

  const _StarDistribution({
    required this.distribution,
    required this.total,
    required this.avg,
  }) : starDist = distribution;

  final Map distribution;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big number
        Column(
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -2,
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < avg.floor()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.amber,
                  size: 12.sp,
                );
              }),
            ),
            Text(
              '$total reviews',
              style: TextStyle(fontSize: 10.sp, color: AppColors.inkLight),
            ),
          ],
        ),

        SizedBox(width: 16.w),

        // Bars
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = starDist[star] ?? 0;
              final pct = total > 0 ? count / total : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.inkLight,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.amber,
                      size: 10.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99.r),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(AppColors.amber),
                          minHeight: 5.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    SizedBox(
                      width: 20.w,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Review Card ────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16.r,
                backgroundColor: AppColors.primary,
                backgroundImage: review['user_avatar'] != null
                    ? NetworkImage(review['user_avatar'])
                    : null,
                child: review['user_avatar'] == null
                    ? Text(
                        (review['user_name'] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['user_name'] ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      review['date'] ?? '',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < (review['rating'] as num)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.amber,
                    size: 13.sp,
                  );
                }),
              ),
            ],
          ),

          if (review['comment'] != null &&
              (review['comment'] as String).isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              review['comment'],
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.inkLight,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Related Product Card ───────────────────────────
class _RelatedProductCard extends StatelessWidget {
  final ProductModel product;
  const _RelatedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushReplacement('/product/${product.slug}'),
      child: Container(
        width: 150.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
              child: CachedNetworkImage(
                imageUrl: product.image ?? '',
                height: 140.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surface),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '৳${product.displayPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Action Bar ──────────────────────────────
class _BottomActionBar extends StatelessWidget {
  final ProductModel product;
  final VariantModel? selectedVariant;
  final int quantity;
  final bool isLoading;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const _BottomActionBar({
    required this.product,
    required this.selectedVariant,
    required this.quantity,
    required this.isLoading,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wishlist button
          Consumer(
            builder: (context, ref, _) {
              final isWishlisted = ref
                  .watch(wishlistProvider)
                  .isWishlisted(product.id);
              return GestureDetector(
                onTap: () =>
                    ref.read(wishlistProvider.notifier).toggleWishlist(product),
                child: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isWishlisted
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    isWishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: isWishlisted
                        ? AppColors.primary
                        : AppColors.inkLight,
                    size: 20.sp,
                  ),
                ),
              );
            },
          ),

          SizedBox(width: 10.w),

          // Add to cart
          Expanded(
            child: GestureDetector(
              onTap: product.inStock ? onAddToCart : null,
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: product.inStock ? AppColors.ink : AppColors.border,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        product.inStock ? 'Add to Cart' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // Buy Now
          Expanded(
            child: GestureDetector(
              onTap: product.inStock ? onBuyNow : null,
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: product.inStock ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────
class _ProductDetailShimmer extends StatelessWidget {
  const _ProductDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(height: 340.h, color: AppColors.surface),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80.w, height: 12.h, color: AppColors.surface),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  height: 20.h,
                  color: AppColors.surface,
                ),
                SizedBox(height: 8.h),
                Container(width: 200.w, height: 20.h, color: AppColors.surface),
                SizedBox(height: 16.h),
                Container(width: 120.w, height: 28.h, color: AppColors.surface),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/product/models/product_model.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../../features/cart/providers/cart_provider.dart'; // 👈 Cart Provider ইমপোর্ট করলাম

// 👈 ConsumerStatefulWidget-এ রূপান্তর করা হলো (লোডিং স্টেট ধরে রাখার জন্য)
class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final double? width;

  const ProductCard({super.key, required this.product, this.width});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isLoading = false;

  // 🛒 Add to Cart ফাংশন
  Future<void> _handleAddToCart() async {
    if (!widget.product.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.product.hasVariants) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a variant (size/color) first'),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      context.push('/product/${widget.product.slug}');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(cartProvider.notifier)
          .addToCart(productId: widget.product.id, quantity: 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} added to cart!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isWishlisted = ref.watch(wishlistProvider).isWishlisted(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.slug}'),
      child: Container(
        width: widget.width ?? 170.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image & Badges Stack ────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.image ?? '',
                    width: double.infinity,
                    height: 140.h,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.border,
                      ),
                    ),
                  ),
                ),

                if (product.badge != null && product.badge!.isNotEmpty)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        product.badge!.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                //  Discount Percentage
                if (product.discountPrice != null && product.discountPrice! > 0)
                  Positioned(
                    top: (product.badge != null && product.badge!.isNotEmpty)
                        ? 32.h
                        : 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 10.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '-${(((product.price - product.discountPrice!) / product.price) * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Wishlist Heart Button ─────────────
                Positioned(
                  bottom: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(wishlistProvider.notifier)
                          .toggleWishlist(product);
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: isWishlisted
                            ? AppColors.primary
                            : AppColors.inkLight,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Product Info ────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ), // 👈 প্যাডিং একটু অ্যাডজাস্ট করেছি
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    if (product.category != null) ...[
                      Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h), // 👈 স্পেসিং কমিয়েছি
                    ],

                    // Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize:
                            12.sp, // 👈 ফন্ট সাইজ একটু কমিয়েছি (13 থেকে 12)
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4.h), // 👈 স্পেসিং কমিয়েছি
                    // ⭐ Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 13.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${product.avgRating}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkLight,
                          ),
                        ),
                        Text(
                          ' (${product.reviewsCount})',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(), // 👈 বাকি স্পেস ফিল করার জন্য
                    // 💰 Price & 🛒 Add to Cart Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.discountPrice != null)
                                Text(
                                  '৳${product.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10.sp, // 👈 একটু ছোট করেছি
                                    color: AppColors.inkLight,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                '৳${product.displayPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13.sp, // 👈 একটু ছোট করেছি
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // Right: Add to Cart Button (with Loading & inStock Logic) 🚀
                        GestureDetector(
                          onTap: _isLoading || !product.inStock
                              ? null
                              : _handleAddToCart,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 28.h,
                            width: 28.w, // 👈 স্কয়ার বাটন
                            decoration: BoxDecoration(
                              color: product.inStock
                                  ? AppColors.primary
                                  : AppColors
                                        .border, // স্টক না থাকলে ধূসর দেখাবে
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      width: 14.w,
                                      height: 14.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      product.inStock
                                          ? Icons.add_shopping_cart_rounded
                                          : Icons.remove_shopping_cart_rounded,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

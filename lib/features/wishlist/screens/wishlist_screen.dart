import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/product_card.dart';
import '../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Wishlist',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: _buildBody(wishlistState),
    );
  }

  Widget _buildBody(WishlistState state) {
    if (state.isLoading && state.items.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Text(
          'Something went wrong!\n${state.error}',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkLight, fontSize: 14.sp),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80.sp,
              color: AppColors.border,
            ),
            SizedBox(height: 16.h),
            Text(
              'Your wishlist is empty!',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Save items you love to buy them later.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.inkLight),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio:
            0.55, // ProductCard এর সাইজ অনুযায়ী এটি অ্যাডজাস্ট করতে হতে পারে
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final product = state.items[index];
        return ProductCard(product: product, width: double.infinity);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// আপনার প্রোভাইডারগুলো ঠিকঠাক ইমপোর্ট করে নিন:
import '../../features/cart/providers/cart_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart'; // 👈 উইশলিস্ট প্রোভাইডার ইমপোর্ট করলাম
import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location == '/shop') currentIndex = 1;
    if (location == '/cart') currentIndex = 2;
    if (location == '/wishlist') currentIndex = 3;
    if (location == '/profile') currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: SizedBox(
            height: 60.h,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  current: currentIndex,
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Shop',
                  index: 1,
                  current: currentIndex,
                  onTap: () => context.go('/shop'),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final count = ref.watch(cartCountProvider);
                    // Cart এর জন্য আপনার নিজের বানানো Custom Nav Item
                    return _CustomBadgeNavItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Cart',
                      index: 2,
                      current: currentIndex,
                      badgeCount: count,
                      onTap: () => context.go('/cart'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    // 👈 উইশলিস্টের জন্য কাউন্ট বের করলাম
                    final wishlistCount = ref
                        .watch(wishlistProvider)
                        .items
                        .length;
                    return _CustomBadgeNavItem(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Wishlist',
                      index: 3,
                      current: currentIndex,
                      badgeCount: wishlistCount, // 👈 কাউন্ট পাস করলাম
                      onTap: () => context.go('/wishlist'),
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 4,
                  current: currentIndex,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// সাধারণ NavItem (যেগুলোতে ব্যাজ দরকার নেই)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: active ? AppColors.primary : AppColors.inkLight,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.inkLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 👈 ব্যাজওয়ালা NavItem (আপনার Cart এর স্টাইলটি আমি একটি রিইউজেবল উইজেটে কনভার্ট করেছি)
class _CustomBadgeNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final int badgeCount;
  final VoidCallback onTap;

  const _CustomBadgeNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22.sp,
                  color: active ? AppColors.primary : AppColors.inkLight,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4, // ব্যাজটি আইকনের একটু বাইরে রাখার জন্য
                    top: -4,
                    child: Container(
                      width: 14.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.inkLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

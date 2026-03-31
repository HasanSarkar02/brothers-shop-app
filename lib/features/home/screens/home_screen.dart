import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/home_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/services/update_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ── InitState এ আপডেট চেক করা ──
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdate();
    });
  }

  // ──আপডেট চেক করার লজিক ──
  void _checkAppUpdate() {
    ref.read(updateServiceProvider).checkForUpdate((downloadUrl) {
      if (mounted) _showUpdateDialog(downloadUrl);
      _showUpdateDialog(downloadUrl);
    });
  }

  // ──আপডেট এভেইলেবল ডায়ালগ ──
  void _showUpdateDialog(String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text('New Update Available! 🚀'),
          content: const Text(
            'A new version of the app is available. Please update to get the latest features and bug fixes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startDownload(downloadUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text(
                'Update Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startDownload(String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DownloadProgressDialog(apkUrl: apkUrl);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: homeAsync.when(
        loading: () => const _HomeShimmer(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48.sp,
                color: AppColors.inkLight,
              ),
              SizedBox(height: 12.h),
              Text(
                'Failed to load',
                style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () => ref.refresh(homeDataProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        data: (home) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.refresh(homeDataProvider),
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────
              // ... আগের ইম্পোর্টগুলো ...

              // ── App Bar ──────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.white,
                elevation: 0,
                title: SvgPicture.network(
                  'https://brothersfe.com/logo.svg',
                  height: 32.h,
                  // SVG লোড হতে সমস্যা হলে এই placeholder দেখাবে
                  placeholderBuilder: (BuildContext context) => Text(
                    'BROTHERS',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    color: AppColors.ink,
                    onPressed: () {
                      context.push('/search');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppColors.ink,
                    onPressed: () {
                      // নোটিফিকেশন পেজের লজিক
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1.h),
                  child: Divider(height: 1.h, color: AppColors.border),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: 12.h),

                  // ── Banner Slider ─────────────────
                  if (home.sliders.isNotEmpty)
                    _BannerSlider(sliders: home.sliders),

                  SizedBox(height: 24.h),

                  // ── Categories ───────────────────
                  if (home.featuredCategories.isNotEmpty) ...[
                    SectionHeader(
                      label: 'Browse',
                      title: 'Shop by Category',
                      actionText: 'View All',
                      onAction: () => context.push('/shop'),
                    ),
                    SizedBox(height: 14.h),
                    _CategoryRow(categories: home.featuredCategories),
                    SizedBox(height: 24.h),
                  ],

                  // ── Flash Sale ───────────────────
                  if (home.flashSaleProducts.isNotEmpty) ...[
                    SectionHeader(
                      label: '⚡ Limited Time',
                      title: 'Flash Sale',
                      actionText: 'See All',
                      onAction: () => context.push('/offers'),
                    ),
                    SizedBox(height: 14.h),
                    _ProductRow(products: home.flashSaleProducts),
                    SizedBox(height: 24.h),
                  ],

                  // ── Promo Banners ────────────────
                  if (home.promoBanners.isNotEmpty) ...[
                    _PromoBanners(banners: home.promoBanners),
                    SizedBox(height: 24.h),
                  ],

                  // ── Trending ─────────────────────
                  if (home.trendingProducts.isNotEmpty) ...[
                    SectionHeader(
                      label: 'This Week',
                      title: 'Trending Products',
                      actionText: 'See All',
                      onAction: () => context.push('/shop'),
                    ),
                    SizedBox(height: 14.h),
                    _ProductRow(products: home.trendingProducts),
                    SizedBox(height: 24.h),
                  ],

                  // ── New Arrivals ──────────────────
                  if (home.newArrivals.isNotEmpty) ...[
                    SectionHeader(
                      label: 'Just Dropped',
                      title: 'New Arrivals',
                      actionText: 'View All',
                      onAction: () => context.push('/shop?sort=new'),
                    ),
                    SizedBox(height: 14.h),
                    _ProductRow(products: home.newArrivals),
                    SizedBox(height: 24.h),
                  ],

                  // ── Best Sellers ──────────────────
                  if (home.bestSellers.all.isNotEmpty) ...[
                    SectionHeader(label: 'Most Loved', title: 'Best Sellers'),
                    SizedBox(height: 14.h),
                    _BestSellerTabs(bestSellers: home.bestSellers),
                    SizedBox(height: 32.h),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Download Progress Dialog (New) ──────────────────
class _DownloadProgressDialog extends ConsumerStatefulWidget {
  final String apkUrl;
  const _DownloadProgressDialog({required this.apkUrl});

  @override
  ConsumerState<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState
    extends ConsumerState<_DownloadProgressDialog> {
  int _progress = 0;
  String _statusMessage = "Downloading update...";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    ref
        .read(updateServiceProvider)
        .downloadAndInstallUpdate(
          apkUrl: widget.apkUrl,
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
          onDownloadComplete: () {
            setState(() {
              _progress = 100;
              _statusMessage = "Download complete! Opening installer...";
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          },
          onError: (error) {
            setState(() {
              _isError = true;
              _statusMessage = "Download failed: $error";
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        _isError ? 'Error!' : 'Updating App',
        style: TextStyle(
          color: _isError ? Colors.red : AppColors.ink,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),

          if (!_isError) ...[
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 8.h,
              borderRadius: BorderRadius.circular(8.r),
            ),
            SizedBox(height: 12.h),

            Text(
              '$_progress%',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        if (_isError)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

// ── Banner Slider ──────────────────────────────────
class _BannerSlider extends StatefulWidget {
  final List sliders;
  const _BannerSlider({required this.sliders});

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180.h,
          child: Swiper(
            itemCount: widget.sliders.length,
            autoplay: true,
            autoplayDelay: 4000,
            viewportFraction: 0.92,
            scale: 0.95,
            onIndexChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final slider = widget.sliders[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: CachedNetworkImage(
                  imageUrl: slider.image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.surface,
                    highlightColor: AppColors.border,
                    child: Container(color: AppColors.surface),
                  ),
                ),
              );
            },
          ),
        ),

        // Dots
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.sliders.asMap().entries.map((e) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _current == e.key ? 20.w : 6.w,
              height: 6.h,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99.r),
                color: _current == e.key ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Category Row ───────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final List categories;
  const _CategoryRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) {
          final cat = categories[i];
          return GestureDetector(
            onTap: () => context.push('/shop?category=${cat.slug}'),
            child: Column(
              children: [
                Container(
                  width: 58.w,
                  height: 58.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: CachedNetworkImage(
                      imageUrl: cat.icon ?? cat.image ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.category_outlined,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                SizedBox(
                  width: 62.w,
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Product Row ────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final List products;
  const _ProductRow({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      ),
    );
  }
}

// ── Promo Banners ──────────────────────────────────
class _PromoBanners extends StatelessWidget {
  final List banners;
  const _PromoBanners({required this.banners});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: banners.map((b) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: CachedNetworkImage(
                imageUrl: b.image,
                width: double.infinity,
                height: 120.h,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Best Seller Tabs ───────────────────────────────
class _BestSellerTabs extends StatefulWidget {
  final dynamic bestSellers;
  const _BestSellerTabs({required this.bestSellers});

  @override
  State<_BestSellerTabs> createState() => _BestSellerTabsState();
}

class _BestSellerTabsState extends State<_BestSellerTabs> {
  int _tab = 0;
  final _tabs = ['All', 'Furniture', 'Electronics'];

  List get _currentProducts {
    switch (_tab) {
      case 1:
        return widget.bestSellers.furniture;
      case 2:
        return widget.bestSellers.electronics;
      default:
        return widget.bestSellers.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab pills
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: _tabs.asMap().entries.map((e) {
              final active = _tab == e.key;
              return GestureDetector(
                onTap: () => setState(() => _tab = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ink : AppColors.surface,
                    borderRadius: BorderRadius.circular(99.r),
                    border: Border.all(
                      color: active ? AppColors.ink : AppColors.border,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.inkLight,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 14.h),

        // Products
        SizedBox(
          height: 280.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _currentProducts.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, i) => ProductCard(product: _currentProducts[i]),
          ),
        ),
      ],
    );
  }
}

// ── Home Shimmer (Loading) ─────────────────────────
class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.border,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60.h),
            // Banner shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 180.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // Category shimmer
            SizedBox(
              height: 90.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 6,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, __) => Column(
                  children: [
                    Container(
                      width: 58.w,
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(width: 50.w, height: 10.h, color: Colors.white),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // Product shimmer
            SizedBox(
              height: 280.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 4,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, __) => Container(
                  width: 170.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

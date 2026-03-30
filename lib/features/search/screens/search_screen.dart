import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../../../core/constants/app_colors.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Container(
          height: 40.h,
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            autofocus: true, // স্ক্রিনে ঢোকার সাথেই কি-বোর্ড ওপেন হবে
            decoration: InputDecoration(
              hintText: 'Search for products...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20.sp),
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
            onChanged: (value) {
              ref.read(searchProvider.notifier).onSearchQueryChanged(value);
            },
            onSubmitted: (value) {
              // ইউজার এন্টার চাপলে ফুল রেজাল্ট পেজে পাঠাতে পারেন
              // context.push('/search/results?q=$value');
            },
          ),
        ),
      ),
      body: _buildBody(searchState, context),
    );
  }

  Widget _buildBody(SearchState state, BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (state.query.length > 1 && state.instantResults.isEmpty) {
      return Center(
        child: Text(
          'No products found for "${state.query}"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: state.instantResults.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final product = state.instantResults[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Image.network(
              product['image'],
              width: 50.w,
              height: 50.w,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            product['name'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '৳${product['price']}',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
          onTap: () {
            // প্রোডাক্ট ডিটেইলস পেজে নিয়ে যাওয়ার লজিক
            context.push('/product/${product['slug']}');
          },
        );
      },
    );
  }
}

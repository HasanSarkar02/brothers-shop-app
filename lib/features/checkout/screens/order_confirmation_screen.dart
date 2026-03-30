import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../services/checkout_service.dart';

// ── Provider for confirmation data ──
final orderConfirmationProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      orderNumber,
    ) async {
      final service = CheckoutService();
      return await service.getOrderConfirmation(orderNumber);
    });

class OrderConfirmationScreen extends ConsumerWidget {
  final String orderNumber;

  const OrderConfirmationScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmationAsync = ref.watch(orderConfirmationProvider(orderNumber));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: confirmationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64.sp,
                  color: Colors.redAccent,
                ),
                SizedBox(height: 16.h),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, color: AppColors.inkLight),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _buildConfirmation(context, data),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context, Map<String, dynamic> data) {
    final items = data['items'] as List? ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // ── Success Icon ─────────────────────
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              'Order Placed! 🎉',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Thank you for your order',
              style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
            ),
            SizedBox(height: 24.h),

            // ── Order Info Card ──────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _infoRow('Order Number', data['order_number'] ?? ''),
                  _divider(),
                  _infoRow(
                    'Status',
                    (data['status'] ?? '').toString().toUpperCase(),
                  ),
                  _divider(),
                  _infoRow(
                    'Payment',
                    data['payment_method'] == 'cod'
                        ? 'Cash on Delivery'
                        : data['payment_method'] ?? '',
                  ),
                  _divider(),
                  _infoRow(
                    'Payment Status',
                    (data['payment_status'] ?? '').toString().toUpperCase(),
                  ),
                  _divider(),
                  _infoRow('Placed At', data['placed_at'] ?? ''),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Shipping Info Card ──────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipping Details',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _shippingRow(
                    Icons.person_outline,
                    data['shipping_name'] ?? '',
                  ),
                  SizedBox(height: 8.h),
                  _shippingRow(
                    Icons.phone_outlined,
                    data['shipping_phone'] ?? '',
                  ),
                  SizedBox(height: 8.h),
                  _shippingRow(
                    Icons.location_on_outlined,
                    data['shipping_address'] ?? '',
                  ),
                  if (data['notes'] != null &&
                      data['notes'].toString().isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _shippingRow(Icons.note_alt_outlined, data['notes']),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Order Items Card ────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items (${items.length})',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (item['variant_info'] != null)
                                  Text(
                                    item['variant_info'],
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.inkLight,
                                    ),
                                  ),
                                Text(
                                  '৳${_toPrice(item['unit_amount'])} × ${_toInt(item['quantity'])}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.inkLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '৳${_toPrice(item['total_amount'])}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(color: AppColors.border),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '৳${_toPrice(data['grand_total'])}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // ── Action Buttons ──────────────────
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: OutlinedButton(
                onPressed: () => context.go('/orders'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'View My Orders',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: AppColors.inkLight),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: AppColors.border, height: 1);

  Widget _shippingRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.inkLight),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: AppColors.ink),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // 🔧 SAFE TYPE CONVERSION HELPERS
  // Handles "11500.00" (String), 11500 (int), 11500.0 (double)
  // ═══════════════════════════════════════════════

  String _toPrice(dynamic value) {
    return _toDouble(value).toStringAsFixed(0);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _isLoggedIn = false;
  bool _isChecking = true;

  // Guest tracking controllers
  final _orderNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await LocalStorage.getToken();
    setState(() {
      _isLoggedIn = token != null;
      _isChecking = false;
    });

    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(orderListProvider.notifier).fetchOrders();
      });
    }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _isLoggedIn ? _buildAuthOrders() : _buildGuestTrack(),
    );
  }

  // ═══════════════════════════════════════
  // AUTH USER — Order List
  // ═══════════════════════════════════════
  Widget _buildAuthOrders() {
    final orderState = ref.watch(orderListProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(orderListProvider.notifier).refresh(),
      child: orderState.isLoading && orderState.orders.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : orderState.error != null && orderState.orders.isEmpty
          ? _buildErrorState(
              orderState.error!,
              () => ref.read(orderListProvider.notifier).fetchOrders(),
            )
          : orderState.orders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: orderState.orders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(orderState.orders[index]);
              },
            ),
    );
  }

  // ═══════════════════════════════════════
  // GUEST USER — Track Order
  // ═══════════════════════════════════════
  Widget _buildGuestTrack() {
    final guestState = ref.watch(guestOrderProvider);

    if (guestState.trackedOrder != null) {
      return _buildGuestOrderView([guestState.trackedOrder!]);
    }

    if (guestState.orders.isNotEmpty) {
      return _buildGuestOrderView(guestState.orders);
    }

    if (guestState.isOtpSent) {
      return _buildOtpInput(guestState);
    }

    return _buildGuestSearchForm(guestState);
  }

  Widget _buildGuestSearchForm(GuestOrderState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 48.sp,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Track Your Order',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Enter your order number and phone number',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Error
          if (state.error != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      state.error!.replaceAll('Exception: ', ''),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Order Number Field
          Text(
            'Order Number',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _orderNumberController,
            style: TextStyle(fontSize: 14.sp, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'e.g. BFE-2025-0001',
              hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
              prefixIcon: Icon(
                Icons.receipt_long_outlined,
                size: 20.sp,
                color: AppColors.inkLight,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Phone Number Field
          Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 14.sp, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'e.g. 01711111111',
              hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
              prefixIcon: Icon(
                Icons.phone_outlined,
                size: 20.sp,
                color: AppColors.inkLight,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: state.isSearching ? null : _handleGuestSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: state.isSearching
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Track Order',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 16.h),

          // Login CTA
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.login_rounded,
                  size: 24.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login for faster tracking',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'See all your orders in one place',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput(GuestOrderState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),

          Icon(
            Icons.lock_outline_rounded,
            size: 64.sp,
            color: AppColors.primary,
          ),
          SizedBox(height: 20.h),

          Text(
            'Verify Your Order',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'We sent an OTP to ${_phoneController.text}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
          ),
          SizedBox(height: 32.h),

          // OTP Field
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 16,
              color: AppColors.ink,
            ),
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(fontSize: 24.sp, color: AppColors.border),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              counterText: '',
            ),
          ),
          SizedBox(height: 24.h),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: state.isVerifyingOtp ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: state.isVerifyingOtp
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16.h),

          // Resend & Back buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: state.isSearching
                    ? null
                    : () => ref
                          .read(guestOrderProvider.notifier)
                          .sendOtp(
                            _orderNumberController.text.trim(),
                            _phoneController.text.trim(),
                          ),
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              TextButton(
                onPressed: () => ref.read(guestOrderProvider.notifier).reset(),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════

  Widget _buildGuestOrderView(List<OrderModel> orders) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          // ✅ সব orders দেখাও
          ...orders.map(
            (order) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildOrderDetails(order),
            ),
          ),

          SizedBox(height: 8.h),

          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(guestOrderProvider.notifier).reset(),
              icon: Icon(Icons.search_rounded, size: 18.sp),
              label: Text(
                'Track Another Order',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () => _showOrderDetails(context, order),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            SizedBox(height: 12.h),

            // Info Row
            Row(
              children: [
                // Items count
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 14.sp,
                        color: AppColors.inkLight,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.inkLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Payment method
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    order.paymentMethod == 'cod' ? 'COD' : order.paymentMethod,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.inkLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),

                // Price
                Text(
                  '৳${order.grandTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Date
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14.sp,
                  color: AppColors.inkLight,
                ),
                SizedBox(width: 4.w),
                Text(
                  order.placedAt,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.inkLight),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: AppColors.inkLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.amber;
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'processing':
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'shipped':
      case 'out_for_delivery':
        color = Colors.deepPurple;
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        color = AppColors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        color = Colors.redAccent;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.inkLight;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Column(
      children: [
        // Status Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getStatusGradient(order.status),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Icon(
                _getStatusIcon(order.status),
                size: 48.sp,
                color: Colors.white,
              ),
              SizedBox(height: 12.h),
              Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                order.orderNumber,
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Info Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _infoRow('Order Number', order.orderNumber),
              _divider(),
              _infoRow(
                'Payment',
                order.paymentMethod == 'cod'
                    ? 'Cash on Delivery'
                    : order.paymentMethod,
              ),
              _divider(),
              _infoRow('Placed At', order.placedAt),
              _divider(),
              _infoRow('Ship To', order.shippingName),
              _divider(),
              _infoRow('Phone', order.shippingPhone),
              _divider(),
              _infoRow('Address', order.shippingAddress),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Items
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items (${order.items.length})',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 12.h),
              ...order.items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            if (item.variantInfo != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                item.variantInfo!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.inkLight,
                                ),
                              ),
                            ],
                            SizedBox(height: 2.h),
                            Text(
                              '৳${item.unitAmount.toStringAsFixed(0)} × ${item.quantity}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.inkLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '৳${item.totalAmount.toStringAsFixed(0)}',
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
                    '৳${order.grandTotal.toStringAsFixed(0)}',
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
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: AppColors.inkLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: AppColors.border, height: 1);

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.sp,
              color: AppColors.border,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Start shopping to see your orders here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.go('/shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
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
              error.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════

  void _handleGuestSearch() {
    final orderNumber = _orderNumberController.text.trim();
    final phone = _phoneController.text.trim();

    if (orderNumber.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter order number and phone'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ref.read(guestOrderProvider.notifier).trackOrder(orderNumber, phone);
  }

  void _handleVerifyOtp() {
    final otp = _otpController.text.trim();
    final orderNumber = _orderNumberController.text.trim();
    final phone = _phoneController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the OTP'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    ref.read(guestOrderProvider.notifier).verifyOtp(orderNumber, phone, otp);
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              _buildOrderDetails(order),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return [Colors.amber, Colors.orange];
      case 'processing':
      case 'confirmed':
        return [Colors.blue, Colors.blueAccent];
      case 'shipped':
      case 'out_for_delivery':
        return [Colors.deepPurple, Colors.purple];
      case 'delivered':
        return [Colors.green, Colors.teal];
      case 'cancelled':
        return [Colors.redAccent, Colors.red];
      default:
        return [AppColors.inkLight, Colors.grey];
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'processing':
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'shipped':
      case 'out_for_delivery':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

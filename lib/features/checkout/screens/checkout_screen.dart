import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage.dart';
import '../providers/checkout_provider.dart';
import '../models/checkout_model.dart';
import '../../cart/providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _divisionController = TextEditingController();
  final _districtController = TextEditingController();
  final _thanaController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _createAccount = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndPrefill();
  }

  Future<void> _checkLoginAndPrefill() async {
    final token = await LocalStorage.getToken();
    _isLoggedIn = token != null;

    if (_isLoggedIn) {
      final user = await LocalStorage.getUser();
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    }

    // Also prefill from checkout summary user data
    final summary = ref.read(checkoutProvider).summary;
    if (summary?.user != null) {
      _nameController.text = summary!.user!.name;
      _emailController.text = summary.user!.email;
      _phoneController.text = summary.user!.phone;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _divisionController.dispose();
    _districtController.dispose();
    _thanaController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // ⚠️ Scenario 8: Email required if creating account
    if (!_isLoggedIn &&
        _createAccount &&
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email is required to create an account'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    final Map<String, dynamic> orderData = {
      'shipping_name': _nameController.text.trim(),
      'shipping_phone': _phoneController.text.trim(),
      'shipping_email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'division': _divisionController.text.trim(),
      'district': _districtController.text.trim(),
      'thana': _thanaController.text.trim(),
      'full_address': _addressController.text.trim(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'payment_method': 'cod',
    };

    // Guest account creation
    if (!_isLoggedIn && _createAccount) {
      orderData['create_account'] = true;
      orderData['password'] = _passwordController.text;
      orderData['password_confirmation'] = _confirmPasswordController.text;
    }

    try {
      final response = await ref
          .read(checkoutProvider.notifier)
          .placeOrder(orderData);

      if (response != null && mounted) {
        // ── Scenario 9: Save user data after account creation ──
        if (response.newAccount && response.token != null) {
          await LocalStorage.saveToken(response.token!);
          await LocalStorage.saveUser({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'avatar': '',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created successfully! 🎉'),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }

        // ── Scenario 10: Refresh cart badge (count becomes 0) ──
        ref.invalidate(cartProvider);

        // Navigate to confirmation
        context.go('/order-confirmation/${response.orderNumber}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Checkout',
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
      body: checkoutState.isLoadingSummary
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : checkoutState.error != null && checkoutState.summary == null
          ? _buildError(checkoutState.error!)
          : checkoutState.summary == null
          ? _buildError('Unable to load checkout data')
          : _buildCheckoutForm(checkoutState),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64.sp,
              color: AppColors.border,
            ),
            SizedBox(height: 16.h),
            Text(
              error.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.inkLight,
                fontWeight: FontWeight.w600,
              ),
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
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutForm(CheckoutState checkoutState) {
    final summary = checkoutState.summary!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Order Summary ──────────────────
                  _buildSectionTitle('Order Summary'),
                  SizedBox(height: 8.h),
                  _buildOrderItems(summary.items),
                  SizedBox(height: 20.h),

                  // ── Shipping Information ───────────
                  _buildSectionTitle('Shipping Information'),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Phone is required'
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email (Optional)',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _divisionController,
                    label: 'Division',
                    icon: Icons.location_city_rounded,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Division is required'
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _districtController,
                          label: 'District',
                          icon: Icons.map_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _thanaController,
                          label: 'Thana/Upazila',
                          icon: Icons.pin_drop_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Full Address',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Address is required'
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _notesController,
                    label: 'Order Notes (Optional)',
                    icon: Icons.note_alt_outlined,
                    maxLines: 2,
                  ),
                  SizedBox(height: 20.h),

                  // ── Payment Method ─────────────────
                  _buildSectionTitle('Payment Method'),
                  SizedBox(height: 8.h),
                  _buildPaymentMethod(),
                  SizedBox(height: 20.h),

                  // ── Guest Account Creation ─────────
                  if (!_isLoggedIn) ...[
                    _buildSectionTitle('Create Account (Optional)'),
                    SizedBox(height: 8.h),
                    _buildCreateAccountSection(),
                    SizedBox(height: 20.h),
                  ],

                  // ── Price Breakdown ────────────────
                  _buildPriceBreakdown(summary),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),

          // ── Bottom: Place Order Button ───────
          _buildPlaceOrderButton(checkoutState),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SUB-WIDGETS
  // ═══════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildOrderItems(List<CheckoutItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: item.image ?? '',
                    width: 56.w,
                    height: 56.h,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.variant != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          item.variant!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                      SizedBox(height: 4.h),
                      Text(
                        '৳${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Item total
                Text(
                  '৳${item.itemTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(fontSize: 14.sp, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13.sp, color: AppColors.inkLight),
        prefixIcon: Icon(icon, size: 20.sp, color: AppColors.inkLight),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Pay when you receive your order',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.inkLight),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create an account',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Track orders & faster checkout next time',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _createAccount,
                onChanged: (v) => setState(() => _createAccount = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_createAccount) ...[
            SizedBox(height: 12.h),
            // 👇 Email reminder
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16.sp,
                    color: AppColors.amber,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Make sure you entered your email above to create an account',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: _createAccount
                  ? (v) => v == null || v.length < 6
                        ? 'Minimum 6 characters'
                        : null
                  : null,
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: _createAccount
                  ? (v) => v != _passwordController.text
                        ? 'Passwords do not match'
                        : null
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(CheckoutSummaryModel summary) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', '৳${summary.subtotal.toStringAsFixed(0)}'),
          SizedBox(height: 8.h),
          _priceRow(
            'Shipping',
            summary.shippingCost > 0
                ? '৳${summary.shippingCost.toStringAsFixed(0)}'
                : 'Free',
            valueColor: AppColors.green,
          ),
          SizedBox(height: 8.h),
          Divider(color: AppColors.border),
          SizedBox(height: 8.h),
          _priceRow(
            'Total',
            '৳${summary.grandTotal.toStringAsFixed(0)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15.sp : 13.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton(CheckoutState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: state.isPlacingOrder ? null : _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              elevation: 0,
            ),
            child: state.isPlacingOrder
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Place Order • ৳${state.summary?.grandTotal.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

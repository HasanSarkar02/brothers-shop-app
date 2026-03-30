import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/social_login_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Please enter email/phone and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .login(identifier: identifier, password: password);

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 13.sp)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32.h),

              // ── Back button ───────────────────────
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : context.go('/'),
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20.sp,
                    color: AppColors.ink,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // ── Header ────────────────────────────
              Text(
                'Welcome Back 👋',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Sign in to your Brothers account',
                style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
              ),

              SizedBox(height: 36.h),

              // ── Email / Phone field ───────────────
              const FieldLabel(label: 'Email or Phone'),
              SizedBox(height: 8.h),
              InputField(
                controller: _identifierController,
                hint: 'Enter email or phone number',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 18.h),

              // ── Password field ────────────────────
              const FieldLabel(label: 'Password'),
              SizedBox(height: 8.h),
              InputField(
                controller: _passwordController,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      _obscurePassword
                          ? Icons
                                .visibility_outlined // ✅ Fixed icon name
                          : Icons.visibility_off_outlined, // ✅ Fixed icon name
                      size: 20.sp,
                      color: AppColors.inkLight,
                    ),
                  ),
                ),
                onSubmit: (_) => _login(),
              ),

              SizedBox(height: 10.h),

              // ── Forgot password ───────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to forgot password
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              // ── Login Button ──────────────────────
              PrimaryButton(
                label: 'Sign In',
                isLoading: _isLoading,
                onTap: _login,
              ),

              SizedBox(height: 24.h),

              // ── Divider ───────────────────────────
              const OrDivider(),

              SizedBox(height: 24.h),

              // ── Social Login ──────────────────────
              SocialLoginButtons(
                onSuccess: () {
                  if (mounted) context.go('/');
                },
                onError: _showError,
              ),

              SizedBox(height: 32.h),

              // ── Register Link ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.inkLight,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      'Create one',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/social_login_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Email অথবা Phone — একটা দিলেই হবে
  bool _useEmail = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    // ── Email Validation ─────────────────────────
    if (_useEmail) {
      if (email.isEmpty) {
        _showError('Please enter your email');
        return;
      }

      // Standard Email Regex Pattern
      final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      );
      if (!emailRegex.hasMatch(email)) {
        _showError('Please enter a valid email address');
        return;
      }
    }

    // ── Phone Validation (Bangladeshi) ───────────
    if (!_useEmail) {
      if (phone.isEmpty) {
        _showError('Please enter your phone number');
        return;
      }

      // Bangladeshi Phone Regex Pattern (+8801..., 8801..., or 01...)
      final phoneRegex = RegExp(r"^(?:\+88|88)?(01[3-9]\d{8})$");
      if (!phoneRegex.hasMatch(phone)) {
        _showError('Please enter a valid Bangladeshi phone number');
        return;
      }
    }

    // ── Password Validation ──────────────────────
    if (password.isEmpty || password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            name: name,
            email: _useEmail ? email : null,
            phone: _useEmail ? null : phone,
            password: password,
            passwordConfirmation: confirm,
          );

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
                'Create Account ✨',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Join Brothers — Bangladesh\'s best furniture store',
                style: TextStyle(fontSize: 13.sp, color: AppColors.inkLight),
              ),

              SizedBox(height: 32.h),

              // ── Name ──────────────────────────────
              const FieldLabel(label: 'Full Name'),
              SizedBox(height: 8.h),
              InputField(
                controller: _nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),

              SizedBox(height: 18.h),

              // ── Email / Phone toggle ───────────────
              Row(
                children: [
                  _ToggleChip(
                    label: 'Email',
                    selected: _useEmail,
                    onTap: () => setState(() => _useEmail = true),
                  ),
                  SizedBox(width: 8.w),
                  _ToggleChip(
                    label: 'Phone',
                    selected: !_useEmail,
                    onTap: () => setState(() => _useEmail = false),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // ── Email or Phone ────────────────────
              if (_useEmail)
                InputField(
                  controller: _emailController,
                  hint: 'Enter your email address',
                  icon: Icons.email_outlined, // ✅ Fixed icon name
                  keyboardType: TextInputType.emailAddress,
                )
              else
                InputField(
                  controller: _phoneController,
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

              SizedBox(height: 18.h),

              // ── Password ──────────────────────────
              const FieldLabel(label: 'Password'),
              SizedBox(height: 8.h),
              InputField(
                controller: _passwordController,
                hint: 'Min. 8 characters',
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
                                .visibility_outlined // ✅ Fixed
                          : Icons.visibility_off_outlined, // ✅ Fixed
                      size: 20.sp,
                      color: AppColors.inkLight,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18.h),

              // ── Confirm Password ──────────────────
              const FieldLabel(label: 'Confirm Password'),
              SizedBox(height: 8.h),
              InputField(
                controller: _confirmController,
                hint: 'Re-enter your password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      _obscureConfirm
                          ? Icons
                                .visibility_outlined // ✅ Fixed
                          : Icons.visibility_off_outlined, // ✅ Fixed
                      size: 20.sp,
                      color: AppColors.inkLight,
                    ),
                  ),
                ),
                onSubmit: (_) => _register(),
              ),

              SizedBox(height: 28.h),

              // ── Register Button ───────────────────
              PrimaryButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onTap: _register,
              ),

              SizedBox(height: 24.h),

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

              // ── Login Link ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.inkLight,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/login'),
                    child: Text(
                      'Sign In',
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

// ── Toggle Chip ────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.inkLight,
          ),
        ),
      ),
    );
  }
}

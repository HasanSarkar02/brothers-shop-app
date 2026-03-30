import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

// ── Google Sign In instance ────────────────────────
final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

class SocialLoginButtons extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const SocialLoginButtons({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  ConsumerState<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends ConsumerState<SocialLoginButtons> {
  bool _googleLoading = false;
  bool _facebookLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _googleLoading = true);

    try {
      // ১. Google sign in popup
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _googleLoading = false);
        return;
      }

      // ২. Access token নাও
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to get Google access token');
      }

      // ৩. Laravel API তে পাঠাও
      await ref
          .read(authProvider.notifier)
          .socialLogin(provider: 'google', accessToken: accessToken);

      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) {
        widget.onError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleFacebookLogin() async {
    widget.onError('Facebook login coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          isLoading: _googleLoading,
          icon: _googleLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  Icons.g_mobiledata_rounded,
                  size: 28.sp,
                  color: Colors.red,
                ),
          onTap: _googleLoading ? null : _handleGoogleLogin,
        ),

        SizedBox(height: 12.h),

        _SocialButton(
          label: 'Continue with Facebook',
          isLoading: _facebookLoading,
          icon: Icon(
            Icons.facebook_rounded,
            size: 22.sp,
            color: const Color(0xFF1877F2),
          ),
          onTap: _facebookLoading ? null : _handleFacebookLogin,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24.w,
              child: Center(child: icon),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: onTap == null ? AppColors.inkLight : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

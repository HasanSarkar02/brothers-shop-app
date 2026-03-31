import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/local_storage.dart';
import '../providers/profile_provider.dart';
import 'package:flutter_html/flutter_html.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggedIn = false;
  bool _isChecking = true;
  String _appVersion = "1.0.0";
  Map<String, dynamic> _localUser = {};

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkAuth();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version; // "1.0.1"
    });
  }

  Future<void> _checkAuth() async {
    final token = await LocalStorage.getToken();
    final user = await LocalStorage.getUser();

    setState(() {
      _isLoggedIn = token != null;
      _localUser = user;
      _isChecking = false;
    });

    if (_isLoggedIn) {
      ref.read(profileProvider.notifier).fetchProfile();
    }
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

    final profileState = ref.watch(profileProvider);
    final user = profileState.user.isNotEmpty ? profileState.user : _localUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ─────────────────────────
            _isLoggedIn
                ? _buildAuthHeader(user, profileState.isLoading, context)
                : _buildGuestHeader(),

            SizedBox(height: 8.h),

            // ── Quick Actions (Auth only) ──────
            if (_isLoggedIn) _buildQuickActions(),

            SizedBox(height: 8.h),

            // ── Menu Items ─────────────────────
            if (_isLoggedIn) ...[
              _buildSectionTitle('My Orders'),
              _buildMenuCard([
                _menuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'All Orders',
                  subtitle: 'View order history',
                  onTap: () => context.push('/orders'),
                ),
                _menuItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Track Order',
                  subtitle: 'Track your delivery',
                  onTap: () => context.push('/orders'),
                ),
              ]),
              SizedBox(height: 8.h),
              _buildSectionTitle('Account'),
              _buildMenuCard([
                _menuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your information',
                  onTap: () => _showEditProfile(context, user),
                ),
                _menuItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _showChangePassword(context),
                ),
                _menuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Manage delivery addresses',
                  onTap: () => _showComingSoon('Saved Addresses'),
                ),
                _menuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => _showComingSoon('Notifications'),
                ),
              ]),
            ] else ...[
              _buildSectionTitle('Get Started'),
              _buildMenuCard([
                _menuItem(
                  icon: Icons.login_rounded,
                  title: 'Sign In',
                  subtitle: 'Access your account',
                  onTap: () => context.push('/login'),
                ),
                _menuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Create Account',
                  subtitle: 'Join us today',
                  onTap: () => context.push('/register'),
                ),
                _menuItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Track My Order',
                  subtitle: 'Check order status',
                  onTap: () => context.push('/orders'),
                ),
              ]),
            ],

            SizedBox(height: 8.h),

            // ── Support ────────────────────────
            _buildSectionTitle('Support'),
            _buildMenuCard([
              _menuItem(
                icon: Icons.headset_mic_outlined,
                title: 'Contact Us',
                subtitle: 'Get in touch with us',
                onTap: () => _showContactUs(context),
              ),
              _menuItem(
                icon: Icons.help_outline_rounded,
                title: 'FAQ',
                subtitle: 'Frequently asked questions',
                onTap: () => _showPage(context, 'faq', 'FAQ'),
              ),
            ]),

            SizedBox(height: 8.h),

            // ── About ──────────────────────────
            _buildSectionTitle('About'),
            _buildMenuCard([
              _menuItem(
                icon: Icons.info_outline_rounded,
                title: 'About Us',
                subtitle: 'Learn about Brothers FE',
                onTap: () => _showPage(context, 'about_us', 'About Us'),
              ),
              _menuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () =>
                    _showPage(context, 'privacy_policy', 'Privacy Policy'),
              ),
              _menuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Our terms of service',
                onTap: () => _showPage(
                  context,
                  'terms_conditions',
                  'Terms & Conditions',
                ),
              ),
            ]),

            SizedBox(height: 8.h),

            // ── Logout ─────────────────────────
            if (_isLoggedIn)
              _buildMenuCard([
                _menuItem(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Log out of your account',
                  onTap: () => _showLogoutDialog(context),
                  titleColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                ),
              ]),

            SizedBox(height: 8.h),

            // ── App Version ────────────────────
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                children: [
                  Text(
                    'Developed by Hasan Sarkar',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkLight,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Version $_appVersion',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // AUTH HEADER
  // ═══════════════════════════════════════

  Widget _buildAuthHeader(
    Map<String, dynamic> user,
    bool isLoading,
    BuildContext context,
  ) {
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';
    final avatar = user['avatar'] ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatar.startsWith('http')
                              ? avatar
                              : '${ApiConstants.storageUrl}/$avatar',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarPlaceholder(name),
                          errorWidget: (_, __, ___) => _avatarPlaceholder(name),
                        )
                      : _avatarPlaceholder(name),
                ),
              ),

              GestureDetector(
                onTap: () async {
                  try {
                    await ref
                        .read(profileProvider.notifier)
                        .pickAndUploadAvatar();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Avatar updated successfully!'),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload failed: $e')),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 18.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          isLoading
              ? SizedBox(
                  width: 120.w,
                  height: 20.h,
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(Colors.white54),
                  ),
                )
              : Text(
                  name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
          SizedBox(height: 4.h),
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(fontSize: 13.sp, color: Colors.white70),
            ),
          if (phone.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              phone,
              style: TextStyle(fontSize: 12.sp, color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // GUEST HEADER
  // ═══════════════════════════════════════

  Widget _buildGuestHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 32.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40.sp,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Welcome to Brothers FE',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Sign in to unlock all features',
            style: TextStyle(fontSize: 13.sp, color: Colors.white70),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 44.h,
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
  // QUICK ACTIONS
  // ═══════════════════════════════════════

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _quickAction(
              icon: Icons.shopping_bag_outlined,
              label: 'Orders',
              onTap: () => context.push('/orders'),
            ),
            _quickActionDivider(),
            _quickAction(
              icon: Icons.favorite_outline_rounded,
              label: 'Wishlist',
              onTap: () => context.go('/wishlist'),
            ),
            _quickActionDivider(),
            _quickAction(
              icon: Icons.local_shipping_outlined,
              label: 'Track',
              onTap: () => context.push('/orders'),
            ),
            _quickActionDivider(),
            _quickAction(
              icon: Icons.headset_mic_outlined,
              label: 'Support',
              onTap: () => _showContactUs(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 22.sp, color: AppColors.primary),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.inkLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionDivider() {
    return Container(width: 1, height: 36.h, color: AppColors.border);
  }

  // ═══════════════════════════════════════
  // MENU BUILDERS
  // ═══════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.inkLight,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: List.generate(children.length, (index) {
            return Column(
              children: [
                children[index],
                if (index < children.length - 1)
                  Divider(color: AppColors.border, height: 1, indent: 56.w),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20.sp,
                    color: AppColors.border,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHOW METHODS — delegate to StatefulWidget sheets
  // ═══════════════════════════════════════

  void _showEditProfile(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => const _ContactUsSheet(),
    );
  }

  void _showPage(BuildContext context, String slug, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _PageSheet(slug: slug, title: title),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        icon: Icon(Icons.logout_rounded, size: 48.sp, color: Colors.redAccent),
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(fontSize: 14.sp, color: AppColors.inkLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.inkLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileProvider.notifier).logout();
              await LocalStorage.deleteToken();
              await LocalStorage.clearUser();
              if (mounted) {
                setState(() => _isLoggedIn = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Signed out successfully'),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Coming Soon!'),
        backgroundColor: AppColors.amber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EDIT PROFILE BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _EditProfileSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(profileProvider.notifier).updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            SizedBox(height: 16.h),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 20.h),
            _sheetTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            SizedBox(height: 12.h),
            _sheetTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12.h),
            _sheetTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            SizedBox(height: 20.h),
            _sheetButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CHANGE PASSWORD BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(profileServiceProvider);
      final msg = await service.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            SizedBox(height: 16.h),
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 20.h),
            _sheetTextField(
              controller: _currentController,
              label: 'Current Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 12.h),
            _sheetTextField(
              controller: _newController,
              label: 'New Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) =>
                  v == null || v.length < 6 ? 'Minimum 6 characters' : null,
            ),
            SizedBox(height: 12.h),
            _sheetTextField(
              controller: _confirmController,
              label: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) =>
                  v != _newController.text ? 'Passwords do not match' : null,
            ),
            SizedBox(height: 20.h),
            _sheetButton(
              label: 'Change Password',
              isLoading: _isLoading,
              onTap: _changePassword,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CONTACT US BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _ContactUsSheet extends ConsumerStatefulWidget {
  const _ContactUsSheet();

  @override
  ConsumerState<_ContactUsSheet> createState() => _ContactUsSheetState();
}

class _ContactUsSheetState extends ConsumerState<_ContactUsSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(profileServiceProvider);
      final msg = await service.sendContact(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              SizedBox(height: 16.h),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "We'd love to hear from you",
                style: TextStyle(fontSize: 13.sp, color: AppColors.inkLight),
              ),
              SizedBox(height: 20.h),
              _sheetTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              _sheetTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              _sheetTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12.h),
              _sheetTextField(
                controller: _messageController,
                label: 'Your Message',
                icon: Icons.message_outlined,
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 20.h),
              _sheetButton(
                label: 'Send Message',
                isLoading: _isLoading,
                onTap: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE VIEWER BOTTOM SHEET (About, Privacy, Terms)
// ══════════════════════════════════════════════════════════════
class _PageSheet extends ConsumerWidget {
  final String slug;
  final String title;

  const _PageSheet({required this.slug, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(pageProvider(slug));

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _dragHandle(),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: pageAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48.sp,
                        color: Colors.redAccent,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ),
                ),
                data: (content) => SingleChildScrollView(
                  controller: scrollController,
                  child: Html(
                    data: content,
                    style: {
                      "html": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14.sp),
                        color: AppColors.ink,
                        lineHeight: const LineHeight(1.6),
                        fontFamily: 'Outfit',
                      ),
                      "p": Style(margin: Margins.only(bottom: 12)),
                      "h1": Style(
                        fontSize: FontSize(24.sp),
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        margin: Margins.only(bottom: 12),
                      ),
                      "h2": Style(
                        fontSize: FontSize(20.sp),
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        margin: Margins.only(bottom: 10),
                      ),
                      "h3": Style(
                        fontSize: FontSize(18.sp),
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        margin: Margins.only(bottom: 8),
                      ),
                      "ul": Style(
                        margin: Margins.only(bottom: 12),
                        padding: HtmlPaddings.only(left: 18),
                      ),
                      "ol": Style(
                        margin: Margins.only(bottom: 12),
                        padding: HtmlPaddings.only(left: 18),
                      ),
                      "li": Style(margin: Margins.only(bottom: 6)),
                      "strong": Style(fontWeight: FontWeight.w700),
                      "b": Style(fontWeight: FontWeight.w700),
                      "a": Style(
                        color: AppColors.primary,
                        textDecoration: TextDecoration.underline,
                      ),
                      "img": Style(
                        width: Width(double.infinity),
                        margin: Margins.only(top: 8, bottom: 8),
                      ),
                      "table": Style(backgroundColor: AppColors.white),
                      "td": Style(
                        padding: HtmlPaddings.all(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      "th": Style(
                        padding: HtmlPaddings.all(8),
                        backgroundColor: AppColors.surface,
                        fontWeight: FontWeight.w700,
                        border: Border.all(color: AppColors.border),
                      ),
                    },
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

// ══════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS (used by all bottom sheets)
// ══════════════════════════════════════════════════════════════

Widget _dragHandle() {
  return Container(
    width: 40.w,
    height: 4.h,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(2.r),
    ),
  );
}

Widget _sheetTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  int maxLines = 1,
  bool enabled = true,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    maxLines: maxLines,
    enabled: enabled,
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
      disabledBorder: OutlineInputBorder(
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

Widget _sheetButton({
  required String label,
  required bool isLoading,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50.h,
    child: ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              label,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
    ),
  );
}

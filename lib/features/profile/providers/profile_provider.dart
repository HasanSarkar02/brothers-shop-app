import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import 'package:image_picker/image_picker.dart';

// ═══════════════════════════════════════
// Service Provider
// ═══════════════════════════════════════
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// ═══════════════════════════════════════
// Auth State — isLoggedIn
// ═══════════════════════════════════════
final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<bool> {
  AuthStateNotifier() : super(false);

  void setLoggedIn(bool value) => state = value;
}

// ═══════════════════════════════════════
// Profile State
// ═══════════════════════════════════════
class ProfileState {
  final bool isLoading;
  final Map<String, dynamic> user;
  final String? error;

  ProfileState({this.isLoading = false, this.user = const {}, this.error});

  ProfileState copyWith({
    bool? isLoading,
    Map<String, dynamic>? user,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _service;
  final Ref _ref;

  ProfileNotifier(this._service, this._ref) : super(ProfileState());

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _service.getProfile();
      state = state.copyWith(isLoading: false, user: data);
      _ref.read(authStateProvider.notifier).setLoggedIn(true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _service.updateProfile(data);
      state = state.copyWith(isLoading: false, user: updatedUser);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        state = state.copyWith(isLoading: true, clearError: true);

        final newAvatarUrl = await _service.uploadAvatar(image.path);

        final updatedUser = Map<String, dynamic>.from(state.user);
        updatedUser['avatar'] = newAvatarUrl;

        state = state.copyWith(isLoading: false, user: updatedUser);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _ref.read(authStateProvider.notifier).setLoggedIn(false);
    state = ProfileState();
  }

  void clear() {
    _ref.read(authStateProvider.notifier).setLoggedIn(false);
    state = ProfileState();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final service = ref.watch(profileServiceProvider);
  return ProfileNotifier(service, ref);
});

// ═══════════════════════════════════════
// Pages (About, Privacy, Terms)
// ═══════════════════════════════════════
final pageProvider = FutureProvider.family<String, String>((ref, slug) async {
  final service = ref.watch(profileServiceProvider);
  return await service.getPage(slug);
});

// ═══════════════════════════════════════
// Contact Form
// ═══════════════════════════════════════
final contactLoadingProvider = StateProvider<bool>((ref) => false);

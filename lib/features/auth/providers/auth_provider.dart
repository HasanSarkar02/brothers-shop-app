import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());

// ── Auth State ─────────────────────────────────────
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    user: clearUser ? null : (user ?? this.user),
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

// ── Auth Notifier ──────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _loadUser();
  }

  // App start এ saved user load করো
  Future<void> _loadUser() async {
    final user = await _repo.getMe();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  // ── Login ──────────────────────────────
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(
        identifier: identifier,
        password: password,
      );
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // ── Register ───────────────────────────
  Future<void> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // ── Social Login ───────────────────────
  Future<void> socialLogin({
    required String provider,
    required String accessToken,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.socialLogin(
        provider: provider,
        accessToken: accessToken,
      );
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // ── Logout ─────────────────────────────
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ── Simple logged in check ─────────────────────────
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

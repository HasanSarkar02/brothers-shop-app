// lib/features/checkout/providers/checkout_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checkout_model.dart';
import '../services/checkout_service.dart';

// ── ১. State Class ────────────────────────────────────────
class CheckoutState {
  final bool isLoadingSummary;
  final bool isPlacingOrder;
  final CheckoutSummaryModel? summary;
  final String? error;

  const CheckoutState({
    this.isLoadingSummary = false,
    this.isPlacingOrder = false,
    this.summary,
    this.error,
  });

  CheckoutState copyWith({
    bool? isLoadingSummary,
    bool? isPlacingOrder,
    CheckoutSummaryModel? summary,
    String? error,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return CheckoutState(
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      summary: clearSummary ? null : (summary ?? this.summary),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ──  Service Provider ───────────────────────────────────
final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  return CheckoutService();
});

// ──  Controller/Notifier ────────────────────────────────
class CheckoutController extends StateNotifier<CheckoutState> {
  final CheckoutService _service;

  // Added const
  CheckoutController(this._service) : super(const CheckoutState()) {
    fetchSummary();
  }

  // কার্টের সামারি আনা (GET /checkout)
  Future<void> fetchSummary() async {
    state = state.copyWith(
      isLoadingSummary: true,
      clearError: true,
      clearSummary: true,
    );
    try {
      final summaryData = await _service.getCheckoutSummary();
      state = state.copyWith(isLoadingSummary: false, summary: summaryData);
    } catch (e) {
      state = state.copyWith(isLoadingSummary: false, error: e.toString());
    }
  }

  // অর্ডার প্লেস করা (POST /checkout/place-order)
  Future<OrderResponseModel?> placeOrder(Map<String, dynamic> orderData) async {
    state = state.copyWith(isPlacingOrder: true, clearError: true);
    try {
      final response = await _service.placeOrder(orderData);
      state = state.copyWith(isPlacingOrder: false);
      return response; // সফল হলে রেসপন্স রিটার্ন করবে
    } catch (e) {
      state = state.copyWith(isPlacingOrder: false, error: e.toString());
      rethrow; // UI-তে try-catch দিয়ে SnackBar দেখানোর জন্য
    }
  }
}

// ── ৪. StateNotifierProvider ──────────────────────────────
final checkoutProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
      final service = ref.watch(checkoutServiceProvider);
      return CheckoutController(service);
    });

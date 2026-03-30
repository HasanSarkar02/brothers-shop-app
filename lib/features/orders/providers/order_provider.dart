import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

// ═══════════════════════════════════════
// Service Provider
// ═══════════════════════════════════════
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

// ═══════════════════════════════════════
// Auth User: All Orders List
// ═══════════════════════════════════════
class OrderListState {
  final bool isLoading;
  final List<OrderModel> orders;
  final String? error;

  OrderListState({this.isLoading = false, this.orders = const [], this.error});

  OrderListState copyWith({
    bool? isLoading,
    List<OrderModel>? orders,
    String? error,
    bool clearError = false,
  }) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderService _service;

  // ✅ Constructor এ auto fetch বন্ধ
  OrderListNotifier(this._service) : super(OrderListState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _service.getMyOrders();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => fetchOrders();
}

final orderListProvider =
    StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
      return OrderListNotifier(ref.watch(orderServiceProvider));
    });

// ═══════════════════════════════════════
// Guest User: Track Order State
// ═══════════════════════════════════════
class GuestOrderState {
  final bool isSearching;
  final bool isOtpSent;
  final bool isVerifyingOtp;

  // Direct track result — single order
  final OrderModel? trackedOrder;

  // OTP verify result — multiple orders
  final List<OrderModel> orders;

  final String? error;

  GuestOrderState({
    this.isSearching = false,
    this.isOtpSent = false,
    this.isVerifyingOtp = false,
    this.trackedOrder,
    this.orders = const [],
    this.error,
  });

  // কোনো result আছে কিনা
  bool get hasResult => trackedOrder != null || orders.isNotEmpty;

  GuestOrderState copyWith({
    bool? isSearching,
    bool? isOtpSent,
    bool? isVerifyingOtp,
    OrderModel? trackedOrder,
    List<OrderModel>? orders,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return GuestOrderState(
      isSearching: isSearching ?? this.isSearching,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
      trackedOrder: clearResult ? null : (trackedOrder ?? this.trackedOrder),
      orders: clearResult ? [] : (orders ?? this.orders),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ═══════════════════════════════════════
// Guest Order Notifier
// ═══════════════════════════════════════
class GuestOrderNotifier extends StateNotifier<GuestOrderState> {
  final OrderService _service;

  GuestOrderNotifier(this._service) : super(GuestOrderState());

  // ── Direct Track (OTP ছাড়া) ───────────
  // Order Number + Phone দিয়ে সরাসরি track
  Future<void> trackOrder(String orderNumber, String phone) async {
    state = state.copyWith(
      isSearching: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final order = await _service.trackGuestOrder(
        orderNumber: orderNumber,
        phone: phone,
      );
      state = state.copyWith(isSearching: false, trackedOrder: order);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Send OTP ───────────────────────────
  // Phone নম্বরে OTP পাঠাবে
  Future<void> sendOtp(String orderNumber, String phone) async {
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      await _service.sendOtp(orderNumber: orderNumber, phone: phone);
      state = state.copyWith(isSearching: false, isOtpSent: true);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Verify OTP ─────────────────────────
  // OTP verify করে সব orders দেখাবে
  Future<void> verifyOtp(String orderNumber, String phone, String otp) async {
    state = state.copyWith(isVerifyingOtp: true, clearError: true);
    try {
      final orders = await _service.verifyOtp(
        orderNumber: orderNumber,
        phone: phone,
        otp: otp,
      );
      state = state.copyWith(
        isVerifyingOtp: false,
        orders: orders,
        isOtpSent: false, // OTP screen hide করো
      );
    } catch (e) {
      state = state.copyWith(
        isVerifyingOtp: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Reset ──────────────────────────────
  void reset() => state = GuestOrderState();
}

final guestOrderProvider =
    StateNotifierProvider<GuestOrderNotifier, GuestOrderState>((ref) {
      return GuestOrderNotifier(ref.watch(orderServiceProvider));
    });

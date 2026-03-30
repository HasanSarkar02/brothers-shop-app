import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';

// ── Search State ──────────────────────────────────────────
class SearchState {
  final bool isLoading;
  final List<dynamic> instantResults;
  final String query;
  final String? error;

  SearchState({
    this.isLoading = false,
    this.instantResults = const [],
    this.query = '',
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    List<dynamic>? instantResults,
    String? query,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      instantResults: instantResults ?? this.instantResults,
      query: query ?? this.query,
      error: error,
    );
  }
}

// ── Search Notifier with Debounce ─────────────────────────
class SearchNotifier extends StateNotifier<SearchState> {
  final Dio _dio;
  Timer? _debounce;

  SearchNotifier(this._dio) : super(SearchState());

  void onSearchQueryChanged(String query) {
    // স্টেট আপডেট করছি যাতে UI-তে লেখাটা থাকে
    state = state.copyWith(query: query);

    // আগের টাইমার ক্যান্সেল করে দিচ্ছি (Debounce Logic)
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 2) {
      state = state.copyWith(instantResults: [], isLoading: false);
      return;
    }

    // ইউজার টাইপ থামানোর ৩০০ মিলিসেকেন্ড পর API কল হবে
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchInstantResults(query);
    });
  }

  Future<void> _fetchInstantResults(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(
        '/search/instant',
        queryParameters: {'q': query},
      );
      final res = response.data;

      if (res['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          instantResults: res['results'] ?? [],
        );
      } else {
        state = state.copyWith(isLoading: false, error: res['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final dioProvider = Provider<Dio>((ref) {
  return DioClient.instance;
});
// ── Provider ──────────────────────────────────────────────
final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
      return SearchNotifier(ref.watch(dioProvider));
    });

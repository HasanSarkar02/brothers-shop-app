import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/search_repository.dart';

final searchRepositoryProvider = Provider((_) => SearchRepository());

// ── Search State ──────────────────────────────────────────
class SearchState {
  final bool isLoading;
  final List<dynamic> instantResults;
  final String query;
  final String? error;

  const SearchState({
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
    bool clearError = false,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      instantResults: instantResults ?? this.instantResults,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Search Notifier with Debounce & CancelToken ───────────
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repo;
  Timer? _debounce;
  CancelToken? _cancelToken;

  SearchNotifier(this._repo) : super(const SearchState());

  void onSearchQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _cancelToken?.cancel('User typed a new query');

    state = state.copyWith(query: query, clearError: true);

    if (query.trim().length < 2) {
      state = state.copyWith(instantResults: [], isLoading: false);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchInstantResults(query);
    });
  }

  Future<void> _fetchInstantResults(String query) async {
    state = state.copyWith(isLoading: true);

    _cancelToken = CancelToken();

    try {
      final results = await _repo.fetchInstantResults(
        query,
        cancelToken: _cancelToken,
      );

      state = state.copyWith(isLoading: false, instantResults: results);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('Notifier disposed');
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────
final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
      return SearchNotifier(ref.read(searchRepositoryProvider));
    });

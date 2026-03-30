import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_model.dart';
import '../repository/home_repository.dart';

final homeRepositoryProvider = Provider((_) => HomeRepository());

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  return ref.read(homeRepositoryProvider).getHomeData();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/search_history_service.dart';

final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  return SearchHistoryService();
});

final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(searchHistoryServiceProvider);
  return service.getHistory();
});

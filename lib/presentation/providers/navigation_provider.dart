import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for bottom navigation state
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0) {
    _loadSavedIndex();
  }

  static const String _keyNavigationIndex = 'navigation_index';

  Future<void> _loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_keyNavigationIndex) ?? 0;
    state = savedIndex;
  }

  Future<void> setIndex(int index) async {
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNavigationIndex, index);
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier();
});

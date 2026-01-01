import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the active state of the sleep timer
final sleepTimerProvider = StateProvider<bool>((ref) => false);

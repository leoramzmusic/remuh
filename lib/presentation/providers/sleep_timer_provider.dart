import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SleepTimerState {
  final Duration? remainingTime;
  final bool isActive;
  final bool pauseAtEndOfTrack;

  const SleepTimerState({
    this.remainingTime,
    this.isActive = false,
    this.pauseAtEndOfTrack = false,
  });

  SleepTimerState copyWith({
    Duration? Function()? remainingTime,
    bool? isActive,
    bool? pauseAtEndOfTrack,
  }) {
    return SleepTimerState(
      remainingTime: remainingTime != null
          ? remainingTime()
          : this.remainingTime,
      isActive: isActive ?? this.isActive,
      pauseAtEndOfTrack: pauseAtEndOfTrack ?? this.pauseAtEndOfTrack,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  Timer? _timer;

  SleepTimerNotifier() : super(const SleepTimerState());

  void setTimer(Duration duration) {
    _cancelInternal();
    state = state.copyWith(
      isActive: true,
      remainingTime: () => duration,
      pauseAtEndOfTrack: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime == null) return;

      if (state.remainingTime! <= Duration.zero) {
        _onTimerFinished();
      } else {
        state = state.copyWith(
          remainingTime: () =>
              state.remainingTime! - const Duration(seconds: 1),
        );
      }
    });
  }

  void setPauseAtEndOfTrack() {
    _cancelInternal();
    state = state.copyWith(
      isActive: true,
      remainingTime: () => null,
      pauseAtEndOfTrack: true,
    );
  }

  void cancelTimer() {
    _cancelInternal();
    state = const SleepTimerState();
  }

  void _cancelInternal() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTimerFinished() {
    cancelTimer();
    // La pausa ahora es manejada por AudioPlayerNotifier escuchando este estado
    state = state.copyWith(remainingTime: () => Duration.zero);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
      return SleepTimerNotifier();
    });

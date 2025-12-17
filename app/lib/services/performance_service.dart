import 'dart:async';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _timers = {};

  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  void stopTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      _timers.remove(name);
      
      // Log ou enviar para backend
      print('Performance: $name took ${duration}ms');
    }
  }

  T measure<T>(String name, T Function() function) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = function();
      stopwatch.stop();
      print('Performance: $name took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('Performance: $name failed after ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  }

  Future<T> measureAsync<T>(String name, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      print('Performance: $name took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('Performance: $name failed after ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  }
}


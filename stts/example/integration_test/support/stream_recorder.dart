import 'dart:async';

/// Records events and errors of a stream, in arrival order.
class StreamRecorder<T> {
  StreamRecorder(Stream<T> stream) {
    _subscription = stream.listen(
      (event) {
        events.add(event);
        _changes.add(null);
      },
      onError: (Object error) {
        errors.add(error);
        _changes.add(null);
      },
    );
  }

  final events = <T>[];
  final errors = <Object>[];
  final _changes = StreamController<void>.broadcast();
  late final StreamSubscription<T> _subscription;

  /// Waits until [event] is recorded at or after index [from] and returns its index.
  Future<int> waitFor(
    T event, {
    int from = 0,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (true) {
      final index = events.indexOf(event, from);
      if (index != -1) return index;

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw TimeoutException(
          '$event not received from index $from. Events: $events, errors: $errors',
          timeout,
        );
      }

      await _changes.stream.first.timeout(remaining, onTimeout: () {});
    }
  }

  /// Returns events recorded during the next [duration].
  Future<List<T>> eventsDuring(Duration duration) async {
    final start = events.length;
    await Future<void>.delayed(duration);
    return events.sublist(start);
  }

  Future<void> cancel() async {
    await _subscription.cancel();
    await _changes.close();
  }
}

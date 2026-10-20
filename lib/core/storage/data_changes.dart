import 'dart:async';

abstract final class DataChanges {
  static final _controller = StreamController<void>.broadcast(sync: true);
  static Stream<void> get stream => _controller.stream;
  static void notify() => _controller.add(null);
}

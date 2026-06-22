import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/stream_event.dart';

/// Thin wrapper over the browser's native EventSource. One connection per
/// session, no manual reconnect: the backend replays the full history on
/// every connect, so reconnecting would duplicate events. The owning
/// notifier calls [close] the instant a `done`/`error` event arrives.
class SseConnection {
  final web.EventSource _es;
  final _controller = StreamController<StreamEvent>();
  bool _closed = false;

  SseConnection(String url) : _es = web.EventSource(url) {
    _es.onmessage = ((web.Event e) {
      final msg = e as web.MessageEvent;
      try {
        final raw = (msg.data as JSString).toDart;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (!_controller.isClosed) {
          _controller.add(StreamEvent.fromJson(json));
        }
      } catch (_) {
        // ignore parse errors, parity with the React hook
      }
    }).toJS;

    _es.onerror = ((web.Event _) {
      if (!_controller.isClosed) {
        _controller.addError(const SseError('Stream connection lost'));
      }
    }).toJS;
  }

  Stream<StreamEvent> get events => _controller.stream;

  void close() {
    if (_closed) return;
    _closed = true;
    _es.close();
    if (!_controller.isClosed) _controller.close();
  }
}

class SseError implements Exception {
  final String message;
  const SseError(this.message);

  @override
  String toString() => message;
}

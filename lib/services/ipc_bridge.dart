import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// IPC Bridge for communication with Electron
/// Listens on stdin for commands and sends responses/events to stdout
class IPCBridge {
  static final IPCBridge _instance = IPCBridge._internal();
  factory IPCBridge() => _instance;
  IPCBridge._internal();

  final _commandController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get commandStream => _commandController.stream;

  bool _isInitialized = false;
  StreamSubscription? _stdinSubscription;

  /// Initialize the IPC bridge
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    debugPrint('[IPC] Initializing IPC Bridge...');

    // Listen to stdin for commands from Electron
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.trim().isEmpty) return;
        
        try {
          final data = jsonDecode(line);
          debugPrint('[IPC] Received command: ${data['type']}');
          _commandController.add(data);
        } catch (e) {
          debugPrint('[IPC] Error parsing command: $e');
          sendError('parse_error', 'Failed to parse command: $e');
        }
      },
      onError: (error) {
        debugPrint('[IPC] stdin error: $error');
      },
      onDone: () {
        debugPrint('[IPC] stdin closed');
      },
    );

    // Send ready signal
    sendEvent('ready', {'version': '1.0.0'});
  }

  /// Send a response back to Electron
  void sendResponse(String id, Map<String, dynamic> data) {
    _send({
      'type': 'response',
      'id': id,
      'data': data,
    });
  }

  /// Send an event to Electron
  void sendEvent(String event, Map<String, dynamic> data) {
    _send({
      'type': 'event',
      'event': event,
      'data': data,
    });
  }

  /// Send an error to Electron
  void sendError(String code, String message) {
    _send({
      'type': 'error',
      'code': code,
      'message': message,
    });
  }

  void _send(Map<String, dynamic> data) {
    try {
      final json = jsonEncode(data);
      stdout.writeln(json);
      debugPrint('[IPC] Sent: ${data['type']} - ${data['event'] ?? data['code'] ?? ''}');
    } catch (e) {
      debugPrint('[IPC] Error sending data: $e');
    }
  }

  void dispose() {
    _stdinSubscription?.cancel();
    _commandController.close();
    _isInitialized = false;
  }
}

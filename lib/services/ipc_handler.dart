import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nipaplay/utils/video_player_state.dart';
import 'package:nipaplay/player_abstraction/player_abstraction.dart';
import 'package:window_manager/window_manager.dart';
import 'ipc_bridge.dart';

/// Handles IPC commands from Electron
class IPCHandler {
  final IPCBridge _bridge = IPCBridge();
  final VideoPlayerState videoPlayerState;
  StreamSubscription? _commandSubscription;

  IPCHandler(this.videoPlayerState);

  void initialize() {
    _bridge.initialize();
    
    _commandSubscription = _bridge.commandStream.listen((command) {
      _handleCommand(command);
    });

    // Listen to video player events and send them to Electron
    videoPlayerState.addListener(_onVideoPlayerStateChanged);
  }

  void _handleCommand(Map<String, dynamic> command) {
    final type = command['type'] as String?;
    final id = command['id'] as String?;
    final data = command['data'] as Map<String, dynamic>?;

    try {
      switch (type) {
        case 'load_video':
          _handleLoadVideo(id, data);
          break;
        case 'play':
          _handlePlay(id);
          break;
        case 'pause':
          _handlePause(id);
          break;
        case 'seek':
          _handleSeek(id, data);
          break;
        case 'set_volume':
          _handleSetVolume(id, data);
          break;
        case 'add_external_subtitle':
          _handleAddExternalSubtitle(id, data);
          break;
        case 'select_subtitle':
          _handleSelectSubtitle(id, data);
          break;
        case 'set_window_size':
          _handleSetWindowSize(id, data);
          break;
        case 'get_state':
          _handleGetState(id);
          break;
        case 'toggle_fullscreen':
          _handleToggleFullscreen(id);
          break;
        default:
          _bridge.sendError('unknown_command', 'Unknown command type: $type');
      }
    } catch (e) {
      _bridge.sendError('command_error', 'Error handling command: $e');
    }
  }

  void _handleLoadVideo(String? id, Map<String, dynamic>? data) async {
    final url = data?['url'] as String?;
    if (url == null) {
      _bridge.sendError('invalid_params', 'Missing url parameter');
      return;
    }

    final startTime = data?['startTime'] as int? ?? 0;

    try {
      await videoPlayerState.initializePlayer(url);
      
      // Seek to start position if specified
      if (startTime > 0) {
        videoPlayerState.seekTo(Duration(milliseconds: startTime));
      }

      if (id != null) {
        _bridge.sendResponse(id, {'success': true});
      }
    } catch (e) {
      _bridge.sendError('load_error', 'Failed to load video: $e');
    }
  }

  void _handlePlay(String? id) {
    videoPlayerState.play();
    if (id != null) {
      _bridge.sendResponse(id, {'success': true});
    }
  }

  void _handlePause(String? id) {
    videoPlayerState.pause();
    if (id != null) {
      _bridge.sendResponse(id, {'success': true});
    }
  }

  void _handleSeek(String? id, Map<String, dynamic>? data) {
    final position = data?['position'] as int?;
    if (position == null) {
      _bridge.sendError('invalid_params', 'Missing position parameter');
      return;
    }

    videoPlayerState.seekTo(Duration(milliseconds: position));
    if (id != null) {
      _bridge.sendResponse(id, {'success': true});
    }
  }

  void _handleSetVolume(String? id, Map<String, dynamic>? data) {
    final volume = data?['volume'] as num?;
    if (volume == null) {
      _bridge.sendError('invalid_params', 'Missing volume parameter');
      return;
    }

    videoPlayerState.player.volume = volume.toDouble().clamp(0.0, 1.0);
    if (id != null) {
      _bridge.sendResponse(id, {'success': true});
    }
  }

  void _handleAddExternalSubtitle(String? id, Map<String, dynamic>? data) {
    final name = data?['name'] as String?;
    final url = data?['url'] as String?;
    final comment = data?['comment'] as String?; // Optional comment/description

    if (name == null || url == null) {
      _bridge.sendError('invalid_params', 'Missing name or url parameter');
      return;
    }

    videoPlayerState.ipcExternalSubtitles.add({
      'name': name,
      'url': url,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    videoPlayerState.notifyListeners(); // Notify UI to update

    if (id != null) {
      _bridge.sendResponse(id, {
        'success': true,
        'index': videoPlayerState.ipcExternalSubtitles.length - 1,
      });
    }
  }

  void _handleSelectSubtitle(String? id, Map<String, dynamic>? data) {
    final index = data?['index'] as int?;
    
    if (index == null) {
      _bridge.sendError('invalid_params', 'Missing index parameter');
      return;
    }

    if (index == -1) {
      // Turn off subtitles
      videoPlayerState.player.activeSubtitleTracks = [];
    } else if (index >= 0 && index < videoPlayerState.ipcExternalSubtitles.length) {
      // Load external subtitle
      final subtitle = videoPlayerState.ipcExternalSubtitles[index];
      try {
        videoPlayerState.player.setMedia(subtitle['url']!, MediaType.subtitle);
      } catch (e) {
        _bridge.sendError('subtitle_error', 'Failed to load subtitle: $e');
        return;
      }
    } else {
      // Built-in subtitle track
      final builtInIndex = index - videoPlayerState.ipcExternalSubtitles.length;
      videoPlayerState.player.activeSubtitleTracks = [builtInIndex];
    }

    if (id != null) {
      _bridge.sendResponse(id, {'success': true});
    }
  }

  void _handleSetWindowSize(String? id, Map<String, dynamic>? data) async {
    final width = data?['width'] as num?;
    final height = data?['height'] as num?;

    if (width == null || height == null) {
      _bridge.sendError('invalid_params', 'Missing width or height parameter');
      return;
    }

    try {
      await windowManager.setSize(Size(width.toDouble(), height.toDouble()));
      if (id != null) {
        _bridge.sendResponse(id, {'success': true});
      }
    } catch (e) {
      _bridge.sendError('window_error', 'Failed to set window size: $e');
    }
  }

  void _handleGetState(String? id) {
    if (id == null) return;

    _bridge.sendResponse(id, {
      'hasVideo': videoPlayerState.hasVideo,
      'isPlaying': videoPlayerState.status == PlayerStatus.playing,
      'isPaused': videoPlayerState.status == PlayerStatus.paused,
      'position': videoPlayerState.position.inMilliseconds,
      'duration': videoPlayerState.duration.inMilliseconds,
      'volume': videoPlayerState.player.volume,
      'isFullscreen': videoPlayerState.isFullscreen,
      'externalSubtitles': videoPlayerState.ipcExternalSubtitles,
    });
  }

  void _handleToggleFullscreen(String? id) async {
    await videoPlayerState.toggleFullscreen();
    if (id != null) {
      _bridge.sendResponse(id, {'success': true});
    }
  }

  void _onVideoPlayerStateChanged() {
    // Send state updates to Electron
    _bridge.sendEvent('state_changed', {
      'hasVideo': videoPlayerState.hasVideo,
      'isPlaying': videoPlayerState.status == PlayerStatus.playing,
      'isPaused': videoPlayerState.status == PlayerStatus.paused,
      'position': videoPlayerState.position.inMilliseconds,
      'duration': videoPlayerState.duration.inMilliseconds,
      'volume': videoPlayerState.player.volume,
      'isFullscreen': videoPlayerState.isFullscreen,
    });
  }

  void dispose() {
    _commandSubscription?.cancel();
    videoPlayerState.removeListener(_onVideoPlayerStateChanged);
  }
}

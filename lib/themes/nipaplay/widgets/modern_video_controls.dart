import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io' show Platform, exit;
import 'package:nipaplay/utils/video_player_state.dart';
import 'package:nipaplay/utils/globals.dart' as globals;
import 'package:provider/provider.dart';
import 'url_input_dialog.dart';
import 'external_subtitle_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'package:nipaplay/player_abstraction/player_abstraction.dart';

class ModernVideoControls extends StatefulWidget {
  const ModernVideoControls({super.key});

  @override
  State<ModernVideoControls> createState() => _ModernVideoControlsState();
}

class _ModernVideoControlsState extends State<ModernVideoControls> {
  bool _isDragging = false;
  double _dragPosition = 0.0;
  bool _isHovering = false;
  Offset? _hoverPosition;
  
  // Volume control state
  double? _volumeOverride;
  
  // Subtitle customization state
  double _subtitleDelay = 0.0;
  double _subtitleSize = 32.0;
  double _subtitlePosition = 130.0;
  
  // Active external subtitle URL (for UI state only)
  String? _activeExternalSubtitle;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onProgressDragStart(VideoPlayerState videoState, double localX, double width) {
    setState(() {
      _isDragging = true;
      _dragPosition = (localX / width).clamp(0.0, 1.0);
    });
  }

  void _onProgressDragUpdate(double localX, double width, VideoPlayerState videoState) {
    setState(() {
      _dragPosition = (localX / width).clamp(0.0, 1.0);
    });
  }

  void _onProgressDragEnd(VideoPlayerState videoState) {
    final seekPositionMs = (_dragPosition * videoState.duration.inMilliseconds).round();
    videoState.player.seek(position: seekPositionMs);
    setState(() {
      _isDragging = false;
    });
  }

  void _onProgressTap(double localX, double width, VideoPlayerState videoState) {
    final position = (localX / width).clamp(0.0, 1.0);
    final seekPositionMs = (position * videoState.duration.inMilliseconds).round();
    videoState.player.seek(position: seekPositionMs);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerState>(
      builder: (context, videoState, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Draggable Top Bar
            if (!globals.isPhone && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onPanStart: (details) {
                    windowManager.startDragging();
                  },
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
                    child: Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => exit(0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            'PlayTorrio Player',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFc77dff),
                              shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Exit Button for mobile
            if (globals.isPhone)
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => exit(0),
                  tooltip: 'Exit',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              
            // Bottom Controls
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: videoState.controlBarHeight,
                  left: 20,
                  right: 20,
                ),
                child: MouseRegion(
                  onEnter: (_) => videoState.setControlsHovered(true),
                  onExit: (_) => videoState.setControlsHovered(false),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProgressBar(videoState),
                      const SizedBox(height: 15),
                      _buildControlBar(videoState),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(VideoPlayerState videoState) {
    final progress = _isDragging ? _dragPosition : videoState.progress;
    
    return MouseRegion(
      onEnter: (event) => setState(() => _isHovering = true),
      onHover: (event) => setState(() {
        _isHovering = true;
        _hoverPosition = event.localPosition;
      }),
      onExit: (event) => setState(() {
        _isHovering = false;
        _hoverPosition = null;
      }),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          return GestureDetector(
            onHorizontalDragStart: (details) {
              _onProgressDragStart(videoState, details.localPosition.dx, width);
            },
            onHorizontalDragUpdate: (details) {
              _onProgressDragUpdate(details.localPosition.dx, width, videoState);
            },
            onHorizontalDragEnd: (_) => _onProgressDragEnd(videoState),
            onTapDown: (details) {
              _onProgressTap(details.localPosition.dx, width, videoState);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: _isHovering ? 10 : 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9d4edd), Color(0xFFc77dff)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9d4edd).withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (_isHovering && _hoverPosition != null && videoState.duration.inMilliseconds > 0)
                    Positioned(
                      left: _hoverPosition!.dx,
                      bottom: 35,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0), // Center the tooltip (50% of its own width to the left)
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9d4edd),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                            ],
                          ),
                          child: Text(
                            _formatDuration(Duration(
                              milliseconds: ((_hoverPosition!.dx / width) * videoState.duration.inMilliseconds).round(),
                            )),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlBar(VideoPlayerState videoState) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(30),
        right: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a001a).withOpacity(0.95),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(30),
              right: Radius.circular(30),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: globals.isPhone ? 6 : 20,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    videoState.status == PlayerStatus.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 38,
                  ),
                  onPressed: videoState.hasVideo
                      ? () => videoState.togglePlayPause()
                      : null,
                ),
                const SizedBox(width: 10),
                _buildVolumeControl(videoState),
                const SizedBox(width: 20),
                Text(
                  '${_formatDuration(videoState.position)} / ${_formatDuration(videoState.duration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.link_rounded, color: Colors.white, size: 38),
                  onPressed: () {
                    // Get current video URL if available
                    String? currentUrl;
                    if (videoState.hasVideo && videoState.currentVideoPath != null) {
                      currentUrl = videoState.currentVideoPath;
                    }
                    
                    showDialog(
                      context: context,
                      builder: (context) => UrlInputDialog(currentUrl: currentUrl),
                    );
                  },
                  tooltip: 'Open URL',
                ),
                IconButton(
                  icon: const Icon(Icons.audiotrack, color: Colors.white, size: 38),
                  onPressed: videoState.hasVideo
                      ? () => _showAudioMenu(context, videoState)
                      : null,
                  tooltip: 'Audio Tracks',
                ),
                IconButton(
                  icon: const Icon(Icons.subtitles, color: Colors.white, size: 38),
                  onPressed: videoState.hasVideo
                      ? () => _showSubtitleMenu(context, videoState)
                      : null,
                  tooltip: 'Subtitles',
                ),
                IconButton(
                  icon: Icon(
                    videoState.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                    size: 38,
                  ),
                  onPressed: () => videoState.toggleFullscreen(),
                  tooltip: 'Fullscreen',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl(VideoPlayerState videoState) {
    final currentVolume = _volumeOverride ?? videoState.player.volume;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF9d4edd).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              currentVolume == 0
                  ? Icons.volume_off
                  : currentVolume < 0.5
                      ? Icons.volume_down
                      : Icons.volume_up,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              final newVolume = currentVolume > 0 ? 0.0 : 1.0;
              setState(() {
                _volumeOverride = newVolume;
              });
              videoState.player.volume = newVolume;
              // Clear override after a short delay
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _volumeOverride = null;
                  });
                }
              });
            },
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: const Color(0xFF9d4edd),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: currentVolume.clamp(0.0, 1.0),
                onChanged: (value) {
                  setState(() {
                    _volumeOverride = value;
                  });
                  videoState.player.volume = value;
                },
                onChangeEnd: (value) {
                  // Clear override after dragging ends
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _volumeOverride = null;
                      });
                    }
                  });
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAudioMenu(BuildContext context, VideoPlayerState videoState) {
    final audioTracks = videoState.player.mediaInfo.audio ?? [];
    final activeAudioTracks = videoState.player.activeAudioTracks;
    final currentTrackIndex = activeAudioTracks.isNotEmpty ? activeAudioTracks.first : -1;
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 200,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0a001a).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF9d4edd).withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                width: 360,
                constraints: const BoxConstraints(maxHeight: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AUDIO TRACKS',
                            style: TextStyle(
                              color: Color(0xFFc77dff),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Flexible(
                      child: audioTracks.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                'No audio tracks available',
                                style: TextStyle(color: Colors.white54),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(15),
                              itemCount: audioTracks.length,
                              itemBuilder: (context, index) {
                                final track = audioTracks[index];
                                final isSelected = currentTrackIndex == index;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF9d4edd)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      track.title ?? 'Audio Track ${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    onTap: () {
                                      videoState.player.activeAudioTracks = [index];
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubtitleMenu(BuildContext context, VideoPlayerState videoState) {
    final subtitleTracks = videoState.player.mediaInfo.subtitle ?? [];
    final activeSubtitleTracks = videoState.player.activeSubtitleTracks;
    final currentTrackIndex = activeSubtitleTracks.isNotEmpty ? activeSubtitleTracks.first : -1;
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              bottom: 120,
              right: 120,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: EdgeInsets.zero,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a001a).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF9d4edd).withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  width: 360,
                  constraints: const BoxConstraints(maxHeight: 650),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SUBTITLES',
                              style: TextStyle(
                                color: Color(0xFFc77dff),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(15),
                          itemCount: subtitleTracks.length + 2 + videoState.ipcExternalSubtitles.length, // +2 for "Off" and "Add External"
                          itemBuilder: (context, index) {
                            // Add External Subtitle button
                            if (index == 0) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9d4edd).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF9d4edd),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.add, color: Colors.white),
                                  title: const Text(
                                    'Add External Subtitle',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (context) => ExternalSubtitleDialog(
                                        onAdd: (name, url) {
                                          setState(() {
                                            videoState.ipcExternalSubtitles.add({
                                              'name': name,
                                              'url': url,
                                            });
                                          });
                                          
                                          // Load the external subtitle
                                          try {
                                            videoState.player.setMedia(url, MediaType.subtitle);
                                            setState(() {
                                              _activeExternalSubtitle = url;
                                            });
                                          } catch (e) {
                                            debugPrint('Failed to load external subtitle: $e');
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to load subtitle: $e'),
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            
                            // Off option
                            if (index == 1) {
                              final isSelected = currentTrackIndex == -1 && _activeExternalSubtitle == null;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF9d4edd)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  title: Text(
                                    'Off',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  onTap: () {
                                    videoState.player.activeSubtitleTracks = [];
                                    setState(() {
                                      _activeExternalSubtitle = null;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            }
                            
                            // External subtitles
                            if (index >= 2 && index < 2 + videoState.ipcExternalSubtitles.length) {
                              final extIndex = index - 2;
                              final extSub = videoState.ipcExternalSubtitles[extIndex];
                              final isSelected = _activeExternalSubtitle == extSub['url'];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF9d4edd)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.language, color: Colors.white70, size: 20),
                                  title: Text(
                                    extSub['name']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white54, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        if (_activeExternalSubtitle == extSub['url']) {
                                          _activeExternalSubtitle = null;
                                          videoState.player.activeSubtitleTracks = [];
                                        }
                                        videoState.ipcExternalSubtitles.removeAt(extIndex);
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  onTap: () {
                                    try {
                                      videoState.player.setMedia(extSub['url']!, MediaType.subtitle);
                                      setState(() {
                                        _activeExternalSubtitle = extSub['url'];
                                      });
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      debugPrint('Failed to load external subtitle: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to load subtitle: $e'),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }

                            final trackIndex = index - 2 - videoState.ipcExternalSubtitles.length; // Adjust for "Add External", "Off", and external subs
                            final track = subtitleTracks[trackIndex];
                            final isSelected = currentTrackIndex == trackIndex && _activeExternalSubtitle == null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF9d4edd)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                title: Text(
                                  track.title ?? 'Subtitle ${trackIndex + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                onTap: () {
                                  videoState.player.activeSubtitleTracks = [trackIndex];
                                  setState(() {
                                    _activeExternalSubtitle = null;
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Delay (s)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: TextField(
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9d4edd),
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    controller: TextEditingController(
                                      text: _subtitleDelay.toStringAsFixed(1),
                                    ),
                                    onChanged: (value) {
                                      final delay = double.tryParse(value) ?? 0.0;
                                      setDialogState(() => _subtitleDelay = delay);
                                      setState(() => _subtitleDelay = delay);
                                      try {
                                        videoState.player.setProperty('sub-delay', delay.toString());
                                      } catch (e) {
                                        debugPrint('Failed to set subtitle delay: $e');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Text Size',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: const Color(0xFF9d4edd),
                                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: _subtitleSize,
                                      min: 16,
                                      max: 80,
                                      onChanged: (value) {
                                        setDialogState(() => _subtitleSize = value);
                                        setState(() => _subtitleSize = value);
                                        try {
                                          final scale = value / 32.0;
                                          videoState.player.setProperty('sub-scale', scale.toStringAsFixed(2));
                                        } catch (e) {
                                          debugPrint('Failed to set subtitle size: $e');
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _subtitleSize.round().toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Position',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: const Color(0xFF9d4edd),
                                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: _subtitlePosition,
                                      min: 40,
                                      max: 500,
                                      onChanged: (value) {
                                        setDialogState(() => _subtitlePosition = value);
                                        setState(() => _subtitlePosition = value);
                                        try {
                                          final pos = 95 - ((value - 40) / (500 - 40) * 85);
                                          videoState.player.setProperty('sub-pos', pos.round().toString());
                                        } catch (e) {
                                          debugPrint('Failed to set subtitle position: $e');
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _subtitlePosition.round().toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

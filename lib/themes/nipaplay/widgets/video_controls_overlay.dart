import 'package:flutter/material.dart';
import 'package:nipaplay/utils/video_player_state.dart';
import 'modern_video_controls.dart';
import 'package:provider/provider.dart';

class VideoControlsOverlay extends StatelessWidget {
  const VideoControlsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerState>(
      builder: (context, videoState, child) {
        // Show/hide controls based on state
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: videoState.showControls ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !videoState.showControls,
              child: const ModernVideoControls(),
            ),
          ),
        );
      },
    );
  }
}

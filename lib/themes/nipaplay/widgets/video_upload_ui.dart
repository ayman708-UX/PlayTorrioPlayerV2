import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:nipaplay/providers/appearance_settings_provider.dart';

class VideoUploadUI extends StatefulWidget {
  const VideoUploadUI({super.key});

  @override
  State<VideoUploadUI> createState() => _VideoUploadUIState();
}

class _VideoUploadUIState extends State<VideoUploadUI> {
  @override
  Widget build(BuildContext context) {
    final appearanceProvider = Provider.of<AppearanceSettingsProvider>(context);
    final bool enableBlur = appearanceProvider.enableWidgetBlurEffect;

    return const SizedBox.shrink();
  }
}

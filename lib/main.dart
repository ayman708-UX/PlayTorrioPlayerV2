import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'utils/globals.dart' as globals;
import 'utils/video_player_state.dart';
import 'pages/play_video_page.dart';
import 'providers/ui_theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/appearance_settings_provider.dart';
import 'providers/developer_options_provider.dart';
import 'services/debug_log_service.dart';
import 'utils/storage_service.dart';
import 'utils/settings_storage.dart';
import 'player_abstraction/player_factory.dart';
import 'danmaku_abstraction/danmaku_kernel_factory.dart';
import 'services/http_client_initializer.dart';
import 'services/ipc_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Stub class for compatibility with unused pages
class MainPageState {
  TabController? globalTabController;
  
  static MainPageState? of(BuildContext context) {
    return null;
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse command line arguments
  String? videoUrl;
  int? windowWidth;
  int? windowHeight;
  bool enableIPC = false;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--url' && i + 1 < args.length) {
      videoUrl = args[i + 1];
    } else if (args[i] == '--width' && i + 1 < args.length) {
      windowWidth = int.tryParse(args[i + 1]);
    } else if (args[i] == '--height' && i + 1 < args.length) {
      windowHeight = int.tryParse(args[i + 1]);
    } else if (args[i] == '--ipc') {
      enableIPC = true;
    }
  }

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  // Install HTTP client overrides
  await HttpClientInitializer.install();

  // Initialize debug log service
  final debugLogService = DebugLogService();
  debugLogService.initialize();

  // Initialize player and danmaku factories
  PlayerFactory.initialize();
  DanmakuKernelFactory.initialize();

  // Initialize window manager for desktop
  if (globals.isDesktop) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = WindowOptions(
      size: Size(
        windowWidth?.toDouble() ?? 1280,
        windowHeight?.toDouble() ?? 720,
      ),
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(SimplePlayerApp(
    initialVideoUrl: videoUrl,
    enableIPC: enableIPC,
  ));
}

class SimplePlayerApp extends StatefulWidget {
  final String? initialVideoUrl;
  final bool enableIPC;

  const SimplePlayerApp({
    super.key,
    this.initialVideoUrl,
    this.enableIPC = false,
  });

  @override
  State<SimplePlayerApp> createState() => _SimplePlayerAppState();
}

class _SimplePlayerAppState extends State<SimplePlayerApp> {
  late VideoPlayerState _videoPlayerState;
  IPCHandler? _ipcHandler;

  @override
  void initState() {
    super.initState();
    _videoPlayerState = VideoPlayerState();

    // Initialize IPC if enabled
    if (widget.enableIPC) {
      _ipcHandler = IPCHandler(_videoPlayerState);
      _ipcHandler!.initialize();
    }

    // Load initial video if provided
    if (widget.initialVideoUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _videoPlayerState.initializePlayer(widget.initialVideoUrl!);
      });
    }
  }

  @override
  void dispose() {
    _ipcHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _videoPlayerState),
        ChangeNotifierProvider(create: (_) => UIThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AppearanceSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DeveloperOptionsProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'PlayTorrio Player',
        debugShowCheckedModeBanner: false,
        locale: const Locale('en', 'US'), // Force English
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          primaryColor: const Color(0xFF9d4edd),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9d4edd),
            secondary: Color(0xFFc77dff),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
          ),
        ),
        home: const PlayVideoPage(),
      ),
    );
  }
}

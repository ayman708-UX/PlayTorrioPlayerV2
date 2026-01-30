# PlayTorrio Video Player

<div align="center">

![Platform support](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey?style=flat-square) ![License](https://img.shields.io/github/license/ayman708-UX/PlayTorrioPlayerV2?style=flat-square)

**A powerful, cross-platform video player built with Flutter for PlayTorrio**

Featuring advanced playback controls, IPC bridge for Electron integration, automatic subtitle management, and seamless streaming support.

</div>

---

## 🎯 Overview

PlayTorrio Video Player is a high-performance video player built specifically for the PlayTorrio ecosystem. It provides a native-like experience across Windows, macOS, and Linux platforms with advanced features like:

- **IPC Bridge**: Full Electron/Node.js integration via stdin/stdout communication
- **Streaming Support**: Automatic retry logic for reliable HTTP/HTTPS streaming
- **Subtitle Management**: Multiple external subtitle support with automatic language detection
- **Modern UI**: Clean, responsive interface with playback controls
- **Cross-Platform**: Single codebase for Windows, macOS, and Linux

## ✨ Key Features

### 🎬 Video Playback
- **Multiple Player Engines**: Support for Media Kit (libmpv), FVP (libmdk), and Video Player
- **Format Support**: Wide range of video formats (MP4, MKV, AVI, WebM, etc.)
- **Hardware Acceleration**: GPU-accelerated decoding for smooth playback
- **Streaming**: HTTP/HTTPS streaming with automatic retry on connection errors
- **Playback Controls**: Play, pause, seek, volume, playback speed
- **Screenshot Capture**: Take screenshots during playback

### 📝 Subtitle Support
- **Multiple Formats**: ASS, SRT subtitle support
- **External Subtitles**: Add unlimited external subtitle files
- **Built-in Subtitles**: Automatic detection of embedded subtitle tracks
- **Language Detection**: Smart language identification (English, Chinese, Japanese, Korean, etc.)
- **Subtitle Comments**: Add source/quality notes to subtitle tracks
- **Track Switching**: Easy switching between subtitle tracks

### 🔌 IPC Bridge Integration
- **Electron Compatible**: Full integration with Electron apps via IPC
- **JSON Protocol**: Simple JSON-based command/response system
- **Real-time Events**: State change notifications for UI synchronization
- **Command Line Args**: Launch with pre-configured settings
- **Process Control**: Clean startup and shutdown handling

### 🎨 User Interface
- **Modern Design**: Clean, intuitive interface
- **Responsive Layout**: Adapts to different window sizes
- **Fullscreen Mode**: Distraction-free viewing experience
- **Playback Info**: Detailed technical information display
- **Error Handling**: User-friendly error messages in English

## 🚀 Quick Start

### For End Users

Download the latest release for your platform:
- **Windows**: `PlayTorrio-Windows-x64.zip`
- **macOS**: `PlayTorrio-macOS.dmg`
- **Linux**: `PlayTorrio-Linux-x64.tar.gz`

Extract and run the executable:
```bash
# Windows
PlayTorrio.exe

# macOS
open PlayTorrio.app

# Linux
./PlayTorrio
```

### For Developers (Electron Integration)

1. **Install the player** in your Electron project:
```bash
# Copy the player executable to your project
cp /path/to/PlayTorrio.exe ./resources/player/
```

2. **Use the IPC bridge**:
```javascript
const { spawn } = require('child_process');

// Launch player with IPC enabled
const player = spawn('./resources/player/PlayTorrio.exe', [
  '--ipc',
  '--width', '1920',
  '--height', '1080'
]);

// Send commands via stdin
player.stdin.write(JSON.stringify({
  type: 'load_video',
  id: 'cmd_1',
  data: {
    url: 'https://example.com/video.mp4'
  }
}) + '\n');

// Receive responses via stdout
player.stdout.on('data', (data) => {
  const messages = data.toString().split('\n').filter(line => line.trim());
  messages.forEach(line => {
    try {
      const message = JSON.parse(line);
      console.log('Player message:', message);
    } catch (e) {
      // Ignore non-JSON output
    }
  });
});
```

See [IPC Integration Guide](IPC_INTEGRATION.md) for complete documentation.

## 📖 Documentation

### Core Documentation
- **[IPC Integration Guide](IPC_INTEGRATION.md)** - Complete guide for Electron integration
- **[Bridge Documentation](bridge.md)** - Detailed IPC protocol specification
- **[Build Guide](BUILD_GUIDE.md)** - Instructions for building from source
- **[Release Guide](RELEASE_GUIDE.md)** - Release process and versioning

### Example Code
- **[Electron Integration Example](electron_integration_example.js)** - Ready-to-use JavaScript bridge class
- **[IPC Test Scripts](test_ipc.js)** - Test scripts for IPC functionality
- **[Subtitle Test](test_multiple_subtitles.js)** - Multiple subtitle handling examples

## 🔧 IPC Commands

### Video Control
```javascript
// Load video
{ type: 'load_video', data: { url: 'https://...', startTime: 0 } }

// Playback control
{ type: 'play' }
{ type: 'pause' }
{ type: 'seek', data: { position: 30000 } }

// Volume control
{ type: 'set_volume', data: { volume: 0.5 } }
```

### Subtitle Management
```javascript
// Add external subtitle
{
  type: 'add_external_subtitle',
  data: {
    name: 'English',
    url: 'https://example.com/subtitle.srt',
    comment: 'OpenSubtitles - High Quality'
  }
}

// Select subtitle track
{ type: 'select_subtitle', data: { index: 0 } }
```

### Window Control
```javascript
// Set window size
{ type: 'set_window_size', data: { width: 1920, height: 1080 } }

// Toggle fullscreen
{ type: 'toggle_fullscreen' }

// Get current state
{ type: 'get_state' }
```

### Events
```javascript
// Ready event
{ type: 'event', event: 'ready', data: { version: '1.8.45' } }

// State changed event
{
  type: 'event',
  event: 'state_changed',
  data: {
    hasVideo: true,
    isPlaying: true,
    position: 15000,
    duration: 120000,
    volume: 1.0,
    isFullscreen: false
  }
}
```

## 🛠️ Building from Source

### Prerequisites
- Flutter SDK 3.5.3 or higher
- Platform-specific build tools:
  - **Windows**: Visual Studio 2022 with C++ tools
  - **macOS**: Xcode 14+
  - **Linux**: GCC, CMake, GTK3 development libraries

### Build Commands

```bash
# Clone the repository
git clone https://github.com/ayman708-UX/PlayTorrioPlayerV2.git
cd PlayTorrioPlayerV2

# Install dependencies
flutter pub get

# Build for your platform
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

Output locations:
- **Windows**: `build/windows/x64/runner/Release/`
- **macOS**: `build/macos/Build/Products/Release/`
- **Linux**: `build/linux/x64/release/bundle/`

## 🎯 Use Cases

### 1. Electron App Integration
Perfect for Electron applications that need a powerful video player:
- Torrent streaming clients
- Media center applications
- Video editing tools
- Educational platforms

### 2. Standalone Player
Use as a standalone video player with:
- Drag-and-drop video loading
- URL input for streaming
- Subtitle management
- Playback controls

### 3. Embedded Player
Embed in larger applications via IPC:
- Control from parent process
- Receive real-time state updates
- Manage subtitles programmatically
- Customize window appearance

## 🔒 Security Features

- **Input Validation**: All URLs and parameters are validated
- **HTTPS Support**: Secure streaming over HTTPS
- **Sandboxed Execution**: Runs in isolated process when launched via IPC
- **Error Handling**: Graceful error recovery without crashes
- **Resource Limits**: Automatic cleanup of resources

## 🚀 Performance

- **Hardware Acceleration**: GPU-accelerated video decoding
- **Efficient Streaming**: Automatic retry with exponential backoff
- **Memory Management**: Optimized memory usage for long playback sessions
- **Low Latency**: Minimal delay between commands and execution
- **Smooth Playback**: 60 FPS rendering with vsync

## 🌐 Streaming Support

### Automatic Retry Logic
The player automatically retries failed streaming connections:
- **3 retry attempts** with incremental delays (2s, 4s, 6s)
- **Handles initialization errors** (pos: 0, dur: 0)
- **Works with all HTTP/HTTPS URLs** including localhost
- **No error dialogs** during retry attempts

### Supported Protocols
- HTTP/HTTPS streaming
- Local file playback
- Network share access (SMB, WebDAV)
- Jellyfin/Emby integration

## 📊 Technical Stack

### Core Framework
- **Flutter 3.5.3**: Cross-platform UI framework
- **Dart**: Programming language

### Video Engines
- **Media Kit**: libmpv-based player (primary)
- **FVP**: libmdk-based player (alternative)
- **Video Player**: Flutter's official player (fallback)

### Key Dependencies
- `media_kit`: Media playback framework
- `media_kit_video`: Video rendering
- `window_manager`: Window control
- `provider`: State management
- `shared_preferences`: Settings storage
- `path_provider`: File system access

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style
- Follow Dart style guidelines
- Add comments for complex logic
- Write descriptive commit messages
- Update documentation as needed

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## � A*cknowledgments

Built on top of NipaPlay-Reload by MCDFSteve, customized for PlayTorrio with:
- IPC bridge implementation
- Streaming retry logic
- English UI translation
- Enhanced subtitle management
- Electron integration support

### Third-Party Libraries
- [media_kit](https://pub.dev/packages/media_kit) - Media playback
- [window_manager](https://pub.dev/packages/window_manager) - Window control
- [provider](https://pub.dev/packages/provider) - State management
- And many more (see [pubspec.yaml](pubspec.yaml))

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/ayman708-UX/PlayTorrioPlayerV2/issues)
- **Documentation**: See `/Documentation` folder
- **Examples**: See example files in repository root

## 🗺️ Roadmap

- [ ] WebSocket-based IPC for better performance
- [ ] Picture-in-Picture mode
- [ ] Advanced subtitle styling
- [ ] Playlist support
- [ ] Audio-only mode
- [ ] Video effects and filters
- [ ] Chromecast support
- [ ] Remote control API

## 📈 Version History

### v1.8.45 (Latest)
- Full English UI translation
- Automatic streaming retry logic
- Enhanced subtitle track naming
- Improved error handling
- IPC bridge stability improvements

See [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) for complete version history.

---

<div align="center">

**Built with ❤️ for PlayTorrio**

[Report Bug](https://github.com/ayman708-UX/PlayTorrioPlayerV2/issues) · [Request Feature](https://github.com/ayman708-UX/PlayTorrioPlayerV2/issues) · [Documentation](IPC_INTEGRATION.md)

</div>

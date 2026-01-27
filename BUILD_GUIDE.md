# PlayTorrio Build Guide

This guide explains how to build portable executables for Windows, macOS (universal), and Linux (universal) that can be bundled with your Electron app.

## 🚀 Automated Builds (Recommended)

**Use GitHub Actions for automatic releases!** See [RELEASE_GUIDE.md](RELEASE_GUIDE.md) for details.

Simply push a version tag and get portable builds for all platforms:
```bash
git tag v1.8.13
git push origin v1.8.13
```

GitHub Actions will build and release Windows, macOS (Universal), and Linux versions automatically.

---

## Manual Builds

If you need to build locally:

## Prerequisites

- Flutter SDK installed
- Platform-specific build tools:
  - **Windows**: Visual Studio 2022 with C++ desktop development
  - **macOS**: Xcode (for building on macOS)
  - **Linux**: Standard build tools (`clang`, `cmake`, `ninja-build`, `libgtk-3-dev`)

## Build Commands

### Windows (Portable)

```cmd
flutter clean
flutter build windows --release
```

**Output Location**: `build/windows/x64/runner/Release/`

**Portable Bundle**: Copy the entire `Release` folder containing:
- `PlayTorrio.exe` - Main executable
- `flutter_windows.dll` - Flutter runtime
- `data/` - Flutter assets and resources
- All other DLLs and dependencies

**For Electron Integration**:
```javascript
const playerPath = path.join(__dirname, 'player', 'windows', 'PlayTorrio.exe');
```

---

### macOS (Universal Binary)

```bash
flutter clean
flutter build macos --release
```

**Output Location**: `build/macos/Build/Products/Release/`

**Portable Bundle**: `PlayTorrio.app` (this is a complete app bundle)

The `.app` is a folder structure that macOS treats as a single application. It contains:
- `Contents/MacOS/PlayTorrio` - Executable
- `Contents/Frameworks/` - Flutter framework
- `Contents/Resources/` - Assets

**For Electron Integration**:
```javascript
const playerPath = path.join(__dirname, 'player', 'macos', 'PlayTorrio.app', 'Contents', 'MacOS', 'PlayTorrio');
```

**Note**: The build is already universal (arm64 + x86_64) by default in recent Flutter versions.

---

### Linux (Universal)

```bash
flutter clean
flutter build linux --release
```

**Output Location**: `build/linux/x64/release/bundle/`

**Portable Bundle**: Copy the entire `bundle` folder containing:
- `playtorrio` - Main executable
- `lib/` - Shared libraries
- `data/` - Flutter assets and resources

**For Electron Integration**:
```javascript
const playerPath = path.join(__dirname, 'player', 'linux', 'playtorrio');
```

**Note**: Linux builds are portable across distributions but require GTK3 to be installed on the target system.

---

## Bundling Structure for Electron

Recommended folder structure for your Electron app:

```
your-electron-app/
├── player/
│   ├── windows/
│   │   └── Release/
│   │       ├── PlayTorrio.exe
│   │       ├── flutter_windows.dll
│   │       └── data/
│   ├── macos/
│   │   └── PlayTorrio.app/
│   │       └── Contents/
│   │           ├── MacOS/
│   │           │   └── PlayTorrio
│   │           ├── Frameworks/
│   │           └── Resources/
│   └── linux/
│       ├── playtorrio
│       ├── lib/
│       └── data/
├── node_modules/
├── main.js
└── package.json
```

## Platform Detection in Electron

```javascript
const os = require('os');
const path = require('path');

function getPlayerPath() {
  const platform = os.platform();
  
  switch (platform) {
    case 'win32':
      return path.join(__dirname, 'player', 'windows', 'PlayTorrio.exe');
    case 'darwin':
      return path.join(__dirname, 'player', 'macos', 'PlayTorrio.app', 'Contents', 'MacOS', 'PlayTorrio');
    case 'linux':
      return path.join(__dirname, 'player', 'linux', 'playtorrio');
    default:
      throw new Error(`Unsupported platform: ${platform}`);
  }
}

// Usage
const { spawn } = require('child_process');
const playerPath = getPlayerPath();
const player = spawn(playerPath, ['--ipc']);
```

## IPC Integration

All builds support the same IPC protocol via stdin/stdout. Launch with `--ipc` flag:

```javascript
const player = spawn(playerPath, [
  '--ipc',
  '--url', 'https://example.com/video.mp4',
  '--width', '1280',
  '--height', '720'
]);
```

See `bridge.md` for complete IPC documentation.

## File Sizes (Approximate)

- **Windows**: ~80-100 MB (Release folder)
- **macOS**: ~90-110 MB (PlayTorrio.app)
- **Linux**: ~80-100 MB (bundle folder)

## Testing Builds

### Windows
```cmd
cd build\windows\x64\runner\Release
PlayTorrio.exe --ipc
```

### macOS
```bash
cd build/macos/Build/Products/Release
./PlayTorrio.app/Contents/MacOS/PlayTorrio --ipc
```

### Linux
```bash
cd build/linux/x64/release/bundle
./playtorrio --ipc
```

## Troubleshooting

### Windows
- If missing DLLs, ensure all files in `Release` folder are copied
- Run `flutter doctor` to verify Visual Studio installation

### macOS
- Code signing may be required for distribution
- For development, right-click > Open to bypass Gatekeeper
- Universal binary includes both Intel and Apple Silicon support

### Linux
- Ensure GTK3 is installed: `sudo apt-get install libgtk-3-0`
- Make executable: `chmod +x playtorrio`
- May need additional libraries depending on distribution

## Distribution

For production Electron apps:

1. **Windows**: Include entire `Release` folder in your installer
2. **macOS**: Include `PlayTorrio.app` in your DMG/PKG
3. **Linux**: Include `bundle` folder in your AppImage/DEB/RPM

The player is fully portable and doesn't require installation - just bundle it with your Electron app.

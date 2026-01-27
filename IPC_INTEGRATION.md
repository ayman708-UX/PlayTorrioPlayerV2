# IPC Integration Guide for Electron

This guide explains how to integrate the NipaPlay Flutter player with your Electron application.

## Overview

The Flutter player can be controlled via IPC (Inter-Process Communication) using JSON messages over stdin/stdout. This allows your Electron app to:

- Launch the player at a specific size
- Load video URLs
- Add and manage external subtitles
- Control playback (play, pause, seek)
- Adjust volume
- Receive real-time state updates

## Quick Start

### 1. Build the Flutter Player

```bash
flutter build windows --release
```

The executable will be at: `build/windows/x64/runner/Release/NipaPlay.exe`

### 2. Launch from Electron

```javascript
const FlutterPlayerBridge = require('./electron_integration_example.js');

const player = new FlutterPlayerBridge('./path/to/NipaPlay.exe');

await player.launch({
  url: 'https://example.com/video.mp4',  // Optional: auto-load video
  width: 1920,                            // Optional: window width
  height: 1080,                           // Optional: window height
});
```

### 3. Control the Player

```javascript
// Load a video
await player.loadVideo('https://example.com/video.mp4', 0);

// Play/Pause
await player.play();
await player.pause();

// Seek to position (in milliseconds)
await player.seek(30000); // Seek to 30 seconds

// Set volume (0.0 to 1.0)
await player.setVolume(0.5);

// Add external subtitle
const { index } = await player.addExternalSubtitle('English', 'https://example.com/subtitle.srt');

// Select subtitle (-1 for off, 0+ for subtitle index)
await player.selectSubtitle(index);

// Toggle fullscreen
await player.toggleFullscreen();

// Get current state
const state = await player.getState();
console.log(state);
// {
//   hasVideo: true,
//   isPlaying: true,
//   isPaused: false,
//   position: 30000,
//   duration: 120000,
//   volume: 0.5,
//   isFullscreen: false
// }
```

### 4. Listen to Events

```javascript
// Listen to state changes
player.on('state_changed', (state) => {
  console.log('Position:', state.position);
  console.log('Duration:', state.duration);
  console.log('Is playing:', state.isPlaying);
});

// Listen to ready event
player.once('ready', () => {
  console.log('Player is ready!');
});
```

## Command Line Arguments

You can also launch the player directly with command-line arguments:

```bash
# Launch with IPC enabled
NipaPlay.exe --ipc

# Launch with specific size
NipaPlay.exe --ipc --width 1920 --height 1080

# Launch with video URL
NipaPlay.exe --ipc --url "https://example.com/video.mp4"

# Combine all options
NipaPlay.exe --ipc --width 1920 --height 1080 --url "https://example.com/video.mp4"
```

## Available Commands

### load_video
Load a video URL

```json
{
  "type": "load_video",
  "id": "cmd_1",
  "data": {
    "url": "https://example.com/video.mp4",
    "startTime": 0
  }
}
```

### play
Start playback

```json
{
  "type": "play",
  "id": "cmd_2"
}
```

### pause
Pause playback

```json
{
  "type": "pause",
  "id": "cmd_3"
}
```

### seek
Seek to position (milliseconds)

```json
{
  "type": "seek",
  "id": "cmd_4",
  "data": {
    "position": 30000
  }
}
```

### set_volume
Set volume (0.0 to 1.0)

```json
{
  "type": "set_volume",
  "id": "cmd_5",
  "data": {
    "volume": 0.5
  }
}
```

### add_external_subtitle
Add an external subtitle

```json
{
  "type": "add_external_subtitle",
  "id": "cmd_6",
  "data": {
    "name": "English",
    "url": "https://example.com/subtitle.srt"
  }
}
```

### select_subtitle
Select a subtitle track

```json
{
  "type": "select_subtitle",
  "id": "cmd_7",
  "data": {
    "index": 0
  }
}
```

Note: Use `-1` to turn off subtitles, `0+` for external/built-in subtitle index.

### set_window_size
Set window size

```json
{
  "type": "set_window_size",
  "id": "cmd_8",
  "data": {
    "width": 1920,
    "height": 1080
  }
}
```

### get_state
Get current player state

```json
{
  "type": "get_state",
  "id": "cmd_9"
}
```

### toggle_fullscreen
Toggle fullscreen mode

```json
{
  "type": "toggle_fullscreen",
  "id": "cmd_10"
}
```

## Events

The player sends events to notify your Electron app of state changes:

### ready
Sent when the player is ready to receive commands

```json
{
  "type": "event",
  "event": "ready",
  "data": {
    "version": "1.0.0"
  }
}
```

### state_changed
Sent when the player state changes

```json
{
  "type": "event",
  "event": "state_changed",
  "data": {
    "hasVideo": true,
    "isPlaying": true,
    "isPaused": false,
    "position": 30000,
    "duration": 120000,
    "volume": 0.5,
    "isFullscreen": false
  }
}
```

## Error Handling

Errors are sent as:

```json
{
  "type": "error",
  "code": "error_code",
  "message": "Error description"
}
```

Common error codes:
- `parse_error`: Failed to parse command
- `unknown_command`: Unknown command type
- `invalid_params`: Missing or invalid parameters
- `command_error`: Error executing command
- `subtitle_error`: Failed to load subtitle
- `window_error`: Failed to set window size

## Example Integration

See `electron_integration_example.js` for a complete working example with the `FlutterPlayerBridge` class.

## Tips

1. **Always enable IPC**: Use `--ipc` flag when launching the player
2. **Handle errors**: Always wrap commands in try-catch blocks
3. **Listen to events**: Use `state_changed` event to keep your UI in sync
4. **Clean shutdown**: Call `player.close()` when done to properly terminate the process
5. **Bundle the player**: Include the entire `build/windows/x64/runner/Release/` folder with your Electron app

## Bundling with Electron

To bundle the Flutter player with your Electron app:

1. Copy the entire `build/windows/x64/runner/Release/` folder to your Electron app's resources
2. Reference the executable path relative to your app:

```javascript
const path = require('path');
const { app } = require('electron');

const playerPath = path.join(
  process.resourcesPath,
  'player',
  'NipaPlay.exe'
);

const player = new FlutterPlayerBridge(playerPath);
```

3. In your `package.json` or build config, include the player folder:

```json
{
  "build": {
    "extraResources": [
      {
        "from": "player/",
        "to": "player/"
      }
    ]
  }
}
```

## Support

For issues or questions, please refer to the main README or open an issue on GitHub.

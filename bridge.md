# IPC Bridge Documentation

Complete guide for integrating the PlayTorrio video player with Electron or any other application via IPC (Inter-Process Communication).

## Overview

The IPC bridge allows you to control the PlayTorrio video player from external applications using JSON messages over stdin/stdout. This is a cross-platform solution that works on Windows, macOS, and Linux.

## Architecture

```
┌─────────────────────┐         JSON over          ┌──────────────────────┐
│                     │      stdin/stdout          │                      │
│  Electron App       │◄──────────────────────────►│  PlayTorrio Player   │
│  (or any app)       │                            │  (Flutter)           │
│                     │                            │                      │
└─────────────────────┘                            └──────────────────────┘
```

### Communication Flow

1. **Commands**: Your app sends JSON commands to the player via stdin
2. **Responses**: Player sends JSON responses back via stdout
3. **Events**: Player broadcasts state changes and events via stdout

## Starting the Player

### Command Line Arguments

```bash
# Basic usage
./PlayTorrio.exe --ipc

# With initial video
./PlayTorrio.exe --ipc --url "https://example.com/video.mp4"

# With custom window size
./PlayTorrio.exe --ipc --width 1920 --height 1080

# All together
./PlayTorrio.exe --ipc --url "https://example.com/video.mp4" --width 1280 --height 720
```

### Available Arguments

| Argument | Type | Description | Example |
|----------|------|-------------|---------|
| `--ipc` | flag | Enable IPC mode | `--ipc` |
| `--url` | string | Initial video URL to load | `--url "https://example.com/video.mp4"` |
| `--width` | number | Window width in pixels | `--width 1280` |
| `--height` | number | Window height in pixels | `--height 720` |

## Message Format

All messages are JSON objects sent as single lines (newline-terminated).

### Command Format (Your App → Player)

```json
{
  "type": "command_name",
  "id": "unique_id",
  "data": {
    "param1": "value1",
    "param2": "value2"
  }
}
```

- `type`: Command name (required)
- `id`: Unique identifier for tracking responses (optional but recommended)
- `data`: Command parameters (optional, depends on command)

### Response Format (Player → Your App)

```json
{
  "type": "response",
  "id": "unique_id",
  "data": {
    "result": "value"
  }
}
```

### Event Format (Player → Your App)

```json
{
  "type": "event",
  "event": "event_name",
  "data": {
    "key": "value"
  }
}
```

### Error Format (Player → Your App)

```json
{
  "type": "error",
  "error": "error_code",
  "message": "Error description"
}
```

## Available Commands

### 1. Load Video

Load a video from URL.

**Command:**
```json
{
  "type": "load_video",
  "id": "cmd_1",
  "data": {
    "url": "https://example.com/video.mp4",
    "startTime": 5000
  }
}
```

**Parameters:**
- `url` (string, required): Video URL (http/https)
- `startTime` (number, optional): Start position in milliseconds

**Response:**
```json
{
  "type": "response",
  "id": "cmd_1",
  "data": {
    "success": true
  }
}
```

---

### 2. Play

Start or resume playback.

**Command:**
```json
{
  "type": "play",
  "id": "cmd_2"
}
```

**Response:**
```json
{
  "type": "response",
  "id": "cmd_2",
  "data": {
    "success": true
  }
}
```

---

### 3. Pause

Pause playback.

**Command:**
```json
{
  "type": "pause",
  "id": "cmd_3"
}
```

**Response:**
```json
{
  "type": "response",
  "id": "cmd_3",
  "data": {
    "success": true
  }
}
```

---

### 4. Seek

Seek to a specific position.

**Command:**
```json
{
  "type": "seek",
  "id": "cmd_4",
  "data": {
    "position": 30000
  }
}
```

**Parameters:**
- `position` (number, required): Position in milliseconds

**Response:**
```json
{
  "type": "response",
  "id": "cmd_4",
  "data": {
    "success": true
  }
}
```

---

### 5. Set Volume

Change the volume level.

**Command:**
```json
{
  "type": "set_volume",
  "id": "cmd_5",
  "data": {
    "volume": 0.5
  }
}
```

**Parameters:**
- `volume` (number, required): Volume level (0.0 to 1.0)

**Response:**
```json
{
  "type": "response",
  "id": "cmd_5",
  "data": {
    "success": true
  }
}
```

---

### 6. Add External Subtitle

Add an external subtitle file. You can add multiple external subtitles by calling this command multiple times.

**Command:**
```json
{
  "type": "add_external_subtitle",
  "id": "cmd_6",
  "data": {
    "name": "English Subtitles",
    "url": "https://example.com/subtitles.srt",
    "comment": "OpenSubtitles - High Quality"
  }
}
```

**Parameters:**
- `name` (string, required): Display name for the subtitle
- `url` (string, required): Subtitle file URL
- `comment` (string, optional): Additional description or source information (e.g., "OpenSubtitles", "Manual Upload", "Community Contributed")

**Response:**
```json
{
  "type": "response",
  "id": "cmd_6",
  "data": {
    "success": true,
    "index": 0
  }
}
```

**Note:** You can add multiple external subtitles. Each call adds a new subtitle and returns its index. The index is used with `select_subtitle` to activate a specific subtitle.

**Example - Adding Multiple Subtitles:**
```javascript
// Add English subtitles with comment
await player.addExternalSubtitle('English', 'https://example.com/en.srt', 'OpenSubtitles - Official');
// Returns: { success: true, index: 0 }

// Add Spanish subtitles with comment
await player.addExternalSubtitle('Spanish', 'https://example.com/es.srt', 'Community Contributed');
// Returns: { success: true, index: 1 }

// Add French subtitles without comment
await player.addExternalSubtitle('French', 'https://example.com/fr.srt');
// Returns: { success: true, index: 2 }
```

**Note:** The comment parameter is displayed in the subtitle menu below the subtitle name, helping users identify the source or quality of each subtitle track.

---

### 7. Select Subtitle

Select a subtitle track.

**Command:**
```json
{
  "type": "select_subtitle",
  "id": "cmd_7",
  "data": {
    "index": 0
  }
}
```

**Parameters:**
- `index` (number, required): Subtitle index (-1 for off, 0+ for external, higher for built-in)

**Response:**
```json
{
  "type": "response",
  "id": "cmd_7",
  "data": {
    "success": true
  }
}
```

---

### 8. Set Window Size

Change the window size.

**Command:**
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

**Parameters:**
- `width` (number, required): Window width in pixels
- `height` (number, required): Window height in pixels

**Response:**
```json
{
  "type": "response",
  "id": "cmd_8",
  "data": {
    "success": true
  }
}
```

---

### 9. Get State

Get the current player state.

**Command:**
```json
{
  "type": "get_state",
  "id": "cmd_9"
}
```

**Response:**
```json
{
  "type": "response",
  "id": "cmd_9",
  "data": {
    "hasVideo": true,
    "isPlaying": true,
    "isPaused": false,
    "position": 15000,
    "duration": 120000,
    "volume": 1.0,
    "isFullscreen": false,
    "externalSubtitles": [
      { "name": "English", "url": "https://example.com/en.srt", "comment": "OpenSubtitles - Official" },
      { "name": "Spanish", "url": "https://example.com/es.srt", "comment": "Community Contributed" }
    ]
  }
}
```

---

### 10. Toggle Fullscreen

Toggle fullscreen mode.

**Command:**
```json
{
  "type": "toggle_fullscreen",
  "id": "cmd_10"
}
```

**Response:**
```json
{
  "type": "response",
  "id": "cmd_10",
  "data": {
    "success": true
  }
}
```

## Events

The player automatically sends events when its state changes.

### Ready Event

Sent when the player is initialized and ready to receive commands.

```json
{
  "type": "event",
  "event": "ready",
  "data": {
    "version": "1.0.0"
  }
}
```

### State Changed Event

Sent whenever the player state changes (playing, paused, position update, etc.).

```json
{
  "type": "event",
  "event": "state_changed",
  "data": {
    "hasVideo": true,
    "isPlaying": true,
    "isPaused": false,
    "position": 15000,
    "duration": 120000,
    "volume": 1.0,
    "isFullscreen": false
  }
}
```

**State Properties:**
- `hasVideo` (boolean): Whether a video is loaded
- `isPlaying` (boolean): Whether video is currently playing
- `isPaused` (boolean): Whether video is paused
- `position` (number): Current playback position in milliseconds
- `duration` (number): Total video duration in milliseconds
- `volume` (number): Current volume level (0.0 to 1.0)
- `isFullscreen` (boolean): Whether player is in fullscreen mode
- `externalSubtitles` (array): List of added external subtitles with name, url, and optional comment

## Error Handling

When an error occurs, the player sends an error message:

```json
{
  "type": "error",
  "error": "error_code",
  "message": "Detailed error description"
}
```

**Common Error Codes:**
- `unknown_command`: Command type not recognized
- `invalid_params`: Missing or invalid parameters
- `command_error`: Error executing command
- `load_error`: Failed to load video
- `subtitle_error`: Failed to load subtitle
- `window_error`: Failed to change window size

## Implementation Examples

### Node.js / Electron

```javascript
const { spawn } = require('child_process');
const path = require('path');

class PlayTorrioBridge {
  constructor(playerPath) {
    this.playerPath = playerPath;
    this.player = null;
    this.messageId = 0;
    this.pendingCommands = new Map();
    this.eventHandlers = new Map();
  }

  start(options = {}) {
    const args = ['--ipc'];
    
    if (options.url) args.push('--url', options.url);
    if (options.width) args.push('--width', options.width.toString());
    if (options.height) args.push('--height', options.height.toString());

    this.player = spawn(this.playerPath, args);

    this.player.stdout.on('data', (data) => {
      const lines = data.toString().split('\n').filter(line => line.trim());
      lines.forEach(line => {
        try {
          const message = JSON.parse(line);
          this.handleMessage(message);
        } catch (e) {
          // Ignore non-JSON output (debug logs, etc.)
        }
      });
    });

    this.player.stderr.on('data', (data) => {
      console.error('Player error:', data.toString());
    });

    this.player.on('close', (code) => {
      console.log(`Player exited with code ${code}`);
    });

    return new Promise((resolve) => {
      this.once('ready', () => resolve());
    });
  }

  handleMessage(message) {
    if (message.type === 'response' && message.id) {
      const handler = this.pendingCommands.get(message.id);
      if (handler) {
        handler.resolve(message.data);
        this.pendingCommands.delete(message.id);
      }
    } else if (message.type === 'error') {
      const handler = this.pendingCommands.get(message.id);
      if (handler) {
        handler.reject(new Error(message.message));
        this.pendingCommands.delete(message.id);
      }
      this.emit('error', message);
    } else if (message.type === 'event') {
      this.emit(message.event, message.data);
    }
  }

  sendCommand(type, data = {}) {
    const id = `cmd_${++this.messageId}`;
    const command = JSON.stringify({ type, id, data });
    
    return new Promise((resolve, reject) => {
      this.pendingCommands.set(id, { resolve, reject });
      this.player.stdin.write(command + '\n');
      
      // Timeout after 30 seconds
      setTimeout(() => {
        if (this.pendingCommands.has(id)) {
          this.pendingCommands.delete(id);
          reject(new Error('Command timeout'));
        }
      }, 30000);
    });
  }

  // Event emitter methods
  on(event, handler) {
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
    this.eventHandlers.get(event).push(handler);
  }

  once(event, handler) {
    const wrapper = (data) => {
      handler(data);
      this.off(event, wrapper);
    };
    this.on(event, wrapper);
  }

  off(event, handler) {
    const handlers = this.eventHandlers.get(event);
    if (handlers) {
      const index = handlers.indexOf(handler);
      if (index !== -1) {
        handlers.splice(index, 1);
      }
    }
  }

  emit(event, data) {
    const handlers = this.eventHandlers.get(event);
    if (handlers) {
      handlers.forEach(handler => handler(data));
    }
  }

  // Command methods
  async loadVideo(url, startTime = 0) {
    return this.sendCommand('load_video', { url, startTime });
  }

  async play() {
    return this.sendCommand('play');
  }

  async pause() {
    return this.sendCommand('pause');
  }

  async seek(position) {
    return this.sendCommand('seek', { position });
  }

  async setVolume(volume) {
    return this.sendCommand('set_volume', { volume });
  }

  async addExternalSubtitle(name, url) {
    return this.sendCommand('add_external_subtitle', { name, url });
  }

  async selectSubtitle(index) {
    return this.sendCommand('select_subtitle', { index });
  }

  async setWindowSize(width, height) {
    return this.sendCommand('set_window_size', { width, height });
  }

  async getState() {
    return this.sendCommand('get_state');
  }

  async toggleFullscreen() {
    return this.sendCommand('toggle_fullscreen');
  }

  stop() {
    if (this.player) {
      this.player.kill();
      this.player = null;
    }
  }
}

// Usage example
async function main() {
  const player = new PlayTorrioBridge('./PlayTorrio.exe');
  
  // Listen to events
  player.on('state_changed', (state) => {
    console.log('Player state:', state);
  });

  player.on('error', (error) => {
    console.error('Player error:', error);
  });

  // Start player
  await player.start({
    width: 1280,
    height: 720
  });

  console.log('Player ready!');

  // Load and play video
  await player.loadVideo('https://example.com/video.mp4');
  await player.play();

  // Add multiple external subtitles
  await player.addExternalSubtitle('English', 'https://example.com/en.srt');
  await player.addExternalSubtitle('Spanish', 'https://example.com/es.srt');
  await player.addExternalSubtitle('French', 'https://example.com/fr.srt');
  
  // Select the Spanish subtitle (index 1)
  await player.selectSubtitle(1);

  // Control playback
  setTimeout(() => player.pause(), 5000);
  setTimeout(() => player.seek(30000), 10000);
  setTimeout(() => player.setVolume(0.5), 15000);
}

main().catch(console.error);
```

### Python

```python
import subprocess
import json
import threading
import queue

class PlayTorrioBridge:
    def __init__(self, player_path):
        self.player_path = player_path
        self.process = None
        self.message_id = 0
        self.pending_commands = {}
        self.event_handlers = {}
        self.output_queue = queue.Queue()
        
    def start(self, url=None, width=None, height=None):
        args = [self.player_path, '--ipc']
        
        if url:
            args.extend(['--url', url])
        if width:
            args.extend(['--width', str(width)])
        if height:
            args.extend(['--height', str(height)])
        
        self.process = subprocess.Popen(
            args,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        # Start output reader thread
        threading.Thread(target=self._read_output, daemon=True).start()
        threading.Thread(target=self._process_messages, daemon=True).start()
        
    def _read_output(self):
        for line in self.process.stdout:
            line = line.strip()
            if line:
                try:
                    message = json.loads(line)
                    self.output_queue.put(message)
                except json.JSONDecodeError:
                    pass  # Ignore non-JSON output
                    
    def _process_messages(self):
        while True:
            message = self.output_queue.get()
            
            if message['type'] == 'response' and 'id' in message:
                msg_id = message['id']
                if msg_id in self.pending_commands:
                    self.pending_commands[msg_id].put(message['data'])
                    
            elif message['type'] == 'error':
                msg_id = message.get('id')
                if msg_id and msg_id in self.pending_commands:
                    self.pending_commands[msg_id].put(Exception(message['message']))
                self._emit('error', message)
                
            elif message['type'] == 'event':
                self._emit(message['event'], message['data'])
                
    def _emit(self, event, data):
        if event in self.event_handlers:
            for handler in self.event_handlers[event]:
                handler(data)
                
    def on(self, event, handler):
        if event not in self.event_handlers:
            self.event_handlers[event] = []
        self.event_handlers[event].append(handler)
        
    def send_command(self, cmd_type, data=None):
        self.message_id += 1
        msg_id = f'cmd_{self.message_id}'
        
        command = {
            'type': cmd_type,
            'id': msg_id
        }
        if data:
            command['data'] = data
            
        result_queue = queue.Queue()
        self.pending_commands[msg_id] = result_queue
        
        self.process.stdin.write(json.dumps(command) + '\n')
        self.process.stdin.flush()
        
        result = result_queue.get(timeout=30)
        del self.pending_commands[msg_id]
        
        if isinstance(result, Exception):
            raise result
        return result
        
    def load_video(self, url, start_time=0):
        return self.send_command('load_video', {'url': url, 'startTime': start_time})
        
    def play(self):
        return self.send_command('play')
        
    def pause(self):
        return self.send_command('pause')
        
    def seek(self, position):
        return self.send_command('seek', {'position': position})
        
    def set_volume(self, volume):
        return self.send_command('set_volume', {'volume': volume})
        
    def get_state(self):
        return self.send_command('get_state')
        
    def stop(self):
        if self.process:
            self.process.terminate()
            self.process = None

# Usage
player = PlayTorrioBridge('./PlayTorrio.exe')

def on_state_changed(state):
    print(f"Player state: {state}")

player.on('state_changed', on_state_changed)
player.start(width=1280, height=720)

player.load_video('https://example.com/video.mp4')
player.play()

# Add multiple external subtitles
player.send_command('add_external_subtitle', {'name': 'English', 'url': 'https://example.com/en.srt'})
player.send_command('add_external_subtitle', {'name': 'Spanish', 'url': 'https://example.com/es.srt'})
player.send_command('add_external_subtitle', {'name': 'French', 'url': 'https://example.com/fr.srt'})

# Select Spanish subtitle (index 1)
player.send_command('select_subtitle', {'index': 1})
```

## Cross-Platform Considerations

### Windows
- Use `.exe` extension: `PlayTorrio.exe`
- Path separators: Use `\\` or `/`
- Process spawning works with `spawn()` in Node.js

### macOS
- Use `.app` bundle or binary directly
- May need to handle app bundle structure
- Ensure executable permissions: `chmod +x PlayTorrio`

### Linux
- Ensure executable permissions: `chmod +x PlayTorrio`
- May need to install dependencies (see main README)
- Path separators: Use `/`

## Best Practices

1. **Always handle errors**: Wrap commands in try-catch blocks
2. **Use unique IDs**: Generate unique IDs for each command to track responses
3. **Listen to events**: Subscribe to `state_changed` events for real-time updates
4. **Graceful shutdown**: Always call `stop()` or kill the process when done
5. **Timeout handling**: Implement timeouts for commands that might hang
6. **Buffer management**: Handle stdout buffering properly to avoid message loss
7. **JSON parsing**: Ignore non-JSON output (debug logs, warnings)

## Troubleshooting

### Player doesn't start
- Check if the player executable exists and has execute permissions
- Verify the path is correct
- Check if required dependencies are installed

### No response to commands
- Ensure `--ipc` flag is passed when starting the player
- Check if stdin/stdout are properly connected
- Verify JSON format is correct (newline-terminated)

### Events not received
- Make sure you're reading stdout continuously
- Check if stdout buffering is disabled
- Verify event handlers are registered before starting

### Video won't load
- Check if the URL is accessible
- Verify the video format is supported
- Look for error events with details

## Security Considerations

1. **Input validation**: Always validate URLs and parameters before sending to player
2. **Path sanitization**: Sanitize file paths to prevent directory traversal
3. **Resource limits**: Monitor player resource usage
4. **Sandboxing**: Consider running the player in a sandboxed environment
5. **HTTPS only**: Prefer HTTPS URLs for video content

## Performance Tips

1. **Batch commands**: Send multiple commands together when possible
2. **Throttle events**: Debounce state_changed events if they're too frequent
3. **Async operations**: Use async/await for better performance
4. **Memory management**: Monitor memory usage for long-running sessions
5. **Process cleanup**: Always clean up processes on exit

## License

This IPC bridge is part of the PlayTorrio project. See LICENSE file for details.

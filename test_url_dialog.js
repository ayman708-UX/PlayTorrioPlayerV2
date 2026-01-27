const { spawn } = require('child_process');
const path = require('path');

// Path to the built executable
const playerPath = path.join(__dirname, 'build', 'windows', 'x64', 'runner', 'Release', 'PlayTorrio.exe');

console.log('Testing URL dialog with pre-filled URL...');

// Start the player with IPC enabled and a video URL
const player = spawn(playerPath, [
  '--ipc',
  '--url', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  '--width', '1280',
  '--height', '720'
]);

let messageId = 0;

// Helper to send commands
function sendCommand(type, data = {}) {
  const id = `cmd_${++messageId}`;
  const command = JSON.stringify({ type, id, data });
  console.log('→ Sending:', command);
  player.stdin.write(command + '\n');
  return id;
}

// Listen to stdout
player.stdout.on('data', (data) => {
  const lines = data.toString().split('\n').filter(line => line.trim());
  lines.forEach(line => {
    try {
      const message = JSON.parse(line);
      console.log('← Received:', JSON.stringify(message, null, 2));
    } catch (e) {
      // Ignore non-JSON output
    }
  });
});

// Listen to stderr
player.stderr.on('data', (data) => {
  console.error('Error:', data.toString());
});

// Handle process exit
player.on('close', (code) => {
  console.log(`Player exited with code ${code}`);
  process.exit(code);
});

// Wait for player to be ready
setTimeout(() => {
  console.log('\n=== Player should now be running with video loaded ===');
  console.log('Instructions:');
  console.log('1. Click the link icon (🔗) in the bottom controls');
  console.log('2. The URL dialog should show the current video URL');
  console.log('3. You can copy it, modify it, or load a different video');
  console.log('\nPress Ctrl+C to exit when done testing.\n');
}, 3000);

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\nShutting down player...');
  player.kill();
  process.exit(0);
});

const { spawn } = require('child_process');
const path = require('path');

// Path to the built executable
const playerPath = path.join(__dirname, 'build', 'windows', 'x64', 'runner', 'Release', 'PlayTorrio.exe');

console.log('Starting PlayTorrio with IPC...');

// Start the player with IPC enabled
const player = spawn(playerPath, ['--ipc', '--width', '1280', '--height', '720']);

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
      console.log('← Raw output:', line);
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

// Wait a bit for the player to start, then send test commands
setTimeout(() => {
  console.log('\n=== Testing IPC Commands ===\n');
  
  // Test 1: Get initial state
  console.log('Test 1: Get State');
  sendCommand('get_state');
  
  setTimeout(() => {
    // Test 2: Load a video (using a sample URL - replace with your own)
    console.log('\nTest 2: Load Video');
    sendCommand('load_video', {
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
    });
    
    setTimeout(() => {
      // Test 3: Play
      console.log('\nTest 3: Play');
      sendCommand('play');
      
      setTimeout(() => {
        // Test 4: Get state while playing
        console.log('\nTest 4: Get State (while playing)');
        sendCommand('get_state');
        
        setTimeout(() => {
          // Test 5: Pause
          console.log('\nTest 5: Pause');
          sendCommand('pause');
          
          setTimeout(() => {
            // Test 6: Seek
            console.log('\nTest 6: Seek to 10 seconds');
            sendCommand('seek', { position: 10000 });
            
            setTimeout(() => {
              // Test 7: Set volume
              console.log('\nTest 7: Set Volume to 50%');
              sendCommand('set_volume', { volume: 0.5 });
              
              setTimeout(() => {
                console.log('\n=== All tests completed ===');
                console.log('Player is still running. Press Ctrl+C to exit.');
              }, 1000);
            }, 1000);
          }, 1000);
        }, 2000);
      }, 1000);
    }, 3000);
  }, 2000);
}, 2000);

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\nShutting down player...');
  player.kill();
  process.exit(0);
});

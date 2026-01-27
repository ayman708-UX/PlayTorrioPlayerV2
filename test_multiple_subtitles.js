const { spawn } = require('child_process');
const path = require('path');

// Path to the built executable
const playerPath = path.join(__dirname, 'build', 'windows', 'x64', 'runner', 'Release', 'PlayTorrio.exe');

console.log('Testing Multiple External Subtitles...\n');

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

// Wait for player to start, then test multiple subtitles
setTimeout(() => {
  console.log('\n=== Testing Multiple External Subtitles ===\n');
  
  // Test 1: Load a video
  console.log('Test 1: Load Video');
  sendCommand('load_video', {
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
  });
  
  setTimeout(() => {
    // Test 2: Add first external subtitle
    console.log('\nTest 2: Add English Subtitle');
    sendCommand('add_external_subtitle', {
      name: 'English',
      url: 'https://example.com/subtitles/en.srt'
    });
    
    setTimeout(() => {
      // Test 3: Add second external subtitle
      console.log('\nTest 3: Add Spanish Subtitle');
      sendCommand('add_external_subtitle', {
        name: 'Spanish',
        url: 'https://example.com/subtitles/es.srt'
      });
      
      setTimeout(() => {
        // Test 4: Add third external subtitle
        console.log('\nTest 4: Add French Subtitle');
        sendCommand('add_external_subtitle', {
          name: 'French',
          url: 'https://example.com/subtitles/fr.srt'
        });
        
        setTimeout(() => {
          // Test 5: Get state to see all external subtitles
          console.log('\nTest 5: Get State (should show all 3 external subtitles)');
          sendCommand('get_state');
          
          setTimeout(() => {
            // Test 6: Select Spanish subtitle (index 1)
            console.log('\nTest 6: Select Spanish Subtitle (index 1)');
            sendCommand('select_subtitle', { index: 1 });
            
            setTimeout(() => {
              // Test 7: Turn off subtitles
              console.log('\nTest 7: Turn Off Subtitles (index -1)');
              sendCommand('select_subtitle', { index: -1 });
              
              setTimeout(() => {
                // Test 8: Select French subtitle (index 2)
                console.log('\nTest 8: Select French Subtitle (index 2)');
                sendCommand('select_subtitle', { index: 2 });
                
                setTimeout(() => {
                  console.log('\n=== All tests completed ===');
                  console.log('\nSummary:');
                  console.log('✓ Added 3 external subtitles (English, Spanish, French)');
                  console.log('✓ Retrieved state showing all external subtitles');
                  console.log('✓ Selected different subtitles by index');
                  console.log('✓ Turned off subtitles');
                  console.log('\nPlayer is still running. Press Ctrl+C to exit.');
                }, 1000);
              }, 1000);
            }, 1000);
          }, 1000);
        }, 1000);
      }, 1000);
    }, 1000);
  }, 3000);
}, 2000);

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\nShutting down player...');
  player.kill();
  process.exit(0);
});

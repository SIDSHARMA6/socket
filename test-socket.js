const io = require('socket.io-client');

console.log('🔌 Connecting to Socket.IO server at http://localhost:1337...');

const socket = io('http://localhost:1337', {
  transports: ['polling', 'websocket'],
  autoConnect: true,
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionAttempts: 3
});

socket.on('connect', () => {
  console.log('✅ Socket connected! ID:', socket.id);
  
  // Test sending a message
  console.log('📤 Sending test message...');
  socket.emit('sendMessage', {
    text: 'Hello from terminal test!',
    sender: 4,
    receiver: 1
  });
});

socket.on('connect_error', (error) => {
  console.error('❌ Connection error:', error.message);
});

socket.on('disconnect', () => {
  console.log('⚠️ Socket disconnected');
});

// Listen for messages
socket.on('message-4', (data) => {
  console.log('📨 Received message for user 4:', data);
});

socket.on('message-1', (data) => {
  console.log('📨 Received message for user 1:', data);
});

// Keep the script running for 10 seconds
setTimeout(() => {
  console.log('⏱️ Test complete, disconnecting...');
  socket.disconnect();
  process.exit(0);
}, 10000);

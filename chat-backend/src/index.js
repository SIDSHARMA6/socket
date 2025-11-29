"use strict";

module.exports = {
  async bootstrap({ strapi }) {
    const io = require("socket.io")(strapi.server.httpServer, {
      cors: { 
        origin: "*",
        methods: ["GET", "POST"],
        credentials: true
      },
      transports: ['websocket', 'polling'],
      allowEIO3: true,
      pingTimeout: 60000,
      pingInterval: 25000
    });

    console.log("=== SOCKET.IO SERVER STARTED ===");

    // Store user socket mappings
    const userSockets = new Map();

    // Middleware for authentication
    io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token;
        if (!token) {
          return next(new Error('Authentication error'));
        }

        // Verify JWT token
        const decoded = await strapi.plugins['users-permissions'].services.jwt.verify(token);
        socket.userId = decoded.id;
        console.log(`User ${decoded.id} authenticated`);
        next();
      } catch (error) {
        console.error('Socket authentication failed:', error);
        next(new Error('Authentication error'));
      }
    });

    io.on("connection", (socket) => {
      console.log(`✅ User ${socket.userId} connected (Socket: ${socket.id})`);
      
      // Store user-socket mapping
      userSockets.set(socket.userId, socket.id);
      
      // Broadcast online status
      io.emit('userOnline', { userId: socket.userId });

      // Join user's personal room
      socket.join(`user-${socket.userId}`);

      // Handle sending messages
      socket.on("sendMessage", async (data) => {
        console.log(`📨 Message from User ${socket.userId}:`, data);

        try {
          // Validate data
          if (!data.text || !data.receiver) {
            socket.emit('messageError', { error: 'Invalid message data' });
            return;
          }

          // Save to database
          const message = await strapi.entityService.create("api::message.message", {
            data: {
              text: data.text,
              sender: socket.userId,
              receiver: data.receiver,
            },
          });

          // Populate sender and receiver
          const populatedMessage = await strapi.entityService.findOne(
            "api::message.message",
            message.id,
            { populate: ['sender', 'receiver'] }
          );

          // Emit to sender (confirmation)
          socket.emit('messageSent', {
            ...populatedMessage,
            tempId: data.tempId, // For client-side matching
            status: 'sent'
          });

          // Emit to receiver (if online)
          const receiverSocketId = userSockets.get(data.receiver);
          if (receiverSocketId) {
            io.to(receiverSocketId).emit('newMessage', populatedMessage);
            
            // Send delivery confirmation to sender
            socket.emit('messageDelivered', {
              messageId: message.id,
              tempId: data.tempId
            });
          }

          console.log(`✅ Message ${message.id} sent successfully`);
        } catch (error) {
          console.error('❌ Error sending message:', error);
          socket.emit('messageError', { 
            error: 'Failed to send message',
            tempId: data.tempId 
          });
        }
      });

      // Handle typing indicators
      socket.on("typing", (data) => {
        const receiverSocketId = userSockets.get(data.receiver);
        if (receiverSocketId) {
          io.to(receiverSocketId).emit('userTyping', {
            userId: socket.userId,
            isTyping: data.isTyping
          });
        }
      });

      // Handle message read receipts
      socket.on("messageRead", async (data) => {
        try {
          // Update message as read in database if needed
          const senderSocketId = userSockets.get(data.senderId);
          if (senderSocketId) {
            io.to(senderSocketId).emit('messageRead', {
              messageId: data.messageId,
              readBy: socket.userId
            });
          }
        } catch (error) {
          console.error('Error marking message as read:', error);
        }
      });

      // Handle disconnect
      socket.on("disconnect", () => {
        console.log(`❌ User ${socket.userId} disconnected`);
        userSockets.delete(socket.userId);
        
        // Broadcast offline status
        io.emit('userOffline', { userId: socket.userId });
      });
    });

    strapi.io = io;
    strapi.userSockets = userSockets;
  }
};

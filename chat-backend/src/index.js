"use strict";

module.exports = {
  async bootstrap({ strapi }) {
    const io = require("socket.io")(strapi.server.httpServer, {
      cors: { origin: "*" }
    });

    console.log("=== SOCKET.IO SERVER STARTED ===");

    io.on("connection", (socket) => {
      console.log("=== NEW SOCKET CONNECTION ===");
      console.log("Socket ID:", socket.id);
      console.log("Total connections:", io.engine.clientsCount);

      socket.on("sendMessage", async (data) => {
        console.log("=== RECEIVED MESSAGE ===");
        console.log("Data:", data);
        console.log("Text:", data.text);
        console.log("Sender:", data.sender);
        console.log("Receiver:", data.receiver);

        try {
          // Save to Strapi DB
          console.log("Saving to database...");
          const message = await strapi.entityService.create("api::message.message", {
            data: {
              text: data.text,
              sender: data.sender,
              receiver: data.receiver,
            },
          });
          console.log("Message saved with ID:", message.id);

          // Populate sender and receiver
          console.log("Populating sender and receiver...");
          const populatedMessage = await strapi.entityService.findOne(
            "api::message.message",
            message.id,
            { populate: ['sender', 'receiver'] }
          );
          console.log("Populated message:", JSON.stringify(populatedMessage, null, 2));

          // Emit to sender and receiver only
          const senderChannel = `message-${data.sender}`;
          const receiverChannel = `message-${data.receiver}`;
          
          console.log("Emitting to channels:");
          console.log("  - Sender channel:", senderChannel);
          console.log("  - Receiver channel:", receiverChannel);
          
          io.emit(senderChannel, populatedMessage);
          io.emit(receiverChannel, populatedMessage);
          
          console.log("✅ Message broadcast successfully");
        } catch (error) {
          console.error("❌ Error sending message:", error);
          console.error("Error details:", error.message);
          console.error("Stack:", error.stack);
        }
      });

      socket.on("disconnect", () => {
        console.log("=== SOCKET DISCONNECTED ===");
        console.log("Socket ID:", socket.id);
      });
    });

    strapi.io = io;
  }
};

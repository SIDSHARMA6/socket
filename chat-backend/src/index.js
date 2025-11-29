"use strict";

module.exports = {
  async bootstrap({ strapi }) {
    const io = require("socket.io")(strapi.server.httpServer, {
      cors: { origin: "*" }
    });

    console.log("=== SOCKET.IO SERVER STARTED ===");

    io.on("connection", (socket) => {
      console.log("✅ Socket connected:", socket.id);

      socket.on("sendMessage", async (data) => {
        console.log("📨 Received message:", data);

        try {
          // Save to database
          const message = await strapi.entityService.create("api::message.message", {
            data: {
              text: data.text,
              sender: data.sender,
              receiver: data.receiver,
            },
          });

          // Populate sender and receiver
          const populated = await strapi.entityService.findOne(
            "api::message.message",
            message.id,
            { populate: ['sender', 'receiver'] }
          );

          console.log("Saved message:", populated);

          // Emit to both users
          io.emit(`message-${data.sender}`, populated);
          io.emit(`message-${data.receiver}`, populated);

          console.log("✅ Message broadcast to both users");
        } catch (error) {
          console.error("❌ Error:", error);
        }
      });

      socket.on("disconnect", () => {
        console.log("❌ Socket disconnected:", socket.id);
      });
    });

    strapi.io = io;
  }
};

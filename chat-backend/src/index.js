"use strict";

module.exports = {
  async bootstrap({ strapi }) {
    const io = require("socket.io")(strapi.server.httpServer, {
      cors: { origin: "*" }
    });

    io.on("connection", (socket) => {
      console.log("Socket Connected:", socket.id);

      socket.on("sendMessage", async (data) => {
        try {
          // Save to Strapi DB
          const message = await strapi.entityService.create("api::message.message", {
            data: {
              text: data.text,
              sender: data.sender,
              receiver: data.receiver,
            },
          });

          // Populate sender and receiver
          const populatedMessage = await strapi.entityService.findOne(
            "api::message.message",
            message.id,
            { populate: ['sender', 'receiver'] }
          );

          // Emit to sender and receiver only
          io.emit(`message-${data.sender}`, populatedMessage);
          io.emit(`message-${data.receiver}`, populatedMessage);
        } catch (error) {
          console.error("Error sending message:", error);
        }
      });
    });

    strapi.io = io;
  }
};

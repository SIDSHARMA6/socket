'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::message.message', ({ strapi }) => ({
  async find(ctx) {
    console.log("=== CUSTOM FIND CONTROLLER ===");
    const user = ctx.state.user;
    console.log("User ID:", user?.id);
    
    if (!user) {
      console.log("ERROR: No user authenticated");
      return ctx.unauthorized('You must be logged in');
    }

    // Get messages where user is sender or receiver
    console.log("Fetching messages for user:", user.id);
    const messages = await strapi.entityService.findMany('api::message.message', {
      filters: {
        $or: [
          { sender: user.id },
          { receiver: user.id }
        ]
      },
      populate: ['sender', 'receiver'],
      sort: { createdAt: 'asc' }
    });

    console.log("Found messages:", messages.length);
    console.log("Messages:", JSON.stringify(messages, null, 2));

    // Return in Strapi format with data wrapper
    return { data: messages };
  }
}));

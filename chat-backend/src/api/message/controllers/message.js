'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::message.message', ({ strapi }) => ({
  async find(ctx) {
    const user = ctx.state.user;
    
    if (!user) {
      return ctx.unauthorized('You must be logged in');
    }

    // Get messages where user is sender or receiver
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

    return messages;
  }
}));

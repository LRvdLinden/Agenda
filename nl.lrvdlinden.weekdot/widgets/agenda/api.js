'use strict';

module.exports = {
  async getAgenda({ homey, query }) {
    return homey.app.widgetData({ days: query.days, allday: query.allday !== 'false' });
  },
};

'use strict';

// Called by the Weekdot app (iPhone, iPad, Mac) with a Homey session of the signed-in user,
// and by the settings page.
module.exports = {
  async postSchedule({ homey, body }) {
    return homey.app.receiveSchedule(body);
  },
  async getStatus({ homey }) {
    return homey.app.status();
  },
  async deleteSchedule({ homey }) {
    return homey.app.clearSchedule();
  },
};

'use strict';

// Called by the Weekdot app (iPhone, iPad, Mac) with a Homey session of the signed-in user,
// and by the settings page.
module.exports = {
  // Public: lets Weekdot check that the app is installed.
  async ping({ homey }) {
    return { app: 'Weekdot', version: homey.manifest.version };
  },
  // Public: Weekdot registers its key once (first key wins).
  async postPair({ homey, body }) {
    return homey.app.pair(body);
  },
  // Public: only accepted with the registered key.
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

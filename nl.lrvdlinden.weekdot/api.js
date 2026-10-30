'use strict';

// Called by the Weekdot app (iPhone, iPad, Mac) with a Homey session of the signed-in user,
// and by the settings page.
module.exports = {
  // Read with the user's Homey token (read-only scope is enough): the key Weekdot uses to send the schedule.
  async getPairing({ homey }) {
    return homey.app.pairing();
  },
  // Public endpoint (no token): only accepted with the pairing key from getPairing.
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

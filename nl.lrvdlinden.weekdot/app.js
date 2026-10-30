'use strict';

const crypto = require('crypto');
const Homey = require('homey');
const Agenda = require('./lib/agenda');

const TICK = 30 * 1000;
const MAX_LATE = 10 * 60 * 1000; // after a restart, do not fire triggers that are more than 10 minutes old

class WeekdotApp extends Homey.App {
  async onInit() {
    this.agenda = new Agenda(this.homey);
    this.lastTick = Date.now();
    this.fired = new Set();

    const flow = this.homey.flow;
    const calendarAutocomplete = async query => this.calendarChoices(query);

    this.started = flow.getTriggerCard('event_started');
    this.ended = flow.getTriggerCard('event_ended');
    this.startsIn = flow.getTriggerCard('event_starts_in');
    this.atTime = flow.getTriggerCard('agenda_at_time');
    this.received = flow.getTriggerCard('schedule_received');

    for (const card of [this.started, this.ended]) {
      card.registerRunListener(async (args, state) => this.agenda.matches(state.event, args));
      card.registerArgumentAutocompleteListener('calendar', calendarAutocomplete);
    }
    this.startsIn.registerRunListener(async (args, state) => Number(args.minutes) === state.minutes && this.agenda.matches(state.event, args));
    this.startsIn.registerArgumentAutocompleteListener('calendar', calendarAutocomplete);
    this.atTime.registerRunListener(async (args, state) => args.time === state.time);

    const now = () => new Date();
    const conditions = {
      event_now: args => this.agenda.events.some(e => this.agenda.isNow(e, now()) && this.agenda.matches(e, args)),
      event_today: args => this.agenda.eventsOn(this.agenda.dayKey(now())).some(e => this.agenda.matches(e, args)),
      event_tomorrow: args => this.agenda.eventsOn(this.agenda.dayKey(now(), 1)).some(e => this.agenda.matches(e, args)),
    };
    for (const [id, fn] of Object.entries(conditions)) {
      const card = flow.getConditionCard(id);
      card.registerRunListener(async args => fn(args));
      card.registerArgumentAutocompleteListener('calendar', calendarAutocomplete);
    }

    const nextCard = flow.getActionCard('get_next_event');
    nextCard.registerArgumentAutocompleteListener('calendar', calendarAutocomplete);
    nextCard.registerRunListener(async args => {
      const e = this.agenda.next(args);
      if (!e) {
        return { found: false, title: '', emoji: '', location: '', calendar: '', start_time: '', date: '', minutes_until: 0 };
      }
      const t = this.agenda.tokens(e);
      return {
        found: true, title: t.title, emoji: t.emoji, location: t.location, calendar: t.calendar, start_time: t.start_time,
        date: this.agenda.dayKey(new Date(e.start)),
        minutes_until: Math.max(0, Math.round((Date.parse(e.start) - Date.now()) / 60000)),
      };
    });
    flow.getActionCard('get_agenda').registerRunListener(async args => {
      const day = this.agenda.dayKey(new Date(), args.day === 'tomorrow' ? 1 : 0);
      return this.agenda.agendaTokens(this.agenda.eventsOn(day));
    });

    // global Flow tokens
    this.tokens = {
      nextTitle: await flow.createToken('next_title', { type: 'string', title: this.homey.__('tokens.next_title') }),
      nextTime: await flow.createToken('next_time', { type: 'string', title: this.homey.__('tokens.next_time') }),
      todayCount: await flow.createToken('today_count', { type: 'number', title: this.homey.__('tokens.today_count') }),
    };

    await this.updateTokens();
    this.homey.setInterval(() => this.tick().catch(err => this.error('tick', err)), TICK);
    this.log('Weekdot ready,', this.agenda.events.length, 'events');
  }

  // ---- API (api.js) ----

  /** Weekdot registers its secret key once; the first key wins until "Remove" in the settings clears it. */
  pair(body) {
    const key = body && typeof body.key === 'string' ? body.key : '';
    if (!/^[0-9a-f]{32,128}$/.test(key)) throw new Error('bad_key');
    const stored = this.homey.settings.get('pairingKey');
    if (stored && !this.keyMatches(key)) throw new Error('already_linked');
    if (!stored) {
      this.homey.settings.set('pairingKey', key);
      this.homey.settings.set('pairedDevice', String(body.device || 'Weekdot').slice(0, 120));
      this.log('Linked with Weekdot on', body.device);
    }
    return { ok: true };
  }

  keyMatches(given) {
    const key = this.homey.settings.get('pairingKey');
    if (!key || typeof given !== 'string' || given.length !== key.length) return false;
    return crypto.timingSafeEqual(Buffer.from(given), Buffer.from(key));
  }

  async receiveSchedule(body) {
    if (!body || !this.keyMatches(body.key)) {
      const err = new Error('Invalid pairing key');
      err.statusCode = 401;
      throw err;
    }
    let count;
    try {
      count = this.agenda.store(body);
    } catch (err) {
      throw new Error(this.homey.__('errors.bad_schedule'));
    }
    await this.updateTokens();
    this.homey.api.realtime('update', { count });
    await this.received.trigger({ count, device: this.agenda.data.device }).catch(err => this.error(err));
    return { ok: true, count };
  }

  status() {
    const d = this.agenda.data;
    return {
      app: 'Weekdot', version: this.homey.manifest.version, linked: !!d,
      device: d ? d.device : null, receivedAt: d ? d.receivedAt : null,
      events: this.agenda.events.length, calendars: this.agenda.calendars,
    };
  }

  async clearSchedule() {
    this.agenda.clear();
    this.homey.settings.unset('pairingKey');
    this.homey.settings.unset('pairedDevice');
    await this.updateTokens();
    this.homey.api.realtime('update', { count: 0 });
    return { ok: true };
  }

  /** Data for the Agenda widget. */
  widgetData({ days = 'today', allday = true } = {}) {
    const now = new Date();
    const list = [0].concat(days === 'today_tomorrow' ? [1] : []).map(offset => {
      const day = this.agenda.dayKey(now, offset);
      const events = this.agenda.eventsOn(day, { allDay: allday !== false && allday !== 'false' }).map(e => ({
        title: e.title, emoji: e.emoji, location: e.location, color: e.color, allDay: e.allDay,
        start: e.allDay ? '' : this.agenda.time(new Date(e.start)),
        end: e.allDay ? '' : this.agenda.time(new Date(e.end)),
        now: this.agenda.isNow(e, now) && !e.allDay,
        past: !e.allDay && Date.parse(e.end) <= now.getTime(),
      }));
      return { offset, day, events };
    });
    return { linked: !!this.agenda.data, receivedAt: this.agenda.data ? this.agenda.data.receivedAt : null, days: list };
  }

  // ---- internals ----

  calendarChoices(query) {
    const q = (query || '').toLowerCase();
    const list = [{ id: '*', name: this.homey.__('calendar.any') }]
      .concat(this.agenda.calendars.map(c => ({ id: c.id, name: c.title })));
    return list.filter(c => !q || c.name.toLowerCase().includes(q));
  }

  async updateTokens() {
    const e = this.agenda.next();
    await this.tokens.nextTitle.setValue(e ? `${e.emoji ? `${e.emoji} ` : ''}${e.title}` : '');
    await this.tokens.nextTime.setValue(e ? this.agenda.time(new Date(e.start)) : '');
    await this.tokens.todayCount.setValue(this.agenda.eventsOn(this.agenda.dayKey(new Date())).length);
  }

  /** Every 30 s: fire the triggers whose moment passed since the last tick. */
  async tick() {
    const nowMs = Date.now();
    const from = Math.max(this.lastTick, nowMs - MAX_LATE);
    this.lastTick = nowMs;
    const crossed = ms => ms > from && ms <= nowMs;
    const once = key => (this.fired.has(key) ? false : (this.fired.add(key), true));

    for (const e of this.agenda.events) {
      const start = Date.parse(e.start);
      const end = Date.parse(e.end);
      if (crossed(start) && once(`s|${e.id}|${start}`)) {
        await this.started.trigger(this.agenda.tokens(e), { event: e }).catch(err => this.error(err));
      }
      if (crossed(end) && once(`e|${e.id}|${end}`)) {
        await this.ended.trigger(this.agenda.tokens(e), { event: e }).catch(err => this.error(err));
      }
    }

    // "starts in … minutes": only for the minute values used in Flows
    const minuteValues = new Set((await this.startsIn.getArgumentValues()).map(a => Number(a.minutes)).filter(m => m > 0));
    for (const m of minuteValues) {
      for (const e of this.agenda.events) {
        if (e.allDay) continue;
        const at = Date.parse(e.start) - m * 60000;
        if (crossed(at) && once(`i|${m}|${e.id}|${at}`)) {
          await this.startsIn.trigger(this.agenda.tokens(e), { event: e, minutes: m }).catch(err => this.error(err));
        }
      }
    }

    // daily agenda at a set time
    const times = new Set((await this.atTime.getArgumentValues()).map(a => a.time).filter(Boolean));
    if (times.size) {
      const fromDate = new Date(from);
      const nowDate = new Date(nowMs);
      const sameDay = this.agenda.dayKey(fromDate) === this.agenda.dayKey(nowDate);
      const a = sameDay ? this.agenda.minuteOfDay(fromDate) : -1;
      const b = this.agenda.minuteOfDay(nowDate);
      for (const time of times) {
        const [h, mi] = time.split(':').map(Number);
        const t = h * 60 + mi;
        if (t > a && t <= b && once(`t|${time}|${this.agenda.dayKey(nowDate)}`)) {
          const list = this.agenda.eventsOn(this.agenda.dayKey(nowDate));
          await this.atTime.trigger(this.agenda.agendaTokens(list), { time }).catch(err => this.error(err));
        }
      }
    }

    if (this.fired.size > 5000) this.fired = new Set([...this.fired].slice(-1000));
    if (new Date(nowMs).getSeconds() < TICK / 1000) await this.updateTokens();
  }
}

module.exports = WeekdotApp;

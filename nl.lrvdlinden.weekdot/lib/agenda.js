'use strict';

/**
 * The schedule Weekdot sends (next 8 days) and helpers to read it in Homey's time zone.
 * Event: { id, title, emoji?, location?, start, end (ISO), allDay, startDay, endDay (yyyy-mm-dd, end exclusive),
 *          calendarId, calendar, color, free }
 */
const MAX_EVENTS = 3000;
const str = (v, max = 300) => (typeof v === 'string' ? v.slice(0, max) : '');

class Agenda {
  constructor(homey) {
    this.homey = homey;
    this.data = homey.settings.get('schedule') || null;
  }

  /** Checks and stores a schedule from Weekdot. Returns the number of events. */
  store(body) {
    if (!body || typeof body !== 'object' || !Array.isArray(body.events)) throw new Error('bad_schedule');
    const events = body.events.slice(0, MAX_EVENTS).map(e => ({
      id: str(e.id, 200),
      title: str(e.title),
      emoji: str(e.emoji, 16),
      location: str(e.location),
      start: str(e.start, 40),
      end: str(e.end, 40),
      allDay: e.allDay === true,
      startDay: str(e.startDay, 10),
      endDay: str(e.endDay, 10),
      calendarId: str(e.calendarId, 200),
      calendar: str(e.calendar, 120),
      color: /^#[0-9a-fA-F]{6}$/.test(e.color || '') ? e.color : '#E8352F',
      free: e.free === true,
    })).filter(e => !Number.isNaN(Date.parse(e.start)) && !Number.isNaN(Date.parse(e.end)));
    const calendars = (Array.isArray(body.calendars) ? body.calendars : []).slice(0, 200).map(c => ({
      id: str(c.id, 200), title: str(c.title, 120), color: /^#[0-9a-fA-F]{6}$/.test(c.color || '') ? c.color : '#E8352F',
    }));
    this.data = {
      receivedAt: new Date().toISOString(),
      sentAt: str(body.sentAt, 40),
      device: str(body.device, 120) || 'Weekdot',
      appVersion: str(body.appVersion, 20),
      from: str(body.from, 40),
      to: str(body.to, 40),
      calendars,
      events: events.sort((a, b) => Date.parse(a.start) - Date.parse(b.start)),
    };
    this.homey.settings.set('schedule', this.data);
    return events.length;
  }

  clear() {
    this.data = null;
    this.homey.settings.unset('schedule');
  }

  get events() { return (this.data && this.data.events) || []; }
  get calendars() { return (this.data && this.data.calendars) || []; }

  // ---- time helpers (Homey's time zone) ----
  get timeZone() { return this.homey.clock.getTimezone(); }

  /** yyyy-mm-dd of a moment in Homey's time zone. */
  dayKey(date, offsetDays = 0) {
    const d = new Date(date.getTime() + offsetDays * 86400000);
    const p = new Intl.DateTimeFormat('en-CA', { timeZone: this.timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(d);
    const get = t => (p.find(x => x.type === t) || {}).value;
    return `${get('year')}-${get('month')}-${get('day')}`;
  }

  /** HH:MM of a moment in Homey's time zone. */
  time(date) {
    const p = new Intl.DateTimeFormat('en-GB', { timeZone: this.timeZone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).formatToParts(date);
    const get = t => (p.find(x => x.type === t) || {}).value;
    return `${get('hour')}:${get('minute')}`;
  }

  /** Minutes since midnight in Homey's time zone. */
  minuteOfDay(date) {
    const [h, m] = this.time(date).split(':').map(Number);
    return h * 60 + m;
  }

  /** Does the event cover (part of) the day yyyy-mm-dd? */
  onDay(e, day) {
    if (e.allDay) return e.startDay <= day && day < e.endDay;
    const first = this.dayKey(new Date(e.start));
    const last = this.dayKey(new Date(Math.max(Date.parse(e.start), Date.parse(e.end) - 1)));
    return first <= day && day <= last;
  }

  isNow(e, now = new Date()) {
    if (e.allDay) return this.onDay(e, this.dayKey(now));
    return Date.parse(e.start) <= now.getTime() && now.getTime() < Date.parse(e.end);
  }

  /** Does the event match the Flow arguments (calendar and optional word in the title)? */
  matches(e, args = {}) {
    const cal = args.calendar && args.calendar.id;
    if (cal && cal !== '*' && e.calendarId !== cal) return false;
    const word = (args.keyword || '').trim().toLowerCase();
    if (word && !(`${e.title} ${e.emoji}`).toLowerCase().includes(word)) return false;
    return true;
  }

  eventsOn(day, { allDay = true } = {}) {
    return this.events.filter(e => this.onDay(e, day) && (allDay || !e.allDay));
  }

  next(args = {}, now = new Date()) {
    return this.events.find(e => !e.allDay && Date.parse(e.start) > now.getTime() && this.matches(e, args)) || null;
  }

  /** "3 events: 09:30 Stand-up, 12:30 Lunch, …" in Homey's language. */
  summary(list) {
    const t = (k, tags) => this.homey.__(k, tags);
    if (!list.length) return t('agenda.none');
    const items = list.map(e => `${e.allDay ? t('agenda.all_day') : this.time(new Date(e.start))} ${e.emoji ? `${e.emoji} ` : ''}${e.title}`.trim());
    return list.length === 1 ? t('agenda.one', { list: items[0] }) : t('agenda.many', { count: list.length, list: items.join(', ') });
  }

  /** Flow tokens of one event. */
  tokens(e) {
    return {
      title: e.title,
      emoji: e.emoji || '',
      location: e.location || '',
      calendar: e.calendar || '',
      start_time: e.allDay ? '' : this.time(new Date(e.start)),
      end_time: e.allDay ? '' : this.time(new Date(e.end)),
      all_day: e.allDay,
    };
  }

  agendaTokens(list) {
    const first = list.find(e => !e.allDay) || list[0];
    return {
      count: list.length,
      summary: this.summary(list),
      first_title: first ? first.title : '',
      first_time: first && !first.allDay ? this.time(new Date(first.start)) : '',
    };
  }
}

module.exports = Agenda;

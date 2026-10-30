# All texts of the Weekdot Homey app in the 13 Homey languages. Order: en nl de fr it sv no es da ru pl ko ar
# Edit here, then run: python3 tools/generate.py
L = ["en","nl","de","fr","it","sv","no","es","da","ru","pl","ko","ar"]
def T(*v):
    assert len(v) == 13, v[0]
    return dict(zip(L, v))

S = {
 "app_name": T(*["Weekdot"]*13),
 "app_desc": T("Your Weekdot calendar in Homey: Flows for your events and your daily agenda",
   "Je Weekdot-agenda in Homey: Flows voor je afspraken en je dagagenda",
   "Dein Weekdot-Kalender in Homey: Flows für deine Termine und deine Tagesübersicht",
   "Votre calendrier Weekdot dans Homey : des Flows pour vos événements et votre agenda du jour",
   "Il tuo calendario Weekdot in Homey: Flow per i tuoi eventi e l'agenda del giorno",
   "Din Weekdot-kalender i Homey: Flows för dina händelser och dagens agenda",
   "Weekdot-kalenderen din i Homey: Flows for avtalene dine og dagens agenda",
   "Tu calendario Weekdot en Homey: Flows para tus eventos y tu agenda del día",
   "Din Weekdot-kalender i Homey: Flows til dine begivenheder og dagens program",
   "Ваш календарь Weekdot в Homey: Flow для событий и плана на день",
   "Twój kalendarz Weekdot w Homey: Flow dla wydarzeń i planu dnia",
   "Homey에서 만나는 Weekdot 캘린더: 일정과 오늘의 일정을 위한 Flow",
   "تقويم Weekdot في Homey: تدفقات لمواعيدك وجدول يومك"),
 # args
 "arg_calendar": T("Calendar","Agenda","Kalender","Calendrier","Calendario","Kalender","Kalender","Calendario","Kalender","Календарь","Kalendarz","캘린더","التقويم"),
 "arg_calendar_ph": T("Any calendar","Elke agenda","Jeder Kalender","N'importe quel calendrier","Qualsiasi calendario","Valfri kalender","Hvilken som helst kalender","Cualquier calendario","Enhver kalender","Любой календарь","Dowolny kalendarz","모든 캘린더","أي تقويم"),
 "arg_keyword": T("Title contains (optional)","Titel bevat (optioneel)","Titel enthält (optional)","Le titre contient (facultatif)","Il titolo contiene (facoltativo)","Titeln innehåller (valfritt)","Tittelen inneholder (valgfritt)","El título contiene (opcional)","Titlen indeholder (valgfrit)","Название содержит (необязательно)","Tytuł zawiera (opcjonalnie)","제목에 포함(선택)","العنوان يحتوي على (اختياري)"),
 "arg_keyword_ph": T("with any title","met elke titel","mit beliebigem Titel","avec n'importe quel titre","con qualsiasi titolo","med valfri titel","med hvilken som helst tittel","con cualquier título","med enhver titel","с любым названием","z dowolnym tytułem","모든 제목","بأي عنوان"),
 "arg_minutes": T("Minutes","Minuten","Minuten","Minutes","Minuti","Minuter","Minutter","Minutos","Minutter","Минуты","Minuty","분","الدقائق"),
 "arg_time": T("Time","Tijd","Uhrzeit","Heure","Ora","Tid","Tid","Hora","Tidspunkt","Время","Godzina","시간","الوقت"),
 "arg_day": T("Day","Dag","Tag","Jour","Giorno","Dag","Dag","Día","Dag","День","Dzień","날짜","اليوم"),
 "today": T("Today","Vandaag","Heute","Aujourd'hui","Oggi","Idag","I dag","Hoy","I dag","Сегодня","Dzisiaj","오늘","اليوم"),
 "tomorrow": T("Tomorrow","Morgen","Morgen","Demain","Domani","Imorgon","I morgen","Mañana","I morgen","Завтра","Jutro","내일","غدًا"),
 # tokens
 "tok_title": T("Title","Titel","Titel","Titre","Titolo","Titel","Tittel","Título","Titel","Название","Tytuł","제목","العنوان"),
 "tok_emoji": T("Emoji","Emoji","Emoji","Emoji","Emoji","Emoji","Emoji","Emoji","Emoji","Эмодзи","Emoji","이모지","رمز تعبيري"),
 "tok_location": T("Location","Locatie","Ort","Lieu","Luogo","Plats","Sted","Ubicación","Sted","Место","Miejsce","위치","الموقع"),
 "tok_calendar": T("Calendar","Agenda","Kalender","Calendrier","Calendario","Kalender","Kalender","Calendario","Kalender","Календарь","Kalendarz","캘린더","التقويم"),
 "tok_start": T("Start time","Begintijd","Beginn","Heure de début","Ora di inizio","Starttid","Starttid","Hora de inicio","Starttid","Время начала","Godzina rozpoczęcia","시작 시간","وقت البدء"),
 "tok_end": T("End time","Eindtijd","Ende","Heure de fin","Ora di fine","Sluttid","Sluttid","Hora de fin","Sluttid","Время окончания","Godzina zakończenia","종료 시간","وقت الانتهاء"),
 "tok_date": T("Date","Datum","Datum","Date","Data","Datum","Dato","Fecha","Dato","Дата","Data","날짜","التاريخ"),
 "tok_allday": T("All-day","Hele dag","Ganztägig","Toute la journée","Tutto il giorno","Heldag","Hele dagen","Todo el día","Hele dagen","Весь день","Cały dzień","하루 종일","طوال اليوم"),
 "tok_minutes_until": T("Minutes until start","Minuten tot begin","Minuten bis Beginn","Minutes avant le début","Minuti all'inizio","Minuter till start","Minutter til start","Minutos hasta el inicio","Minutter til start","Минут до начала","Minuty do rozpoczęcia","시작까지 남은 분","الدقائق حتى البدء"),
 "tok_found": T("Found","Gevonden","Gefunden","Trouvé","Trovato","Hittad","Funnet","Encontrado","Fundet","Найдено","Znaleziono","찾음","تم العثور"),
 "tok_count": T("Number of events","Aantal afspraken","Anzahl Termine","Nombre d'événements","Numero di eventi","Antal händelser","Antall avtaler","Número de eventos","Antal begivenheder","Количество событий","Liczba wydarzeń","일정 수","عدد المواعيد"),
 "tok_summary": T("Agenda","Agenda","Tagesübersicht","Agenda","Agenda","Agenda","Agenda","Agenda","Program","План","Plan","일정","جدول المواعيد"),
 "tok_first_title": T("First event","Eerste afspraak","Erster Termin","Premier événement","Primo evento","Första händelsen","Første avtale","Primer evento","Første begivenhed","Первое событие","Pierwsze wydarzenie","첫 일정","أول موعد"),
 "tok_first_time": T("First event time","Tijd eerste afspraak","Uhrzeit erster Termin","Heure du premier événement","Ora del primo evento","Tid för första händelsen","Tid for første avtale","Hora del primer evento","Tid for første begivenhed","Время первого события","Godzina pierwszego wydarzenia","첫 일정 시간","وقت أول موعد"),
 "tok_device": T("Device","Apparaat","Gerät","Appareil","Dispositivo","Enhet","Enhet","Dispositivo","Enhed","Устройство","Urządzenie","기기","الجهاز"),
 # global tokens
 "g_next_title": T("Next event","Volgende afspraak","Nächster Termin","Prochain événement","Prossimo evento","Nästa händelse","Neste avtale","Próximo evento","Næste begivenhed","Следующее событие","Następne wydarzenie","다음 일정","الموعد التالي"),
 "g_next_time": T("Next event (time)","Volgende afspraak (tijd)","Nächster Termin (Uhrzeit)","Prochain événement (heure)","Prossimo evento (ora)","Nästa händelse (tid)","Neste avtale (tid)","Próximo evento (hora)","Næste begivenhed (tid)","Следующее событие (время)","Następne wydarzenie (godzina)","다음 일정(시간)","الموعد التالي (الوقت)"),
 "g_today_count": T("Events today","Afspraken vandaag","Termine heute","Événements aujourd'hui","Eventi di oggi","Händelser idag","Avtaler i dag","Eventos de hoy","Begivenheder i dag","События сегодня","Wydarzenia dzisiaj","오늘 일정","مواعيد اليوم"),
}

# flow cards: (title, titleFormatted)
C = {
 "event_started": (
  T("An event starts","Een afspraak begint","Ein Termin beginnt","Un événement commence","Un evento inizia","En händelse börjar","En avtale starter","Empieza un evento","En begivenhed starter","Событие начинается","Wydarzenie się zaczyna","일정이 시작됨","يبدأ موعد"),
  T("An event [[keyword]] in [[calendar]] starts","Een afspraak [[keyword]] in [[calendar]] begint","Ein Termin [[keyword]] in [[calendar]] beginnt","Un événement [[keyword]] dans [[calendar]] commence","Un evento [[keyword]] in [[calendar]] inizia","En händelse [[keyword]] i [[calendar]] börjar","En avtale [[keyword]] i [[calendar]] starter","Empieza un evento [[keyword]] en [[calendar]]","En begivenhed [[keyword]] i [[calendar]] starter","Событие [[keyword]] в [[calendar]] начинается","Wydarzenie [[keyword]] w [[calendar]] się zaczyna","[[calendar]]의 일정 [[keyword]]이(가) 시작됨","يبدأ موعد [[keyword]] في [[calendar]]")),
 "event_ended": (
  T("An event ends","Een afspraak eindigt","Ein Termin endet","Un événement se termine","Un evento finisce","En händelse slutar","En avtale slutter","Termina un evento","En begivenhed slutter","Событие заканчивается","Wydarzenie się kończy","일정이 종료됨","ينتهي موعد"),
  T("An event [[keyword]] in [[calendar]] ends","Een afspraak [[keyword]] in [[calendar]] eindigt","Ein Termin [[keyword]] in [[calendar]] endet","Un événement [[keyword]] dans [[calendar]] se termine","Un evento [[keyword]] in [[calendar]] finisce","En händelse [[keyword]] i [[calendar]] slutar","En avtale [[keyword]] i [[calendar]] slutter","Termina un evento [[keyword]] en [[calendar]]","En begivenhed [[keyword]] i [[calendar]] slutter","Событие [[keyword]] в [[calendar]] заканчивается","Wydarzenie [[keyword]] w [[calendar]] się kończy","[[calendar]]의 일정 [[keyword]]이(가) 종료됨","ينتهي موعد [[keyword]] في [[calendar]]")),
 "event_starts_in": (
  T("An event starts in … minutes","Een afspraak begint over … minuten","Ein Termin beginnt in … Minuten","Un événement commence dans … minutes","Un evento inizia tra … minuti","En händelse börjar om … minuter","En avtale starter om … minutter","Un evento empieza en … minutos","En begivenhed starter om … minutter","Событие начнётся через … минут","Wydarzenie zacznie się za … minut","… 분 후 일정 시작","يبدأ موعد بعد … دقيقة"),
  T("An event [[keyword]] in [[calendar]] starts in [[minutes]] minutes","Een afspraak [[keyword]] in [[calendar]] begint over [[minutes]] minuten","Ein Termin [[keyword]] in [[calendar]] beginnt in [[minutes]] Minuten","Un événement [[keyword]] dans [[calendar]] commence dans [[minutes]] minutes","Un evento [[keyword]] in [[calendar]] inizia tra [[minutes]] minuti","En händelse [[keyword]] i [[calendar]] börjar om [[minutes]] minuter","En avtale [[keyword]] i [[calendar]] starter om [[minutes]] minutter","Un evento [[keyword]] en [[calendar]] empieza en [[minutes]] minutos","En begivenhed [[keyword]] i [[calendar]] starter om [[minutes]] minutter","Событие [[keyword]] в [[calendar]] начнётся через [[minutes]] мин.","Wydarzenie [[keyword]] w [[calendar]] zacznie się za [[minutes]] min","[[calendar]]의 일정 [[keyword]]이(가) [[minutes]]분 후 시작","يبدأ موعد [[keyword]] في [[calendar]] بعد [[minutes]] دقيقة")),
 "agenda_at_time": (
  T("Daily agenda at a set time","Dagagenda op een vast tijdstip","Tagesübersicht zu einer festen Uhrzeit","Agenda du jour à heure fixe","Agenda del giorno a un orario fisso","Dagens agenda vid en viss tid","Dagens agenda på et fast tidspunkt","Agenda del día a una hora fija","Dagens program på et fast tidspunkt","План на день в заданное время","Plan dnia o ustalonej godzinie","정해진 시간에 오늘 일정","جدول اليوم في وقت محدد"),
  T("Today's agenda at [[time]]","De agenda van vandaag om [[time]]","Die Termine von heute um [[time]]","L'agenda du jour à [[time]]","L'agenda di oggi alle [[time]]","Dagens agenda kl. [[time]]","Dagens agenda kl. [[time]]","La agenda de hoy a las [[time]]","Dagens program kl. [[time]]","План на сегодня в [[time]]","Plan na dziś o [[time]]","[[time]]에 오늘 일정","جدول اليوم في [[time]]")),
 "schedule_received": (
  T("Weekdot sent new events","Weekdot heeft nieuwe afspraken gestuurd","Weekdot hat neue Termine gesendet","Weekdot a envoyé de nouveaux événements","Weekdot ha inviato nuovi eventi","Weekdot skickade nya händelser","Weekdot sendte nye avtaler","Weekdot envió eventos nuevos","Weekdot sendte nye begivenheder","Weekdot отправил новые события","Weekdot wysłał nowe wydarzenia","Weekdot이 새 일정을 보냄","أرسل Weekdot مواعيد جديدة"), None),
 "event_now": (
  T("There is an event right now","Er is nu een afspraak","Gerade läuft ein Termin","Un événement est en cours","C'è un evento in corso","Det pågår en händelse nu","Det er en avtale nå","Hay un evento ahora","Der er en begivenhed nu","Сейчас идёт событие","Trwa wydarzenie","지금 일정이 있음","يوجد موعد الآن"),
  T("There !{{is|is no}} event [[keyword]] in [[calendar]] right now","Er !{{is|is geen}} afspraak [[keyword]] in [[calendar]] op dit moment","Gerade !{{läuft|läuft kein}} Termin [[keyword]] in [[calendar]]","Un événement [[keyword]] dans [[calendar]] !{{est|n'est pas}} en cours","!{{C'è|Non c'è}} un evento [[keyword]] in [[calendar]] in corso","Det !{{pågår|pågår ingen}} händelse [[keyword]] i [[calendar]] nu","Det !{{er|er ingen}} avtale [[keyword]] i [[calendar]] nå","!{{Hay|No hay}} un evento [[keyword]] en [[calendar]] ahora","Der !{{er|er ingen}} begivenhed [[keyword]] i [[calendar]] nu","Сейчас !{{идёт|не идёт}} событие [[keyword]] в [[calendar]]","Wydarzenie [[keyword]] w [[calendar]] !{{trwa|nie trwa}}","지금 [[calendar]]에 일정 [[keyword]]이(가) !{{있음|없음}}","!{{يوجد|لا يوجد}} موعد [[keyword]] في [[calendar]] الآن")),
 "event_today": (
  T("There is an event today","Er is vandaag een afspraak","Heute gibt es einen Termin","Il y a un événement aujourd'hui","C'è un evento oggi","Det finns en händelse idag","Det er en avtale i dag","Hay un evento hoy","Der er en begivenhed i dag","Сегодня есть событие","Dzisiaj jest wydarzenie","오늘 일정이 있음","يوجد موعد اليوم"),
  T("There !{{is|is no}} event [[keyword]] in [[calendar]] today","Er !{{is|is geen}} afspraak [[keyword]] in [[calendar]] vandaag","Heute !{{gibt es einen|gibt es keinen}} Termin [[keyword]] in [[calendar]]","Il !{{y a|n'y a pas}} d'événement [[keyword]] dans [[calendar]] aujourd'hui","Oggi !{{c'è|non c'è}} un evento [[keyword]] in [[calendar]]","Det !{{finns|finns ingen}} händelse [[keyword]] i [[calendar]] idag","Det !{{er|er ingen}} avtale [[keyword]] i [[calendar]] i dag","!{{Hay|No hay}} un evento [[keyword]] en [[calendar]] hoy","Der !{{er|er ingen}} begivenhed [[keyword]] i [[calendar]] i dag","Сегодня !{{есть|нет}} события [[keyword]] в [[calendar]]","Dzisiaj !{{jest|nie ma}} wydarzenia [[keyword]] w [[calendar]]","오늘 [[calendar]]에 일정 [[keyword]]이(가) !{{있음|없음}}","!{{يوجد|لا يوجد}} موعد [[keyword]] في [[calendar]] اليوم")),
 "event_tomorrow": (
  T("There is an event tomorrow","Er is morgen een afspraak","Morgen gibt es einen Termin","Il y a un événement demain","C'è un evento domani","Det finns en händelse imorgon","Det er en avtale i morgen","Hay un evento mañana","Der er en begivenhed i morgen","Завтра есть событие","Jutro jest wydarzenie","내일 일정이 있음","يوجد موعد غدًا"),
  T("There !{{is|is no}} event [[keyword]] in [[calendar]] tomorrow","Er !{{is|is geen}} afspraak [[keyword]] in [[calendar]] morgen","Morgen !{{gibt es einen|gibt es keinen}} Termin [[keyword]] in [[calendar]]","Il !{{y a|n'y a pas}} d'événement [[keyword]] dans [[calendar]] demain","Domani !{{c'è|non c'è}} un evento [[keyword]] in [[calendar]]","Det !{{finns|finns ingen}} händelse [[keyword]] i [[calendar]] imorgon","Det !{{er|er ingen}} avtale [[keyword]] i [[calendar]] i morgen","!{{Hay|No hay}} un evento [[keyword]] en [[calendar]] mañana","Der !{{er|er ingen}} begivenhed [[keyword]] i [[calendar]] i morgen","Завтра !{{есть|нет}} события [[keyword]] в [[calendar]]","Jutro !{{jest|nie ma}} wydarzenia [[keyword]] w [[calendar]]","내일 [[calendar]]에 일정 [[keyword]]이(가) !{{있음|없음}}","!{{يوجد|لا يوجد}} موعد [[keyword]] في [[calendar]] غدًا")),
 "get_next_event": (
  T("Get the next event","Haal de volgende afspraak op","Nächsten Termin abrufen","Obtenir le prochain événement","Ottieni il prossimo evento","Hämta nästa händelse","Hent neste avtale","Obtener el próximo evento","Hent næste begivenhed","Получить следующее событие","Pobierz następne wydarzenie","다음 일정 가져오기","احصل على الموعد التالي"),
  T("Get the next event [[keyword]] in [[calendar]]","Haal de volgende afspraak [[keyword]] in [[calendar]] op","Nächsten Termin [[keyword]] in [[calendar]] abrufen","Obtenir le prochain événement [[keyword]] dans [[calendar]]","Ottieni il prossimo evento [[keyword]] in [[calendar]]","Hämta nästa händelse [[keyword]] i [[calendar]]","Hent neste avtale [[keyword]] i [[calendar]]","Obtener el próximo evento [[keyword]] en [[calendar]]","Hent næste begivenhed [[keyword]] i [[calendar]]","Получить следующее событие [[keyword]] в [[calendar]]","Pobierz następne wydarzenie [[keyword]] w [[calendar]]","[[calendar]]의 다음 일정 [[keyword]] 가져오기","احصل على الموعد التالي [[keyword]] في [[calendar]]")),
 "get_agenda": (
  T("Get the agenda","Haal de agenda op","Tagesübersicht abrufen","Obtenir l'agenda","Ottieni l'agenda","Hämta agendan","Hent agendaen","Obtener la agenda","Hent programmet","Получить план","Pobierz plan","일정 가져오기","احصل على جدول المواعيد"),
  T("Get the agenda of [[day]]","Haal de agenda van [[day]] op","Termine von [[day]] abrufen","Obtenir l'agenda de [[day]]","Ottieni l'agenda di [[day]]","Hämta agendan för [[day]]","Hent agendaen for [[day]]","Obtener la agenda de [[day]]","Hent programmet for [[day]]","Получить план на [[day]]","Pobierz plan na [[day]]","[[day]] 일정 가져오기","احصل على جدول [[day]]")),
}

# runtime strings (locales/<lang>.json), flattened keys
R = {
 "calendar.any": S["arg_calendar_ph"],
 "agenda.none": T("No events","Geen afspraken","Keine Termine","Aucun événement","Nessun evento","Inga händelser","Ingen avtaler","Sin eventos","Ingen begivenheder","Нет событий","Brak wydarzeń","일정 없음","لا توجد مواعيد"),
 "agenda.one": T("1 event: __list__","1 afspraak: __list__","1 Termin: __list__","1 événement : __list__","1 evento: __list__","1 händelse: __list__","1 avtale: __list__","1 evento: __list__","1 begivenhed: __list__","1 событие: __list__","1 wydarzenie: __list__","일정 1개: __list__","موعد واحد: __list__"),
 "agenda.many": T("__count__ events: __list__","__count__ afspraken: __list__","__count__ Termine: __list__","__count__ événements : __list__","__count__ eventi: __list__","__count__ händelser: __list__","__count__ avtaler: __list__","__count__ eventos: __list__","__count__ begivenheder: __list__","Событий: __count__: __list__","Wydarzenia (__count__): __list__","일정 __count__개: __list__","__count__ مواعيد: __list__"),
 "agenda.all_day": T("all day","hele dag","ganztägig","toute la journée","tutto il giorno","heldag","hele dagen","todo el día","hele dagen","весь день","cały dzień","하루 종일","طوال اليوم"),
 "errors.bad_schedule": T("Weekdot sent data that could not be read.","Weekdot stuurde gegevens die niet gelezen konden worden.","Weekdot hat Daten gesendet, die nicht gelesen werden konnten.","Weekdot a envoyé des données illisibles.","Weekdot ha inviato dati non leggibili.","Weekdot skickade data som inte kunde läsas.","Weekdot sendte data som ikke kunne leses.","Weekdot envió datos que no se pudieron leer.","Weekdot sendte data, der ikke kunne læses.","Weekdot отправил данные, которые не удалось прочитать.","Weekdot wysłał dane, których nie można odczytać.","Weekdot에서 읽을 수 없는 데이터를 보냈습니다.","أرسل Weekdot بيانات تعذرت قراءتها."),
 # settings page
 "settings.subtitle": T("Your Weekdot calendar in Homey.","Je Weekdot-agenda in Homey.","Dein Weekdot-Kalender in Homey.","Votre calendrier Weekdot dans Homey.","Il tuo calendario Weekdot in Homey.","Din Weekdot-kalender i Homey.","Weekdot-kalenderen din i Homey.","Tu calendario Weekdot en Homey.","Din Weekdot-kalender i Homey.","Ваш календарь Weekdot в Homey.","Twój kalendarz Weekdot w Homey.","Homey의 Weekdot 캘린더.","تقويم Weekdot في Homey."),
 "settings.status": T("Status","Status","Status","Statut","Stato","Status","Status","Estado","Status","Статус","Status","상태","الحالة"),
 "settings.not_linked": T("Not linked yet","Nog niet gekoppeld","Noch nicht verbunden","Pas encore lié","Non ancora collegato","Inte länkad än","Ikke koblet ennå","Aún no vinculado","Ikke forbundet endnu","Ещё не подключено","Jeszcze nie połączono","아직 연결되지 않음","غير مرتبط بعد"),
 "settings.linked": T("Linked with __device__","Gekoppeld met __device__","Verbunden mit __device__","Lié à __device__","Collegato con __device__","Länkad med __device__","Koblet til __device__","Vinculado con __device__","Forbundet med __device__","Подключено к __device__","Połączono z __device__","__device__에 연결됨","مرتبط بـ __device__"),
 "settings.updated": T("Last update","Laatste update","Letzte Aktualisierung","Dernière mise à jour","Ultimo aggiornamento","Senast uppdaterad","Sist oppdatert","Última actualización","Sidst opdateret","Последнее обновление","Ostatnia aktualizacja","마지막 업데이트","آخر تحديث"),
 "settings.events": T("Events (next 8 days)","Afspraken (komende 8 dagen)","Termine (nächste 8 Tage)","Événements (8 prochains jours)","Eventi (prossimi 8 giorni)","Händelser (kommande 8 dagar)","Avtaler (neste 8 dager)","Eventos (próximos 8 días)","Begivenheder (næste 8 dage)","События (следующие 8 дней)","Wydarzenia (najbliższe 8 dni)","일정(다음 8일)","المواعيد (الأيام الثمانية القادمة)"),
 "settings.calendars": T("Calendars","Agenda's","Kalender","Calendriers","Calendari","Kalendrar","Kalendere","Calendarios","Kalendere","Календари","Kalendarze","캘린더","التقويمات"),
 "settings.stale": T("Weekdot has not sent an update for a while. Open Weekdot on your iPhone to update.","Weekdot heeft al een tijd geen update gestuurd. Open Weekdot op je iPhone om bij te werken.","Weekdot hat länger kein Update gesendet. Öffne Weekdot auf deinem iPhone zum Aktualisieren.","Weekdot n'a pas envoyé de mise à jour depuis un moment. Ouvrez Weekdot sur votre iPhone.","Weekdot non invia aggiornamenti da un po'. Apri Weekdot sull'iPhone per aggiornare.","Weekdot har inte skickat någon uppdatering på ett tag. Öppna Weekdot på din iPhone.","Weekdot har ikke sendt en oppdatering på en stund. Åpne Weekdot på iPhone.","Weekdot no ha enviado ninguna actualización en un tiempo. Abre Weekdot en tu iPhone.","Weekdot har ikke sendt en opdatering i et stykke tid. Åbn Weekdot på din iPhone.","Weekdot давно не присылал обновлений. Откройте Weekdot на iPhone.","Weekdot od dawna nie wysłał aktualizacji. Otwórz Weekdot na iPhonie.","Weekdot이 한동안 업데이트를 보내지 않았습니다. iPhone에서 Weekdot을 여세요.","لم يرسل Weekdot تحديثًا منذ فترة. افتح Weekdot على iPhone للتحديث."),
 "settings.howto": T("How to link","Zo koppel je","So verbindest du","Comment lier","Come collegare","Så länkar du","Slik kobler du","Cómo vincular","Sådan forbinder du","Как подключить","Jak połączyć","연결 방법","طريقة الربط"),
 "settings.step1": T("Install Weekdot on your iPhone, iPad or Mac.","Installeer Weekdot op je iPhone, iPad of Mac.","Installiere Weekdot auf deinem iPhone, iPad oder Mac.","Installez Weekdot sur votre iPhone, iPad ou Mac.","Installa Weekdot su iPhone, iPad o Mac.","Installera Weekdot på din iPhone, iPad eller Mac.","Installer Weekdot på iPhone, iPad eller Mac.","Instala Weekdot en tu iPhone, iPad o Mac.","Installer Weekdot på din iPhone, iPad eller Mac.","Установите Weekdot на iPhone, iPad или Mac.","Zainstaluj Weekdot na iPhonie, iPadzie lub Macu.","iPhone, iPad 또는 Mac에 Weekdot을 설치하세요.","ثبّت Weekdot على iPhone أو iPad أو Mac."),
 "settings.step2": T("In Weekdot, open Settings › Homey and sign in with your Homey account.","Open in Weekdot Instellingen › Homey en log in met je Homey-account.","Öffne in Weekdot Einstellungen › Homey und melde dich mit deinem Homey-Konto an.","Dans Weekdot, ouvrez Réglages › Homey et connectez-vous avec votre compte Homey.","In Weekdot apri Impostazioni › Homey e accedi con il tuo account Homey.","Öppna Inställningar › Homey i Weekdot och logga in med ditt Homey-konto.","Åpne Innstillinger › Homey i Weekdot og logg inn med Homey-kontoen din.","En Weekdot, abre Ajustes › Homey e inicia sesión con tu cuenta de Homey.","Åbn Indstillinger › Homey i Weekdot, og log ind med din Homey-konto.","В Weekdot откройте Настройки › Homey и войдите в аккаунт Homey.","W Weekdot otwórz Ustawienia › Homey i zaloguj się kontem Homey.","Weekdot에서 설정 › Homey를 열고 Homey 계정으로 로그인하세요.","في Weekdot افتح الإعدادات › Homey وسجّل الدخول بحساب Homey."),
 "settings.step3": T("Choose this Homey. Weekdot then sends your events of the coming 8 days.","Kies deze Homey. Weekdot stuurt dan je afspraken van de komende 8 dagen.","Wähle diesen Homey. Weekdot sendet dann deine Termine der nächsten 8 Tage.","Choisissez ce Homey. Weekdot envoie alors vos événements des 8 prochains jours.","Scegli questo Homey. Weekdot invierà gli eventi dei prossimi 8 giorni.","Välj den här Homey. Weekdot skickar sedan dina händelser för de kommande 8 dagarna.","Velg denne Homey. Weekdot sender da avtalene for de neste 8 dagene.","Elige este Homey. Weekdot enviará tus eventos de los próximos 8 días.","Vælg denne Homey. Weekdot sender så dine begivenheder for de næste 8 dage.","Выберите этот Homey. Weekdot отправит события на 8 дней вперёд.","Wybierz ten Homey. Weekdot wyśle wydarzenia z najbliższych 8 dni.","이 Homey를 선택하세요. Weekdot이 다음 8일의 일정을 보냅니다.","اختر جهاز Homey هذا. سيرسل Weekdot مواعيد الأيام الثمانية القادمة."),
 "settings.privacy": T("Your events are only stored on this Homey.","Je afspraken worden alleen op deze Homey bewaard.","Deine Termine werden nur auf diesem Homey gespeichert.","Vos événements sont stockés uniquement sur ce Homey.","I tuoi eventi sono salvati solo su questo Homey.","Dina händelser sparas bara på den här Homey.","Avtalene dine lagres bare på denne Homey.","Tus eventos solo se guardan en este Homey.","Dine begivenheder gemmes kun på denne Homey.","События хранятся только на этом Homey.","Wydarzenia są przechowywane tylko na tym Homey.","일정은 이 Homey에만 저장됩니다.","تُحفظ مواعيدك على جهاز Homey هذا فقط."),
 "settings.clear": T("Remove events from Homey","Afspraken van Homey verwijderen","Termine von Homey entfernen","Supprimer les événements de Homey","Rimuovi gli eventi da Homey","Ta bort händelser från Homey","Fjern avtaler fra Homey","Eliminar eventos de Homey","Fjern begivenheder fra Homey","Удалить события с Homey","Usuń wydarzenia z Homey","Homey에서 일정 삭제","إزالة المواعيد من Homey"),
 "settings.cleared": T("Removed.","Verwijderd.","Entfernt.","Supprimé.","Rimosso.","Borttaget.","Fjernet.","Eliminado.","Fjernet.","Удалено.","Usunięto.","삭제됨.","تمت الإزالة."),
 "settings.website": T("More about Weekdot","Meer over Weekdot","Mehr über Weekdot","En savoir plus sur Weekdot","Scopri Weekdot","Mer om Weekdot","Mer om Weekdot","Más sobre Weekdot","Mere om Weekdot","Подробнее о Weekdot","Więcej o Weekdot","Weekdot 자세히 보기","المزيد عن Weekdot"),
 # widget
 "widget.today": S["today"],
 "widget.tomorrow": S["tomorrow"],
 "widget.nothing": T("Nothing planned","Niets gepland","Nichts geplant","Rien de prévu","Niente in programma","Inget planerat","Ingenting planlagt","Nada previsto","Intet planlagt","Ничего не запланировано","Nic nie zaplanowano","일정 없음","لا شيء مخطط"),
 "widget.not_linked": T("Open Weekdot on your iPhone and link your Homey under Settings › Homey.","Open Weekdot op je iPhone en koppel je Homey bij Instellingen › Homey.","Öffne Weekdot auf dem iPhone und verbinde Homey unter Einstellungen › Homey.","Ouvrez Weekdot sur l'iPhone et liez Homey dans Réglages › Homey.","Apri Weekdot sull'iPhone e collega Homey in Impostazioni › Homey.","Öppna Weekdot på iPhone och länka Homey under Inställningar › Homey.","Åpne Weekdot på iPhone og koble til Homey under Innstillinger › Homey.","Abre Weekdot en el iPhone y vincula Homey en Ajustes › Homey.","Åbn Weekdot på iPhone, og forbind Homey under Indstillinger › Homey.","Откройте Weekdot на iPhone и подключите Homey в Настройки › Homey.","Otwórz Weekdot na iPhonie i połącz Homey w Ustawienia › Homey.","iPhone에서 Weekdot을 열고 설정 › Homey에서 Homey를 연결하세요.","افتح Weekdot على iPhone واربط Homey من الإعدادات › Homey."),
 "widget.all_day": T("All day","Hele dag","Ganztägig","Journée","Tutto il giorno","Heldag","Hele dagen","Todo el día","Hele dagen","Весь день","Cały dzień","하루 종일","طوال اليوم"),
 "widget.now": T("Now","Nu","Jetzt","Maintenant","Adesso","Nu","Nå","Ahora","Nu","Сейчас","Teraz","지금","الآن"),
}

W = {  # widget compose strings
 "w_name": T("Agenda","Agenda","Termine","Agenda","Agenda","Agenda","Agenda","Agenda","Program","План","Plan","일정","جدول المواعيد"),
 "w_days": T("Show","Toon","Anzeigen","Afficher","Mostra","Visa","Vis","Mostrar","Vis","Показывать","Pokaż","표시","عرض"),
 "w_today": S["today"],
 "w_today_tomorrow": T("Today and tomorrow","Vandaag en morgen","Heute und morgen","Aujourd'hui et demain","Oggi e domani","Idag och imorgon","I dag og i morgen","Hoy y mañana","I dag og i morgen","Сегодня и завтра","Dzisiaj i jutro","오늘과 내일","اليوم وغدًا"),
 "w_allday": T("Show all-day events","Toon hele-dag-afspraken","Ganztägige Termine anzeigen","Afficher les événements sur la journée","Mostra eventi di tutto il giorno","Visa heldagshändelser","Vis heldagsavtaler","Mostrar eventos de todo el día","Vis heldagsbegivenheder","Показывать события на весь день","Pokaż wydarzenia całodniowe","하루 종일 일정 표시","عرض مواعيد اليوم الكامل"),
}

TAGS = {
 "en": ["weekdot","calendar","agenda","events","appointments","schedule","planner","week","today","tomorrow","reminders","iphone","ipad","mac","apple watch","ios","icloud","google calendar","outlook","holidays","school holidays","waste collection","sports","presence","routine","morning","notifications","widget"],
 "nl": ["weekdot","agenda","kalender","afspraken","planning","planner","week","vandaag","morgen","herinneringen","iphone","ipad","mac","apple watch","ios","icloud","google agenda","outlook","feestdagen","schoolvakanties","afvalkalender","sport","aanwezigheid","routine","ochtend","meldingen","widget"],
 "de": ["weekdot","kalender","termine","agenda","planer","woche","heute","morgen","erinnerungen","iphone","ipad","mac","apple watch","ios","icloud","google kalender","outlook","feiertage","schulferien","müllabfuhr","sport","routine","widget"],
 "fr": ["weekdot","calendrier","agenda","événements","rendez-vous","planning","semaine","aujourd'hui","demain","rappels","iphone","ipad","mac","apple watch","ios","icloud","google agenda","outlook","jours fériés","vacances scolaires","collecte des déchets","sport","routine","widget"],
 "it": ["weekdot","calendario","agenda","eventi","appuntamenti","planner","settimana","oggi","domani","promemoria","iphone","ipad","mac","apple watch","ios","icloud","google calendar","outlook","festività","vacanze scolastiche","raccolta rifiuti","sport","routine","widget"],
 "sv": ["weekdot","kalender","agenda","händelser","möten","planering","vecka","idag","imorgon","påminnelser","iphone","ipad","mac","apple watch","ios","icloud","google kalender","outlook","helgdagar","skollov","sophämtning","sport","rutin","widget"],
 "no": ["weekdot","kalender","agenda","avtaler","hendelser","planlegging","uke","i dag","i morgen","påminnelser","iphone","ipad","mac","apple watch","ios","icloud","google kalender","outlook","helligdager","skoleferie","søppeltømming","sport","rutine","widget"],
 "es": ["weekdot","calendario","agenda","eventos","citas","planificador","semana","hoy","mañana","recordatorios","iphone","ipad","mac","apple watch","ios","icloud","google calendar","outlook","festivos","vacaciones escolares","recogida de basura","deportes","rutina","widget"],
 "da": ["weekdot","kalender","program","begivenheder","aftaler","planlægning","uge","i dag","i morgen","påmindelser","iphone","ipad","mac","apple watch","ios","icloud","google kalender","outlook","helligdage","skoleferie","affaldsafhentning","sport","rutine","widget"],
 "ru": ["weekdot","календарь","расписание","события","встречи","планировщик","неделя","сегодня","завтра","напоминания","iphone","ipad","mac","apple watch","ios","icloud","google календарь","outlook","праздники","каникулы","вывоз мусора","спорт","рутина","виджет"],
 "pl": ["weekdot","kalendarz","plan","wydarzenia","spotkania","planer","tydzień","dzisiaj","jutro","przypomnienia","iphone","ipad","mac","apple watch","ios","icloud","kalendarz google","outlook","święta","ferie","wywóz śmieci","sport","rutyna","widżet"],
 "ko": ["weekdot","캘린더","일정","이벤트","약속","플래너","주간","오늘","내일","미리 알림","iphone","ipad","mac","apple watch","ios","icloud","구글 캘린더","outlook","공휴일","방학","분리수거","스포츠","루틴","위젯"],
 "ar": ["weekdot","تقويم","مواعيد","أحداث","اجتماعات","مخطط","أسبوع","اليوم","غدًا","تذكيرات","iphone","ipad","mac","apple watch","ios","icloud","تقويم جوجل","outlook","عطلات رسمية","عطلات مدرسية","جمع النفايات","رياضة","روتين","أداة"],
}

README = {
 "en": """Weekdot brings your calendar to Homey.

Weekdot is the free calendar app for iPhone, iPad, Mac and Apple Watch. Link it to Homey and use your events in Flows: turn on the heating before your first appointment, get a reminder when it is time to leave, hear today's agenda in the morning, or let Homey know when a holiday or waste collection day is coming up.

Flows
• When: an event starts, an event ends, an event starts in … minutes, today's agenda at a set time, Weekdot sent new events
• And: there is an event right now, today or tomorrow (optionally in one calendar or with a word in the title)
• Then: get the next event, get the agenda of today or tomorrow (with tokens for Advanced Flows)

Also available: the tokens "Next event", "Next event (time)" and "Events today", and an Agenda widget for your dashboard.

How to link
1. Install Weekdot on your iPhone, iPad or Mac (weekdot.com).
2. In Weekdot, open Settings › Homey and sign in with your Homey account.
3. Choose your Homey. Weekdot sends your events of the coming 8 days and keeps them up to date.

Your events are only sent to your own Homey. You choose which calendars are shared and can hide titles and places.""",
 "nl": """Weekdot brengt je agenda naar Homey.

Weekdot is de gratis agenda-app voor iPhone, iPad, Mac en Apple Watch. Koppel hem aan Homey en gebruik je afspraken in Flows: zet de verwarming aan voor je eerste afspraak, krijg een seintje als je moet vertrekken, hoor 's ochtends je dagagenda, of laat Homey weten dat er een feestdag of afvalophaling aankomt.

Flows
• Als: een afspraak begint, een afspraak eindigt, een afspraak begint over … minuten, de dagagenda op een vast tijdstip, Weekdot heeft nieuwe afspraken gestuurd
• En: er is nu, vandaag of morgen een afspraak (eventueel in één agenda of met een woord in de titel)
• Dan: haal de volgende afspraak op, haal de agenda van vandaag of morgen op (met tags voor Geavanceerde Flows)

Ook beschikbaar: de tags "Volgende afspraak", "Volgende afspraak (tijd)" en "Afspraken vandaag", en een Agenda-widget voor je dashboard.

Zo koppel je
1. Installeer Weekdot op je iPhone, iPad of Mac (weekdot.com).
2. Open in Weekdot Instellingen › Homey en log in met je Homey-account.
3. Kies je Homey. Weekdot stuurt je afspraken van de komende 8 dagen en houdt ze bij.

Je afspraken gaan alleen naar je eigen Homey. Je kiest zelf welke agenda's worden gedeeld en kunt titels en locaties verbergen.""",
 "de": """Weekdot bringt deinen Kalender zu Homey.

Weekdot ist die kostenlose Kalender-App für iPhone, iPad, Mac und Apple Watch. Verbinde sie mit Homey und nutze deine Termine in Flows: Heizung vor dem ersten Termin einschalten, Bescheid bekommen, wenn du losmusst, morgens deine Tagesübersicht hören oder Homey wissen lassen, dass ein Feiertag oder die Müllabfuhr ansteht.

Flows
• Wenn: ein Termin beginnt, ein Termin endet, ein Termin beginnt in … Minuten, Tagesübersicht zu einer festen Uhrzeit, Weekdot hat neue Termine gesendet
• Und: gerade, heute oder morgen gibt es einen Termin (optional in einem Kalender oder mit einem Wort im Titel)
• Dann: nächsten Termin abrufen, Termine von heute oder morgen abrufen (mit Tags für Advanced Flows)

Außerdem: die Tags „Nächster Termin“, „Nächster Termin (Uhrzeit)“ und „Termine heute“ sowie ein Termine-Widget fürs Dashboard.

So verbindest du
1. Installiere Weekdot auf iPhone, iPad oder Mac (weekdot.com).
2. Öffne in Weekdot Einstellungen › Homey und melde dich mit deinem Homey-Konto an.
3. Wähle deinen Homey. Weekdot sendet deine Termine der nächsten 8 Tage und hält sie aktuell.

Deine Termine gehen nur an deinen eigenen Homey. Du wählst, welche Kalender geteilt werden, und kannst Titel und Orte ausblenden.""",
 "fr": """Weekdot amène votre calendrier dans Homey.

Weekdot est l'app de calendrier gratuite pour iPhone, iPad, Mac et Apple Watch. Liez-la à Homey et utilisez vos événements dans des Flows : allumez le chauffage avant votre premier rendez-vous, soyez prévenu quand il faut partir, écoutez l'agenda du jour le matin ou informez Homey d'un jour férié ou d'une collecte des déchets.

Flows
• Quand : un événement commence, un événement se termine, un événement commence dans … minutes, l'agenda du jour à heure fixe, Weekdot a envoyé de nouveaux événements
• Et : il y a un événement en ce moment, aujourd'hui ou demain (éventuellement dans un calendrier ou avec un mot dans le titre)
• Alors : obtenir le prochain événement, obtenir l'agenda d'aujourd'hui ou de demain (avec des tags pour les Flows avancés)

Également : les tags « Prochain événement », « Prochain événement (heure) » et « Événements aujourd'hui », et un widget Agenda pour votre tableau de bord.

Comment lier
1. Installez Weekdot sur iPhone, iPad ou Mac (weekdot.com).
2. Dans Weekdot, ouvrez Réglages › Homey et connectez-vous avec votre compte Homey.
3. Choisissez votre Homey. Weekdot envoie vos événements des 8 prochains jours et les tient à jour.

Vos événements ne sont envoyés qu'à votre propre Homey. Vous choisissez les calendriers partagés et pouvez masquer titres et lieux.""",
 "it": """Weekdot porta il tuo calendario in Homey.

Weekdot è l'app calendario gratuita per iPhone, iPad, Mac e Apple Watch. Collegala a Homey e usa i tuoi eventi nei Flow: accendi il riscaldamento prima del primo appuntamento, ricevi un avviso quando è ora di uscire, ascolta l'agenda del giorno al mattino o fai sapere a Homey che arriva una festività o la raccolta rifiuti.

Flow
• Quando: un evento inizia, un evento finisce, un evento inizia tra … minuti, l'agenda del giorno a un orario fisso, Weekdot ha inviato nuovi eventi
• E: c'è un evento adesso, oggi o domani (facoltativamente in un calendario o con una parola nel titolo)
• Allora: ottieni il prossimo evento, ottieni l'agenda di oggi o domani (con tag per i Flow avanzati)

Inoltre: i tag "Prossimo evento", "Prossimo evento (ora)" ed "Eventi di oggi" e un widget Agenda per la dashboard.

Come collegare
1. Installa Weekdot su iPhone, iPad o Mac (weekdot.com).
2. In Weekdot apri Impostazioni › Homey e accedi con il tuo account Homey.
3. Scegli il tuo Homey. Weekdot invia gli eventi dei prossimi 8 giorni e li mantiene aggiornati.

I tuoi eventi vengono inviati solo al tuo Homey. Scegli tu quali calendari condividere e puoi nascondere titoli e luoghi.""",
 "sv": """Weekdot tar med din kalender till Homey.

Weekdot är den kostnadsfria kalenderappen för iPhone, iPad, Mac och Apple Watch. Länka den till Homey och använd dina händelser i Flows: sätt på värmen före ditt första möte, få en påminnelse när det är dags att gå, hör dagens agenda på morgonen eller låt Homey veta att en helgdag eller sophämtning närmar sig.

Flows
• När: en händelse börjar, en händelse slutar, en händelse börjar om … minuter, dagens agenda vid en viss tid, Weekdot skickade nya händelser
• Och: det finns en händelse nu, idag eller imorgon (valfritt i en kalender eller med ett ord i titeln)
• Då: hämta nästa händelse, hämta agendan för idag eller imorgon (med taggar för avancerade Flows)

Dessutom: taggarna "Nästa händelse", "Nästa händelse (tid)" och "Händelser idag" samt en Agenda-widget för din instrumentpanel.

Så länkar du
1. Installera Weekdot på iPhone, iPad eller Mac (weekdot.com).
2. Öppna Inställningar › Homey i Weekdot och logga in med ditt Homey-konto.
3. Välj din Homey. Weekdot skickar dina händelser för de kommande 8 dagarna och håller dem uppdaterade.

Dina händelser skickas bara till din egen Homey. Du väljer vilka kalendrar som delas och kan dölja titlar och platser.""",
 "no": """Weekdot tar kalenderen din til Homey.

Weekdot er den gratis kalenderappen for iPhone, iPad, Mac og Apple Watch. Koble den til Homey og bruk avtalene dine i Flows: slå på varmen før første avtale, få beskjed når du må dra, hør dagens agenda om morgenen eller la Homey vite at en helligdag eller søppeltømming nærmer seg.

Flows
• Når: en avtale starter, en avtale slutter, en avtale starter om … minutter, dagens agenda på et fast tidspunkt, Weekdot sendte nye avtaler
• Og: det er en avtale nå, i dag eller i morgen (eventuelt i én kalender eller med et ord i tittelen)
• Så: hent neste avtale, hent agendaen for i dag eller i morgen (med tagger for avanserte Flows)

I tillegg: taggene «Neste avtale», «Neste avtale (tid)» og «Avtaler i dag», og en Agenda-widget for dashbordet.

Slik kobler du
1. Installer Weekdot på iPhone, iPad eller Mac (weekdot.com).
2. Åpne Innstillinger › Homey i Weekdot og logg inn med Homey-kontoen din.
3. Velg din Homey. Weekdot sender avtalene for de neste 8 dagene og holder dem oppdatert.

Avtalene dine sendes bare til din egen Homey. Du velger hvilke kalendere som deles og kan skjule titler og steder.""",
 "es": """Weekdot lleva tu calendario a Homey.

Weekdot es la app de calendario gratuita para iPhone, iPad, Mac y Apple Watch. Vincúlala a Homey y usa tus eventos en Flows: enciende la calefacción antes de tu primera cita, recibe un aviso cuando debas salir, escucha la agenda del día por la mañana o avisa a Homey de un festivo o de la recogida de basura.

Flows
• Cuando: empieza un evento, termina un evento, un evento empieza en … minutos, la agenda del día a una hora fija, Weekdot envió eventos nuevos
• Y: hay un evento ahora, hoy o mañana (opcionalmente en un calendario o con una palabra en el título)
• Entonces: obtener el próximo evento, obtener la agenda de hoy o mañana (con etiquetas para Flows avanzados)

Además: las etiquetas «Próximo evento», «Próximo evento (hora)» y «Eventos de hoy», y un widget Agenda para tu panel.

Cómo vincular
1. Instala Weekdot en iPhone, iPad o Mac (weekdot.com).
2. En Weekdot, abre Ajustes › Homey e inicia sesión con tu cuenta de Homey.
3. Elige tu Homey. Weekdot envía tus eventos de los próximos 8 días y los mantiene al día.

Tus eventos solo se envían a tu propio Homey. Tú eliges qué calendarios se comparten y puedes ocultar títulos y lugares.""",
 "da": """Weekdot bringer din kalender til Homey.

Weekdot er den gratis kalenderapp til iPhone, iPad, Mac og Apple Watch. Forbind den med Homey, og brug dine begivenheder i Flows: tænd for varmen før din første aftale, få besked når du skal af sted, hør dagens program om morgenen, eller lad Homey vide at der kommer en helligdag eller affaldsafhentning.

Flows
• Når: en begivenhed starter, en begivenhed slutter, en begivenhed starter om … minutter, dagens program på et fast tidspunkt, Weekdot sendte nye begivenheder
• Og: der er en begivenhed nu, i dag eller i morgen (eventuelt i én kalender eller med et ord i titlen)
• Så: hent næste begivenhed, hent programmet for i dag eller i morgen (med tags til avancerede Flows)

Desuden: taggene "Næste begivenhed", "Næste begivenhed (tid)" og "Begivenheder i dag" samt en Program-widget til dit dashboard.

Sådan forbinder du
1. Installer Weekdot på iPhone, iPad eller Mac (weekdot.com).
2. Åbn Indstillinger › Homey i Weekdot, og log ind med din Homey-konto.
3. Vælg din Homey. Weekdot sender dine begivenheder for de næste 8 dage og holder dem opdateret.

Dine begivenheder sendes kun til din egen Homey. Du vælger, hvilke kalendere der deles, og kan skjule titler og steder.""",
 "ru": """Weekdot переносит ваш календарь в Homey.

Weekdot — бесплатное приложение-календарь для iPhone, iPad, Mac и Apple Watch. Подключите его к Homey и используйте события во Flow: включайте отопление перед первой встречей, получайте напоминание, когда пора выходить, слушайте план на день утром или сообщайте Homey о праздниках и днях вывоза мусора.

Flow
• Когда: событие начинается, событие заканчивается, событие начнётся через … минут, план на день в заданное время, Weekdot отправил новые события
• И: событие идёт сейчас, есть сегодня или завтра (по желанию в одном календаре или со словом в названии)
• Тогда: получить следующее событие, получить план на сегодня или завтра (с тегами для расширенных Flow)

Также: теги «Следующее событие», «Следующее событие (время)» и «События сегодня» и виджет «План» для панели.

Как подключить
1. Установите Weekdot на iPhone, iPad или Mac (weekdot.com).
2. В Weekdot откройте Настройки › Homey и войдите в аккаунт Homey.
3. Выберите свой Homey. Weekdot отправит события на 8 дней вперёд и будет их обновлять.

События отправляются только на ваш Homey. Вы выбираете, какие календари передавать, и можете скрыть названия и места.""",
 "pl": """Weekdot przenosi Twój kalendarz do Homey.

Weekdot to darmowa aplikacja kalendarza na iPhone'a, iPada, Maca i Apple Watch. Połącz ją z Homey i używaj wydarzeń we Flow: włącz ogrzewanie przed pierwszym spotkaniem, dostań przypomnienie, gdy trzeba wychodzić, posłuchaj rano planu dnia albo daj Homey znać o święcie lub wywozie śmieci.

Flow
• Gdy: wydarzenie się zaczyna, wydarzenie się kończy, wydarzenie zacznie się za … minut, plan dnia o ustalonej godzinie, Weekdot wysłał nowe wydarzenia
• I: trwa wydarzenie, jest wydarzenie dzisiaj lub jutro (opcjonalnie w jednym kalendarzu lub ze słowem w tytule)
• Wtedy: pobierz następne wydarzenie, pobierz plan na dziś lub jutro (z tagami dla zaawansowanych Flow)

Dodatkowo: tagi „Następne wydarzenie”, „Następne wydarzenie (godzina)” i „Wydarzenia dzisiaj” oraz widżet Plan na pulpit.

Jak połączyć
1. Zainstaluj Weekdot na iPhonie, iPadzie lub Macu (weekdot.com).
2. W Weekdot otwórz Ustawienia › Homey i zaloguj się kontem Homey.
3. Wybierz swój Homey. Weekdot wyśle wydarzenia z najbliższych 8 dni i będzie je aktualizować.

Wydarzenia trafiają tylko do Twojego Homey. Sam wybierasz udostępniane kalendarze i możesz ukryć tytuły i miejsca.""",
 "ko": """Weekdot이 캘린더를 Homey로 가져옵니다.

Weekdot은 iPhone, iPad, Mac, Apple Watch용 무료 캘린더 앱입니다. Homey와 연결하고 Flow에서 일정을 활용하세요: 첫 약속 전에 난방 켜기, 출발할 시간에 알림 받기, 아침에 오늘 일정 듣기, 공휴일이나 분리수거 날을 Homey에 알리기.

Flow
• 언제: 일정이 시작됨, 일정이 종료됨, … 분 후 일정 시작, 정해진 시간에 오늘 일정, Weekdot이 새 일정을 보냄
• 그리고: 지금, 오늘 또는 내일 일정이 있음(선택적으로 특정 캘린더나 제목의 단어로)
• 그러면: 다음 일정 가져오기, 오늘 또는 내일 일정 가져오기(고급 Flow용 태그 포함)

또한: "다음 일정", "다음 일정(시간)", "오늘 일정" 태그와 대시보드용 일정 위젯을 제공합니다.

연결 방법
1. iPhone, iPad 또는 Mac에 Weekdot을 설치하세요(weekdot.com).
2. Weekdot에서 설정 › Homey를 열고 Homey 계정으로 로그인하세요.
3. Homey를 선택하세요. Weekdot이 다음 8일의 일정을 보내고 최신 상태로 유지합니다.

일정은 내 Homey로만 전송됩니다. 공유할 캘린더를 직접 고르고 제목과 장소를 숨길 수 있습니다.""",
 "ar": """يجلب Weekdot تقويمك إلى Homey.

Weekdot هو تطبيق التقويم المجاني لأجهزة iPhone وiPad وMac وApple Watch. اربطه بـ Homey واستخدم مواعيدك في التدفقات: شغّل التدفئة قبل موعدك الأول، واحصل على تنبيه عندما يحين وقت المغادرة، واستمع إلى جدول يومك صباحًا، أو أخبر Homey بقدوم عطلة رسمية أو يوم جمع النفايات.

التدفقات
• عندما: يبدأ موعد، ينتهي موعد، يبدأ موعد بعد … دقيقة، جدول اليوم في وقت محدد، أرسل Weekdot مواعيد جديدة
• و: يوجد موعد الآن أو اليوم أو غدًا (اختياريًا في تقويم واحد أو بكلمة في العنوان)
• ثم: احصل على الموعد التالي، احصل على جدول اليوم أو الغد (مع وسوم للتدفقات المتقدمة)

وأيضًا: الوسوم "الموعد التالي" و"الموعد التالي (الوقت)" و"مواعيد اليوم"، وأداة جدول المواعيد للوحة التحكم.

طريقة الربط
1. ثبّت Weekdot على iPhone أو iPad أو Mac (weekdot.com).
2. في Weekdot افتح الإعدادات › Homey وسجّل الدخول بحساب Homey.
3. اختر جهاز Homey. يرسل Weekdot مواعيد الأيام الثمانية القادمة ويحدّثها باستمرار.

تُرسل مواعيدك إلى جهاز Homey الخاص بك فقط. أنت تختار التقويمات المشتركة ويمكنك إخفاء العناوين والأماكن.""",
}

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
 "settings.clear": T("Unlink and remove events","Ontkoppelen en afspraken verwijderen","Termine von Homey entfernen","Supprimer les événements de Homey","Rimuovi gli eventi da Homey","Ta bort händelser från Homey","Fjern avtaler fra Homey","Eliminar eventos de Homey","Fjern begivenheder fra Homey","Удалить события с Homey","Usuń wydarzenia z Homey","Homey에서 일정 삭제","إزالة المواعيد من Homey"),
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
 "en": """Let your calendar run your home. Your events of the coming days arrive on Homey, so Flows can start when an appointment begins or ends, minutes before an appointment, or with today's agenda. Filter on a calendar or a word in the title, use the tokens in Advanced Flow and add the Agenda widget to your dashboard.

Requires the free Weekdot app for iPhone, iPad or Mac. You choose which calendars are shared, and your events stay on your own Homey.

Questions and help with setting up can be found in the Homey Community topic of this app.""",
 "nl": """Laat je agenda je huis aansturen. Je afspraken van de komende dagen komen op Homey, zodat Flows kunnen starten als een afspraak begint of eindigt, een aantal minuten voor een afspraak, of met je dagagenda. Filter op een agenda of een woord in de titel, gebruik de tags in Geavanceerde Flows en zet de Agenda-widget op je dashboard.

Werkt met de gratis Weekdot-app voor iPhone, iPad of Mac. Je kiest zelf welke agenda's worden gedeeld en je afspraken blijven op je eigen Homey.

Vragen en hulp bij het instellen vind je in het Homey Community-topic van deze app.""",
 "de": """Lass deinen Kalender dein Zuhause steuern. Deine Termine der nächsten Tage kommen auf Homey, sodass Flows starten können, wenn ein Termin beginnt oder endet, einige Minuten vor einem Termin oder mit der Tagesübersicht. Filtere nach einem Kalender oder einem Wort im Titel, nutze die Tags in Advanced Flows und füge das Termine-Widget zum Dashboard hinzu.

Benötigt die kostenlose Weekdot-App für iPhone, iPad oder Mac. Du wählst, welche Kalender geteilt werden, und deine Termine bleiben auf deinem eigenen Homey.

Fragen und Hilfe bei der Einrichtung findest du im Homey Community-Thema dieser App.""",
 "fr": """Laissez votre calendrier piloter votre maison. Vos événements des prochains jours arrivent sur Homey, pour que des Flows démarrent quand un rendez-vous commence ou se termine, quelques minutes avant un rendez-vous, ou avec l'agenda du jour. Filtrez par calendrier ou par mot du titre, utilisez les tags dans les Flows avancés et ajoutez le widget Agenda à votre tableau de bord.

Nécessite l'app gratuite Weekdot pour iPhone, iPad ou Mac. Vous choisissez les calendriers partagés, et vos événements restent sur votre propre Homey.

Questions et aide à la configuration : consultez le sujet de cette app sur la Homey Community.""",
 "it": """Lascia che il calendario gestisca la tua casa. Gli eventi dei prossimi giorni arrivano su Homey, così i Flow possono partire quando un appuntamento inizia o finisce, qualche minuto prima di un appuntamento o con l'agenda del giorno. Filtra per calendario o per una parola nel titolo, usa i tag nei Flow avanzati e aggiungi il widget Agenda alla dashboard.

Richiede l'app gratuita Weekdot per iPhone, iPad o Mac. Scegli tu quali calendari condividere e i tuoi eventi restano sul tuo Homey.

Domande e aiuto per la configurazione si trovano nell'argomento di questa app sulla Homey Community.""",
 "sv": """Låt din kalender styra ditt hem. Dina händelser för de kommande dagarna hamnar på Homey, så att Flows kan starta när en händelse börjar eller slutar, några minuter före ett möte eller med dagens agenda. Filtrera på en kalender eller ett ord i titeln, använd taggarna i avancerade Flows och lägg till Agenda-widgeten på din instrumentpanel.

Kräver den kostnadsfria Weekdot-appen för iPhone, iPad eller Mac. Du väljer vilka kalendrar som delas, och dina händelser stannar på din egen Homey.

Frågor och hjälp med att komma igång finns i appens tråd på Homey Community.""",
 "no": """La kalenderen styre hjemmet ditt. Avtalene dine for de neste dagene kommer til Homey, slik at Flows kan starte når en avtale begynner eller slutter, noen minutter før en avtale, eller med dagens agenda. Filtrer på en kalender eller et ord i tittelen, bruk taggene i avanserte Flows og legg Agenda-widgeten på dashbordet.

Krever den gratis Weekdot-appen for iPhone, iPad eller Mac. Du velger hvilke kalendere som deles, og avtalene blir på din egen Homey.

Spørsmål og hjelp med oppsettet finner du i appens tråd på Homey Community.""",
 "es": """Deja que tu calendario controle tu casa. Tus eventos de los próximos días llegan a Homey, para que los Flows empiecen cuando una cita comienza o termina, unos minutos antes de una cita o con la agenda del día. Filtra por calendario o por una palabra del título, usa las etiquetas en los Flows avanzados y añade el widget Agenda a tu panel.

Requiere la app gratuita Weekdot para iPhone, iPad o Mac. Tú eliges qué calendarios se comparten y tus eventos se quedan en tu propio Homey.

Encontrarás preguntas y ayuda para la configuración en el tema de esta app en la Homey Community.""",
 "da": """Lad din kalender styre dit hjem. Dine begivenheder for de kommende dage kommer til Homey, så Flows kan starte, når en aftale begynder eller slutter, nogle minutter før en aftale eller med dagens program. Filtrer på en kalender eller et ord i titlen, brug taggene i avancerede Flows, og tilføj Program-widgeten til dit dashboard.

Kræver den gratis Weekdot-app til iPhone, iPad eller Mac. Du vælger, hvilke kalendere der deles, og dine begivenheder bliver på din egen Homey.

Spørgsmål og hjælp til opsætningen finder du i appens tråd på Homey Community.""",
 "ru": """Пусть календарь управляет вашим домом. События на ближайшие дни попадают в Homey, и Flow запускаются, когда встреча начинается или заканчивается, за несколько минут до встречи или вместе с планом на день. Фильтруйте по календарю или слову в названии, используйте теги в расширенных Flow и добавьте виджет «План» на панель.

Требуется бесплатное приложение Weekdot для iPhone, iPad или Mac. Вы сами выбираете, какие календари передавать, а события хранятся только на вашем Homey.

Вопросы и помощь с настройкой — в теме этого приложения на форуме Homey Community.""",
 "pl": """Niech kalendarz steruje Twoim domem. Wydarzenia z najbliższych dni trafiają do Homey, więc Flow mogą startować, gdy spotkanie się zaczyna lub kończy, kilka minut przed spotkaniem albo z planem dnia. Filtruj według kalendarza lub słowa w tytule, używaj tagów w zaawansowanych Flow i dodaj widżet Plan do pulpitu.

Wymaga darmowej aplikacji Weekdot na iPhone'a, iPada lub Maca. Sam wybierasz udostępniane kalendarze, a wydarzenia zostają na Twoim Homey.

Pytania i pomoc w konfiguracji znajdziesz w wątku tej aplikacji na Homey Community.""",
 "ko": """캘린더로 집을 움직여 보세요. 앞으로 며칠간의 일정이 Homey로 전달되어, 일정이 시작되거나 끝날 때, 일정 몇 분 전에, 또는 오늘 일정으로 Flow를 시작할 수 있습니다. 캘린더나 제목의 단어로 필터링하고, 고급 Flow에서 태그를 사용하고, 대시보드에 일정 위젯을 추가하세요.

iPhone, iPad 또는 Mac용 무료 Weekdot 앱이 필요합니다. 공유할 캘린더는 직접 선택하며, 일정은 내 Homey에만 저장됩니다.

질문과 설정 도움말은 Homey Community의 이 앱 주제에서 확인하세요.""",
 "ar": """دع تقويمك يدير منزلك. تصل مواعيد الأيام القادمة إلى Homey، فتبدأ التدفقات عند بدء موعد أو انتهائه، أو قبل الموعد ببضع دقائق، أو مع جدول اليوم. صفِّ حسب التقويم أو كلمة في العنوان، واستخدم الوسوم في التدفقات المتقدمة، وأضف أداة جدول المواعيد إلى لوحة التحكم.

يتطلب تطبيق Weekdot المجاني لأجهزة iPhone أو iPad أو Mac. أنت تختار التقويمات المشتركة، وتبقى مواعيدك على جهاز Homey الخاص بك.

تجد الأسئلة والمساعدة في الإعداد في موضوع هذا التطبيق على منتدى Homey Community.""",
}

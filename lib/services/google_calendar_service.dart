import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'google_http_client.dart';

class GoogleCalendarService {
  Future<String?> insertEvent(
    String title,
    DateTime startTime,
    GoogleSignInAccount user, {
    String? description,
  }) async {
    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);

    final calendarApi = calendar.CalendarApi(httpClient);

    final event = calendar.Event(
      summary: title,
      description: description,
      start: calendar.EventDateTime(
        dateTime: startTime,
        timeZone: "Asia/Jakarta",
      ),
      end: calendar.EventDateTime(
        dateTime: startTime.add(Duration(hours: 1)),
        timeZone: "Asia/Jakarta",
      ),
    );

    final createdEvent = await calendarApi.events.insert(event, "primary");
    return createdEvent.id;
  }

  Future<List<String>> getTodayEvents(GoogleSignInAccount user) async {
    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(httpClient);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final events = await calendarApi.events.list(
      "primary",
      timeMin: startOfDay.toUtc(),
      timeMax: endOfDay.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    List<String> titles = [];
    if (events.items != null) {
      for (var event in events.items!) {
        if (event.summary != null) {
          titles.add(event.summary!);
        }
      }
    }
    return titles;
  }

  Future<void> updateEvent(
    String eventId,
    String title,
    DateTime startTime,
    GoogleSignInAccount user, {
    String? description,
  }) async {
    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(httpClient);
    final event = calendar.Event(
      summary: title,
      description: description,
      start: calendar.EventDateTime(
        dateTime: startTime,
        timeZone: "Asia/Jakarta",
      ),
      end: calendar.EventDateTime(
        dateTime: startTime.add(Duration(hours: 1)),
        timeZone: "Asia/Jakarta",
      ),
    );
    await calendarApi.events.patch(event, "primary", eventId);
  }

  Future<void> deleteEvent(String eventId, GoogleSignInAccount user) async {
    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(httpClient);
    await calendarApi.events.delete("primary", eventId);
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (currentUser == null) return;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('todoapp')
            .doc(currentUser!.uid)
            .collection('todos')
            .get();
    final events = <DateTime, List<Map<String, dynamic>>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      DateTime? date;
      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      } else if (createdAt is DateTime) {
        date = createdAt;
      }
      if (date != null) {
        final day = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(day, () => []).add({...data, 'id': doc.id});
      }
    }
    setState(() {
      _events = events;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalender',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Container(
        color: const Color(0xFFF6F8FA),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFFB3D4FC),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      todayTextStyle: TextStyle(
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color(0xFF4A90E2),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.event_note, color: Color(0xFF4A90E2)),
                  const SizedBox(width: 8),
                  Text(
                    'Task pada ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    _selectedDay != null
                        ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                        : '${_focusedDay.day}/${_focusedDay.month}/${_focusedDay.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    _getEventsForDay(_selectedDay ?? _focusedDay).isEmpty
                        ? Center(
                          child: Text(
                            'Tidak ada task pada hari ini',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                        : ListView.separated(
                          itemCount:
                              _getEventsForDay(
                                _selectedDay ?? _focusedDay,
                              ).length,
                          separatorBuilder:
                              (context, i) =>
                                  Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, i) {
                            final event =
                                _getEventsForDay(
                                  _selectedDay ?? _focusedDay,
                                )[i];
                            return ListTile(
                              leading: Icon(
                                event['isDone'] == true
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color:
                                    event['isDone'] == true
                                        ? Colors.green
                                        : Color(0xFF4A90E2),
                              ),
                              title: Text(
                                event['task'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      event['isDone'] == true
                                          ? Colors.green[700]
                                          : Colors.black,
                                  decoration:
                                      event['isDone'] == true
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                              ),
                              subtitle:
                                  event['description'] != null &&
                                          event['description']
                                              .toString()
                                              .isNotEmpty
                                      ? Text(event['description'])
                                      : null,
                              trailing:
                                  event['isDone'] == true
                                      ? null
                                      : Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey[400],
                                      ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

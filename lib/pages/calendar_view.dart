import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import '../main.dart';

class CalendarView extends StatelessWidget {
  final Map<String, double> dailyMiles;

  CalendarView({required this.dailyMiles});

  @override
  Widget build(BuildContext context) {
    final userStats = Provider.of<UserStatsProvider>(context);
    DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(userStats.accountCreationTime * 1000);

    DateTime firstDay = DateTime(creationDate.year, creationDate.month, creationDate.day);

    return Scaffold(
      appBar: createAppBar(context, 'Miles Biked Calendar'),
      body: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: firstDay,
        lastDay: DateTime.now(),
        availableGestures: AvailableGestures.none, 
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          todayBuilder: (context, date, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
          markerBuilder: (context, date, events) {
            final miles = dailyMiles[DateFormat('M-d-yyyy').format(date)] ?? 0;
            return Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: _getColorBasedOnMiles(miles),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  miles > 0 ? miles.toStringAsFixed(1) : '',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false, 
        ),
      ),
    );
  }

  Color _getColorBasedOnMiles(double miles) {
    if (miles == 0) return Colors.orange[200]!;
    else if (miles < 5) return Colors.orange[200]!;
    else if (miles < 10) return Colors.orange[500]!;
    else if (miles < 20) return Colors.orange[700]!;
    else return Colors.orange[900]!;
  }
}

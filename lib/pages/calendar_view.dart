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
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final miles = dailyMiles[DateFormat('M-d-yyyy').format(date)] ?? 0;
            return Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: _getColorBasedOnMiles(miles, context),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  miles > 0 ? miles.toStringAsFixed(0) : '',
                  style: TextStyle(color: Colors.white, fontSize: 14),
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

  Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color _getColorBasedOnMiles(double miles, BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark; 

    if (miles == 0) {
      return (isDarkMode ? darken(base, 0.1) : lighten(base, 0.1));
    } else if (miles < 10) {
      return (isDarkMode ? darken(base, 0.05): lighten(base, 0.05));
    } else if (miles < 20) {
      return base;
    } else if (miles < 40) {
      return (isDarkMode ? lighten(base, 0.05): darken(base, 0.05)) ;
    } else {
      return (isDarkMode ? lighten(base, 0.1): darken(base, 0.1));
    }
  }
}

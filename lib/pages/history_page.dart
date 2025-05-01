import 'package:cycle_guard_app/pages/routes_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'package:cycle_guard_app/data/trip_history_provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:cycle_guard_app/pages/calendar_view.dart';
import '../auth/dim_util.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedFilterIndex = -1;
  DateTimeRange? _selectedDateRange;

  ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TripHistoryProvider>(context, listen: false)
          .fetchTripHistory();
      Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats();
    });
  }

  Future<void> _pickDateRange(BuildContext context, DateTime firstDay) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDay,
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      keyboardType: TextInputType.text,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary,
              surface: isDarkMode ? Colors.grey[900]! : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black,
              onSurfaceVariant: isDarkMode ? Colors.white : Colors.black,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
              headerForegroundColor:
                  isDarkMode ? Colors.black : colorScheme.onPrimary,
              headerBackgroundColor:
                  isDarkMode ? colorScheme.secondary : colorScheme.primary,
              rangeSelectionBackgroundColor: isDarkMode
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.primaryContainer,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Map<String, double> _getDailyMiles(Map<int, SingleTripInfo> tripHistory) {
    Map<String, double> dailyMiles = {};

    tripHistory.forEach((timestamp, trip) {
      final tripDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final date = DateFormat('M-d-yyyy').format(tripDate);

      if (!dailyMiles.containsKey(date)) {
        dailyMiles[date] = 0;
      }
      dailyMiles[date] = dailyMiles[date]! + trip.distance;
    });

    return dailyMiles;
  }

  Widget _buildDetailRow(IconData icon, String text, Color color) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: DimUtil.safeWidth(context) * 1 / 80),
          Text(text,
              style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? Colors.grey[300]
                      : Theme.of(context).colorScheme.onPrimaryFixed)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tripHistoryProvider = Provider.of<TripHistoryProvider>(context);
    final userStatsProvider = Provider.of<UserStatsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(
        userStatsProvider.accountCreationTime * 1000);
    DateTime firstDay =
        DateTime(creationDate.year, creationDate.month, creationDate.day);
    final tripHistory = tripHistoryProvider.tripHistory;

    double totalCalories =
        tripHistory.values.fold(0.0, (sum, trip) => sum + trip.calories);

    int totalTrips = tripHistory.values.fold(0, (sum, trip) => sum + 1);

    Map<String, List<int>> groupedTrips = {};
    tripHistory.keys.forEach((timestamp) {
      final tripDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      if (_selectedDateRange == null ||
          (tripDate.isAfter(_selectedDateRange!.start) &&
              tripDate
                  .isBefore(_selectedDateRange!.end.add(Duration(days: 1))))) {
        final date = DateFormat('M-d-yyyy').format(tripDate);
        if (!groupedTrips.containsKey(date)) {
          groupedTrips[date] = [];
        }
        groupedTrips[date]!.add(timestamp);
      }
    });

    groupedTrips.forEach((date, timestamps) {
      timestamps.sort((a, b) => b.compareTo(a)); // Sort in descending order
    });

    // Sort dates in descending order by timestamp first (default behavior)
    final sortedDates = groupedTrips.keys.toList()
      ..sort((a, b) => DateFormat('M-d-yyyy')
          .parse(b)
          .compareTo(DateFormat('M-d-yyyy').parse(a)));
    // Function to sort trips based on the selected option (distance, time, or calories)
    List<int> getSortedTimestamps(List<int> timestamps) {
      if (_selectedFilterIndex == 0) {
        timestamps.sort((a, b) {
          final tripA = tripHistoryProvider.getTripByTimestamp(a);
          final tripB = tripHistoryProvider.getTripByTimestamp(b);
          return tripB!.time.compareTo(tripA!.time);
        });
      } else if (_selectedFilterIndex == 1) {
        timestamps.sort((a, b) {
          final tripA = tripHistoryProvider.getTripByTimestamp(a);
          final tripB = tripHistoryProvider.getTripByTimestamp(b);
          return tripB!.distance.compareTo(tripA!.distance);
        });
      } else if (_selectedFilterIndex == 2) {
        timestamps.sort((a, b) {
          final tripA = tripHistoryProvider.getTripByTimestamp(a);
          final tripB = tripHistoryProvider.getTripByTimestamp(b);
          return tripB!.calories.compareTo(tripA!.calories);
        });
      } else {
        // Default is timestamp sorting
        timestamps.sort((a, b) => b.compareTo(a));
      }

      return timestamps;
    }

    return Scaffold(
      appBar: createAppBar(context, 'Ride History'),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              elevation: 4,
              color: isDarkMode
                  ? colorScheme.onSecondaryFixedVariant
                  : colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'All Time Ride Summary',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: isDarkMode
                                ? colorScheme.surfaceContainerLow
                                : Colors.black),
                      ),
                    ),
                    SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Distance:',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '${userStatsProvider.totalDistance} mi',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Calories:',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '$totalCalories cal',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixed),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Time:',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '${userStatsProvider.totalTime} min',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rides:',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '$totalTrips',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? colorScheme.surfaceContainerLow
                                      : colorScheme.onPrimaryFixed),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await tripHistoryProvider.fetchTripHistory();

              // Check if the trip history is not null before proceeding
              if (tripHistoryProvider.tripHistory.isNotEmpty) {
                final dailyMiles =
                    _getDailyMiles(tripHistoryProvider.tripHistory);

                // Check if CalendarView is already on the navigation stack
                bool isCalendarInStack = false;

                // Loop through the current navigation stack
                Navigator.of(context).popUntil((route) {
                  if (route.settings.name == '/calendar') {
                    isCalendarInStack =
                        true; // CalendarView is already on the stack
                  }
                  return true;
                });

                // If it's not in the stack, push it
                if (!isCalendarInStack) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CalendarView(dailyMiles: dailyMiles),
                      settings: RouteSettings(name: '/calendar'),
                    ),
                  );
                }
              } else {
                // Handle the case where the trip history is null or empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No trip history available.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? colorScheme.onPrimaryFixedVariant
                  : colorScheme.surfaceContainerLow,
            ),
            child: Text(
              'View Miles Biked Calendar',
              style: TextStyle(
                color: isDarkMode
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.onSecondaryFixedVariant,
              ),
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Filter rides by:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
              ToggleButtons(
                isSelected: [
                  0 == _selectedFilterIndex,
                  1 == _selectedFilterIndex,
                  2 == _selectedFilterIndex
                ],
                onPressed: (int index) {
                  setState(() {
                    if (_selectedFilterIndex == index) {
                      _selectedFilterIndex = -1;
                    } else {
                      _selectedFilterIndex = index;
                    }
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('Duration',
                        style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.grey[300] : Colors.black)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('Distance',
                        style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.grey[300] : Colors.black)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('Calories',
                        style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.grey[300] : Colors.black)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: DimUtil.safeHeight(context) * 1 / 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colorScheme.onPrimaryFixedVariant
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedDateRange != null
                        ? Border.all(color: colorScheme.outline, width: 2)
                        : Border.all(color: Colors.transparent),
                  ),
                  child: OutlinedButton(
                    onPressed: () => _pickDateRange(context, firstDay),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selectedDateRange == null
                          ? 'Sort Date Range'
                          : '${DateFormat('M/d/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('M/d/yyyy').format(_selectedDateRange!.end)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? colorScheme.surfaceContainerLow
                            : colorScheme.onSecondaryFixedVariant,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: isDarkMode
                      ? colorScheme.surfaceContainerLow
                      : colorScheme.onSecondaryFixedVariant,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDateRange = null;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: DimUtil.safeHeight(context) * 1 / 60),
          groupedTrips.isEmpty
              ? Center(
                  child: Text(
                    'No trips recorded for the selected range.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Expanded(
                  child: Scrollbar(
                    controller: _controller,
                    thumbVisibility: true,
                    trackVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 8,
                    interactive: true,
                    child: CustomScrollView(
                      controller: _controller,
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final date = sortedDates[index];
                              final timestamps = groupedTrips[date]!;
                              final sortedTimestamps =
                                  getSortedTimestamps(timestamps);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  color: isDarkMode
                                      ? colorScheme.onSecondaryFixedVariant
                                      : colorScheme.surfaceContainerLow,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: ExpansionTile(
                                      shape: Border(),
                                      title: Row(
                                        children: [
                                          SizedBox(
                                              width:
                                                  DimUtil.safeWidth(context) *
                                                      1 /
                                                      80),
                                          Text(
                                            '$date',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: isDarkMode
                                                  ? colorScheme
                                                      .surfaceContainerLow
                                                  : Colors.black,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            '${sortedTimestamps.length} ride${sortedTimestamps.length > 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? colorScheme
                                                      .surfaceContainerLow
                                                  : colorScheme.onPrimaryFixed,
                                            ),
                                          ),
                                        ],
                                      ),
                                      collapsedIconColor: isDarkMode
                                          ? colorScheme.surfaceContainerLow
                                          : colorScheme.onPrimaryFixed,
                                      iconColor: isDarkMode
                                          ? colorScheme.surfaceContainerLow
                                          : colorScheme.onPrimaryFixed,
                                      children:
                                          sortedTimestamps.map((timestamp) {
                                        final trip = tripHistoryProvider
                                            .getTripByTimestamp(timestamp);
                                        if (trip == null) {
                                          return ListTile(
                                              title: Text(
                                                  'Trip data not available.'));
                                        }
                                        final tripDate =
                                            DateTime.fromMillisecondsSinceEpoch(
                                                timestamp * 1000);
                                        final formattedTime =
                                            DateFormat('h:mm a')
                                                .format(tripDate);

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 16),
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            color: isDarkMode
                                                ? colorScheme.secondary
                                                : colorScheme.onTertiary,
                                            child: ListTile(
                                              contentPadding:
                                                  EdgeInsets.all(16),
                                              title: Text(
                                                'Ride ${sortedTimestamps.indexOf(timestamp) + 1}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: isDarkMode
                                                      ? Colors.grey[300]
                                                      : colorScheme
                                                          .onPrimaryFixed,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildDetailRow(
                                                      Icons.access_time,
                                                      'Time: $formattedTime',
                                                      Colors.green),
                                                  _buildDetailRow(
                                                      Icons.directions_bike,
                                                      '${trip.distance} mi',
                                                      Colors.blueAccent),
                                                  _buildDetailRow(
                                                      Icons.timer,
                                                      '${trip.time} min',
                                                      Colors.orange),
                                                  _buildDetailRow(
                                                      Icons
                                                          .local_fire_department,
                                                      '${trip.calories} cal',
                                                      Colors.red),
                                                ],
                                              ),
                                              onTap: () {
                                                print(timestamp);
                                                selectedIndexGlobal.value = 0;
                                                setRouteTimestamp(timestamp);
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: groupedTrips.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

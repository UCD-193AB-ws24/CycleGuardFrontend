import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'package:cycle_guard_app/data/trip_history_provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
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
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TripHistoryProvider>(context, listen: false).fetchTripHistory();
      Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats();
    });
  }

Future<void> _pickDateRange(BuildContext context) async {
  
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2025), 
    lastDate: DateTime.now(), 
    initialDateRange: _selectedDateRange,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor: Theme.of(context).colorScheme.primary, 
          datePickerTheme: DatePickerThemeData(
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return Colors.orange;
            }),
            rangeSelectionBackgroundColor: Theme.of(context).colorScheme.onInverseSurface,
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tripHistoryProvider = Provider.of<TripHistoryProvider>(context);
    final userStatsProvider = Provider.of<UserStatsProvider>(context);
    final tripHistory = tripHistoryProvider.tripHistory;

    double totalCalories = tripHistory.values.fold(0.0, (sum, trip) => sum + trip.calories);

    int totalTrips = tripHistory.values.fold(0, (sum, trip) => sum + 1);

    Map<String, List<int>> groupedTrips = {};
    tripHistory.keys.forEach((timestamp) {
      final tripDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      if (_selectedDateRange == null ||
          (tripDate.isAfter(_selectedDateRange!.start) &&
              tripDate.isBefore(_selectedDateRange!.end.add(Duration(days: 1))))) {
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
      ..sort((a, b) => DateFormat('M-d-yyyy').parse(b).compareTo(DateFormat('M-d-yyyy').parse(a)));
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
      } else { // Default is timestamp sorting
        timestamps.sort((a, b) => b.compareTo(a));
      }

      return timestamps;
    }

    return Scaffold(
      appBar: createAppBar(context, 'Ride History'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              elevation: 4,
              color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Theme.of(context).colorScheme.surfaceContainerLow,
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Colors.black),
                      ),
                    ),
                    SizedBox(height: DimUtil.safeHeight(context)*1/80),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Distance:',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '${userStatsProvider.totalDistance} km',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context)*1/80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Calories:',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '$totalCalories cal',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context)*1/80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Time:',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '${userStatsProvider.totalTime} min',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context)*1/80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rides:',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                            ),
                            Text(
                              '$totalTrips',
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Filter rides by:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: DimUtil.safeHeight(context)*1/80),
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
                    child: Text('Duration', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[300] : Colors.black)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                    child: Text('Distance', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[300] : Colors.black)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0), 
                    child: Text('Calories', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[300] : Colors.black)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: DimUtil.safeHeight(context)*1/60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8), 
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedDateRange != null
                        ? Border.all(color: Theme.of(context).colorScheme.outline, width: 2)
                        : Border.all(color: Colors.transparent), 
                  ),
                  child: OutlinedButton(
                    onPressed: () => _pickDateRange(context),
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
                      style: TextStyle(fontSize: 16, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onSecondaryFixedVariant,),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onSecondaryFixedVariant,),
                onPressed: () {
                  setState(() {
                    _selectedDateRange = null;  
                  });
                },
              ),
            ],
          ),
          SizedBox(height: DimUtil.safeHeight(context)*1/60),
          groupedTrips.isEmpty
            ? Center(child: Text('No trips recorded for the selected range.', style: TextStyle(fontSize: 18, color: Colors.grey)))
            : Expanded(
              child: DraggableScrollbar.arrows (
                controller: _controller,
                backgroundColor: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onSecondaryFixedVariant,
                child: ListView.builder(
                  controller: _controller,
                  itemCount: groupedTrips.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final timestamps = groupedTrips[date]!;

                    final sortedTimestamps = getSortedTimestamps(timestamps);

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ExpansionTile(
                              shape: Border(),
                              title: Row(
                                children: [
                                  SizedBox(width: DimUtil.safeWidth(context)*1/80),
                                  Text(
                                    '$date',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                                      color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Colors.black,),
                                  ),
                                  Spacer(),
                                  Text(
                                    '${sortedTimestamps.length} ride${sortedTimestamps.length > 1 ? 's' : ''}',
                                    style: TextStyle(fontSize: 16, 
                                      color: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed),
                                  ),
                                ],
                              ),
                              collapsedIconColor: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed,  
                              iconColor: isDarkMode ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.onPrimaryFixed, 
                              children: [
                                ...sortedTimestamps.map((timestamp) {
                                  final trip = tripHistoryProvider.getTripByTimestamp(timestamp);
                                  if (trip == null) {
                                    return ListTile(
                                      title: Text('Trip data not available.'),
                                    );
                                  }
                                  final tripDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                                  final formattedTime = DateFormat('h:mm a').format(tripDate);
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    color: isDarkMode ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onTertiary,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text(
                                        'Ride ${sortedTimestamps.indexOf(timestamp) + 1}',
                                        style: TextStyle(fontSize: 16, color : isDarkMode ? Colors.grey[300] : Theme.of(context).colorScheme.onPrimaryFixed),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, color: Colors.green, size: 18),
                                              SizedBox(width: DimUtil.safeWidth(context)*1/80),
                                              Text('Time: $formattedTime', style: TextStyle(fontSize: 16, color : isDarkMode ? Colors.grey[300] : Theme.of(context).colorScheme.onPrimaryFixed)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.directions_bike, color: Colors.blueAccent, size: 18),
                                              SizedBox(width: DimUtil.safeWidth(context)*1/80),
                                              Text('${trip.distance} km', style: TextStyle(fontSize: 16, color : isDarkMode ? Colors.grey[300] : Theme.of(context).colorScheme.onPrimaryFixed)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.timer, color: Colors.orange, size: 18),
                                              SizedBox(width:DimUtil.safeWidth(context)*1/80),
                                              Text('${trip.time} min', style: TextStyle(fontSize: 16, color : isDarkMode ? Colors.grey[300] : Theme.of(context).colorScheme.onPrimaryFixed)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.local_fire_department, color: Colors.red, size: 18),
                                              SizedBox(width: DimUtil.safeWidth(context)*1/80),
                                              Text('${trip.calories} cal', style: TextStyle(fontSize: 16, color : isDarkMode ? Colors.grey[300] : Theme.of(context).colorScheme.onPrimaryFixed)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

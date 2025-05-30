import 'dart:developer' as developer;
import 'package:cycle_guard_app/pages/local_notifications.dart';
import 'package:cycle_guard_app/data/notifications_accessor.dart'
    as app_notifications;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScheduler extends StatefulWidget {
  const NotificationScheduler({Key? key}) : super(key: key);

  @override
  State<NotificationScheduler> createState() => _NotificationScheduler();
}

class _NotificationScheduler extends State<NotificationScheduler> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  app_notifications.Notification? _selectedNotification;
  List<app_notifications.Notification> _notifications = [];
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  // Properties for frequency and day of week
  int _selectedFrequency = 0; // Default: 0 = Daily
  int _selectedDayOfWeek =
      DateTime.now().weekday; // Default: Current day of week
  DateTime _selectedDate =
      DateTime.now(); // Default: Today's date for one-time notifications
  bool _showAllNotifications = false;
  final int _notificationLimit = 3;

  // Map frequency values to their names for display
  final Map<int, String> _frequencyNames = {
    0: 'Daily',
    1: 'Weekly',
    2: 'One-time'
  };

  // Map weekday values to their names for display
  final Map<int, String> _dayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _getNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
    BuildContext context,
    void Function(void Function()) dialogSetState,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDarkMode
                  ? colorScheme.onPrimaryFixed
                  : colorScheme.surfaceContainerLow,
              dialBackgroundColor: isDarkMode
                  ? colorScheme.onPrimaryFixedVariant
                  : colorScheme.primaryContainer,
              hourMinuteColor: isDarkMode
                  ? colorScheme.onPrimaryFixedVariant
                  : colorScheme.primaryContainer,
              dayPeriodColor: isDarkMode
                  ? colorScheme.onPrimaryFixedVariant
                  : colorScheme.primaryContainer,
              dialHandColor: colorScheme.primary,
              dialTextColor: isDarkMode ? Colors.white70 : Colors.black,
              hourMinuteTextColor: isDarkMode ? Colors.white70 : Colors.black,
              dayPeriodTextColor: isDarkMode ? Colors.white70 : Colors.black,
              entryModeIconColor: isDarkMode ? Colors.white70 : Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white70 : Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      dialogSetState(() {
        _selectedTime = picked;
      });

      // Also update parent if needed
      setState(() {});
    }
  }

  // New method to select date for one-time notifications
  Future<void> _selectDate(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: colorScheme.primary,
                    onPrimary: Colors.white,
                    surface: colorScheme.onPrimaryFixed,
                    onSurface: Colors.white70,
                  )
                : ColorScheme.light(
                    primary: colorScheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    isDarkMode ? Colors.white70 : colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _getNotifications() async {
    try {
      final result =
          await app_notifications.NotificationsAccessor.getNotifications();
      developer.log('Retrieved notifications: ${result.toString()}',
          name: 'NotificationButtons');

      setState(() {
        _notifications = result.notifications;
      });
    } catch (e) {
      developer.log('Error getting notifications: $e',
          name: 'NotificationButtons');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting notifications: $e')),
      );
    }
  }

  Future<bool> _addNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and body')),
      );
      return false;
    }

    // For one-time notifications, store date information in dayOfWeek field
    int dayOfWeek = _selectedDayOfWeek;
    int minute = _selectedTime.minute;
    int month = 0;

    if (_selectedFrequency == 2) {
      // One-time notification
      // For one-time, store date in these fields:
      dayOfWeek = _selectedDate.day; // Day of month
      month = _selectedDate.month; // Month
    }

    final notification = app_notifications.Notification(
      title: _titleController.text,
      body: _bodyController.text,
      hour: _selectedTime.hour,
      minute: minute,
      frequency: _selectedFrequency,
      dayOfWeek: dayOfWeek,
      month: month,
    );

    final int notificationId = notification.hour * 100000 +
        notification.minute * 1000 +
        notification.frequency * 100 +
        notification.dayOfWeek * 10 +
        notification.month;

    bool notificationExists = _notifications.any((existingNotification) {
      final existingNotificationId = existingNotification.hour * 100000 +
          existingNotification.minute * 1000 +
          existingNotification.frequency * 100 +
          existingNotification.dayOfWeek * 10 +
          existingNotification.month;

      return existingNotificationId == notificationId;
    });

    if (notificationExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Notification with these parameters already exists')),
      );
      return false;
    }

    try {
      final result =
          await app_notifications.NotificationsAccessor.addNotification(
              notification);
      developer.log('Added notification: ${notification.toString()}',
          name: 'NotificationButtons');
      developer.log('Updated notification list: ${result.toString()}',
          name: 'NotificationButtons');

      // Schedule local notification based on frequency
      await _scheduleNotificationBasedOnFrequency(notification);

      setState(() {
        _notifications = result.notifications;
        _titleController.clear();
        _bodyController.clear();
      });

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification added successfully')),
      );

      return true;
    } catch (e) {
      developer.log('Error adding notification: $e',
          name: 'NotificationButtons');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding notification: $e')),
      );
      return false;
    }
  }

  // New method to schedule notifications based on frequency
  Future<void> _scheduleNotificationBasedOnFrequency(
      app_notifications.Notification notification) async {
    // Create a unique ID for the notification
    final int notificationId = notification.hour * 100000 +
        notification.minute * 1000 +
        notification.frequency * 100 +
        notification.dayOfWeek * 10 +
        notification.month;

    switch (notification.frequency) {
      case 0: // Daily
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: notification.title,
          body: notification.body,
          hour: notification.hour,
          minute: notification.minute,
          matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
        );
        break;

      case 1: // Weekly
        await _notificationService.scheduleWeeklyNotification(
          id: notificationId,
          title: notification.title,
          body: notification.body,
          hour: notification.hour,
          minute: notification.minute,
          dayOfWeek: notification.dayOfWeek,
        );
        break;

      case 2: // One-time
        await _notificationService.scheduleOneTimeNotification(
          id: notificationId,
          title: notification.title,
          body: notification.body,
          hour: notification.hour,
          minute: notification.minute,
          year: _selectedDate.year,
          month: notification.month,
          day: notification.dayOfWeek,
        );
        break;
    }
  }

  Future<void> _deleteNotification() async {
    if (_selectedNotification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a notification to delete')),
      );
      return;
    }

    try {
      // Create the same ID for cancellation
      final int notificationId = _selectedNotification!.hour * 100000 +
          _selectedNotification!.minute * 1000 +
          _selectedNotification!.frequency * 100 +
          _selectedNotification!.dayOfWeek * 10 +
          _selectedNotification!.month;

      await _notificationService.cancelNotification(notificationId);

      final result =
          await app_notifications.NotificationsAccessor.deleteNotification(
              _selectedNotification!);
      developer.log('Deleted notification: ${_selectedNotification.toString()}',
          name: 'NotificationButtons');
      developer.log('Updated notification list: ${result.toString()}',
          name: 'NotificationButtons');

      setState(() {
        _notifications = result.notifications;
        _selectedNotification = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted successfully')),
      );
    } catch (e) {
      developer.log('Error deleting notification: $e',
          name: 'NotificationButtons');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  // Helper method to get description of notification frequency/timing
  String _getNotificationTimingDescription(
      app_notifications.Notification notification) {
    String timeStr =
        '${notification.hour}:${notification.minute.toString().padLeft(2, '0')}';

    switch (notification.frequency) {
      case 0: // Daily
        return 'Daily at $timeStr';
      case 1: // Weekly
        return '${_dayNames[notification.dayOfWeek]} at $timeStr';
      case 2: // One-time
        // For one-time notifications, dayOfWeek field stores the day of month
        // and minute field holds the month info
        final String dateStr =
            '${notification.month}/${notification.dayOfWeek}';
        return 'One-time on $dateStr at $timeStr';
      default:
        return 'At $timeStr';
    }
  }

  // Get icon for notification frequency
  IconData _getNotificationIcon(int frequency) {
    switch (frequency) {
      case 0: // Daily
        return Icons.repeat;
      case 1: // Weekly
        return Icons.calendar_view_week;
      case 2: // One-time
        return Icons.notifications_none;
      default:
        return Icons.notifications;
    }
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Notification Manager',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              if (_notifications.isEmpty)
                const Text(
                  'No Existing Notifications',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              if (_notifications.isNotEmpty)
                Column(
                  children: [
                    ..._notifications
                        .take(_showAllNotifications
                            ? _notifications.length
                            : _notificationLimit)
                        .map((notification) {
                      final isSelected = _selectedNotification == notification;
                      final notificationTiming =
                          _getNotificationTimingDescription(notification);
                      final notificationIcon =
                          _getNotificationIcon(notification.frequency);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Material(
                          elevation: 4,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isDarkMode
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onInverseSurface,
                          borderRadius: BorderRadius.circular(12.0),
                          child: ListTile(
                            leading: Icon(
                              notificationIcon,
                              color: isDarkMode ? Colors.white70 : Colors.black,
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  notificationTiming,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedNotification = notification;
                              });
                            },
                            isThreeLine: true,
                          ),
                        ),
                      );
                    }).toList(),
                    if (_notifications.length > _notificationLimit)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllNotifications = !_showAllNotifications;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAllNotifications ? 'See less' : 'See more',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showAllNotifications
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Add or Delete Notifications:',
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: isDarkMode
                              ? Colors.grey[900]
                              : null, // Background color
                          scrollable: true,
                          title: Text(
                            'Add Notification',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.black, // Title color
                            ),
                          ),
                          content: StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: _titleController,
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                    decoration: InputDecoration(
                                      labelText: 'Notification Title',
                                      labelStyle: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _bodyController,
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                    decoration: InputDecoration(
                                      labelText: 'Notification Body',
                                      labelStyle: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black),
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 10),
                                  ListTile(
                                    title: Text(
                                      'Notification Time: ${_selectedTime.format(context)}',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.access_time,
                                        color: isDarkMode ? Colors.white70 : null, 
                                      ),
                                      onPressed: () =>
                                          _selectTime(context, setState),
                                    ),
                                  ),
                                  ListTile(
                                    title: Text(
                                      'Frequency: ${_frequencyNames[_selectedFrequency]}',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black,
                                      ),
                                    ),
                                    trailing: DropdownButton<int>(
                                      value: _selectedFrequency,
                                      dropdownColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.white,
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedFrequency = newValue;
                                          });
                                        }
                                      },
                                      items: _frequencyNames.entries
                                          .map<DropdownMenuItem<int>>((entry) {
                                        return DropdownMenuItem<int>(
                                          value: entry.key,
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  if (_selectedFrequency == 1)
                                    ListTile(
                                      title: Text(
                                        'Day of Week: ${_dayNames[_selectedDayOfWeek]}',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black,
                                        ),
                                      ),
                                      trailing: DropdownButton<int>(
                                        value: _selectedDayOfWeek,
                                        dropdownColor: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.white,
                                        onChanged: (int? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedDayOfWeek = newValue;
                                            });
                                          }
                                        },
                                        items: _dayNames.entries
                                            .map<DropdownMenuItem<int>>(
                                                (entry) {
                                          return DropdownMenuItem<int>(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  if (_selectedFrequency == 2)
                                    ListTile(
                                      title: Text(
                                        'Date: ${_formatDate(_selectedDate)}',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(context),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                bool success = await _addNotification();
                                if (success) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Confirm'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _titleController.clear();
                                  _bodyController.clear();
                                });
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.add,
                    color: Colors.white70,
                  ),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _deleteNotification,
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white70,
                  ),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

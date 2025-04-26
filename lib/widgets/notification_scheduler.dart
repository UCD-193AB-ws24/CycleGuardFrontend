import 'dart:developer' as developer;
import 'package:cycle_guard_app/pages/local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_guard_app/data/notifications_accessor.dart' as app_notifications;
import 'package:flutter/material.dart';

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
  final LocalNotificationService _notificationService = LocalNotificationService();
  bool _isAddingNotification = false;

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

Future<void> _selectTime(BuildContext context) async {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _selectedTime,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: isDarkMode ? colorScheme.onPrimaryFixed : colorScheme.surfaceContainerLow,
            dialBackgroundColor: isDarkMode ? colorScheme.onPrimaryFixedVariant : colorScheme.primaryContainer,
            hourMinuteColor: isDarkMode ? colorScheme.onPrimaryFixedVariant : colorScheme.primaryContainer,
            dayPeriodColor: isDarkMode ? colorScheme.onPrimaryFixedVariant : colorScheme.primaryContainer,
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
    setState(() {
      _selectedTime = picked;
    });
  }
}

  /*
    To use getNotifications uncomment the button in build and the line in init
  */
  Future<void> _getNotifications() async {
    try {
      final result = await app_notifications.NotificationsAccessor.getNotifications();
      developer.log('Retrieved notifications: ${result.toString()}', name: 'NotificationButtons');
      
      setState(() {
        _notifications = result.notifications;
      });
      
      // Show a snackbar to indicate success
      /*if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retrieved ${result.notifications.length} notifications')),
      );*/
    } catch (e) {
      developer.log('Error getting notifications: $e', name: 'NotificationButtons');
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

    final notification = app_notifications.Notification(
      title: _titleController.text,
      body: _bodyController.text,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
    );

    try {
      final result = await app_notifications.NotificationsAccessor.addNotification(notification);
      developer.log('Added notification: ${notification.toString()}', name: 'NotificationButtons');
      developer.log('Updated notification list: ${result.toString()}', name: 'NotificationButtons');
      
      // Schedule local notification
      await _notificationService.scheduleNotification(
        id: notification.hour * 60 + notification.minute, // unique ID
        title: notification.title,
        body: notification.body,
        hour: notification.hour,
        minute: notification.minute,
      );

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
      developer.log('Error adding notification: $e', name: 'NotificationButtons');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding notification: $e')),
      );
      return false;
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
      await _notificationService.cancelNotification(_selectedNotification!.hour * 60 + _selectedNotification!.minute);

      final result = await app_notifications.NotificationsAccessor.deleteNotification(_selectedNotification!);
      developer.log('Deleted notification: ${_selectedNotification.toString()}', name: 'NotificationButtons');
      developer.log('Updated notification list: ${result.toString()}', name: 'NotificationButtons');
      
      setState(() {
        _notifications = result.notifications;
        _selectedNotification = null;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted successfully')),
      );
    } catch (e) {
      developer.log('Error deleting notification: $e', name: 'NotificationButtons');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).colorScheme.brightness == Brightness.dark; 
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Daily Notification Manager',
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
            //const SizedBox(height: 10),
            if (_notifications.isNotEmpty)
              SizedBox(
                child: Column(
                  children: _notifications.map((notification) {
                    final isSelected = _selectedNotification == notification;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Material(
                        elevation: 4,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isDarkMode
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onInverseSurface,
                        borderRadius: BorderRadius.circular(12.0),
                        child: ListTile(
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            notification.body,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black,
                            ),
                          ),
                          trailing: Text(
                            '${notification.hour}:${notification.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedNotification = notification;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
          const SizedBox(height: 20),
          Text(
            _isAddingNotification ? 'Create Notificaiton' : 'Add or Delete Notifications:',
            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isAddingNotification) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingNotification = true;
                    });
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
              /*ElevatedButton.icon(
                onPressed: _getNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Get'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
              ),*/
            ],
          ),
          const SizedBox(height: 20),

          if (_isAddingNotification) ...[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(
                'Notification Time: ${_selectedTime.format(context)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    bool success = await _addNotification();
                    if (success) {
                      setState(() {
                        _isAddingNotification = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Confirm'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isAddingNotification = false;
                      _titleController.clear();
                      _bodyController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
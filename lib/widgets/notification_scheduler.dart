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

  @override
  void initState() {
    super.initState();
    //_getNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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

  Future<void> _addNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and body')),
      );
      return;
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
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification added successfully')),
      );
    } catch (e) {
      developer.log('Error adding notification: $e', name: 'NotificationButtons');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding notification: $e')),
      );
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

          const Text(
            'Existing Notifications:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isSelected = _selectedNotification == notification;

                return ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  trailing: Text('${notification.hour}:${notification.minute.toString().padLeft(2, '0')}'),
                  tileColor: isSelected ? Colors.blue.withOpacity(0.2) : null,
                  onTap: () {
                    setState(() {
                      _selectedNotification = notification;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _addNotification,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _deleteNotification,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
              ),
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
            title: Text('Notification Time: ${_selectedTime.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(context),
          ),
        ],
      ),
    );
  }
}

/*class NotificationScheduler extends StatefulWidget {
  @override
  State<NotificationScheduler> createState() => _NotificationSchedulerState();
}

class _NotificationSchedulerState extends State<NotificationScheduler> {
  final LocalNotificationService _notificationService = LocalNotificationService();
  final List<model.Notification> _scheduledNotifications = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 40),
        Text(
          "Daily Reminder",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _showScheduleNotificationDialog(context),
          child: Text("Schedule"),
        ),
        SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _showScheduledRemindersDialog(context),
          child: Text("See Current Reminders"),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _showScheduleNotificationDialog(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              title: Text(
                "Schedule Daily Reminder",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Notification Title",
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                    ),
                  ),
                  TextField(
                    controller: bodyController,
                    decoration: InputDecoration(
                      labelText: "Notification Body",
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Text("Pick Time"),
                  ),
                  if (selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Selected time: ${selectedTime!.format(context)}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();

                    if (selectedTime == null || title.isEmpty || body.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill in all fields and pick a time')),
                      );
                      return;
                    }

                    // Schedule notification
                    await _notificationService.scheduleNotification(
                      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                      title: title,
                      body: body,
                      hour: selectedTime!.hour,
                      minute: selectedTime!.minute,
                    );

                    // Save to local list
                    setState(() {
                      _scheduledNotifications.add(model.Notification(
                        title: title,
                        body: body,
                        hour: selectedTime!.hour,
                        minute: selectedTime!.minute,
                      ));
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notification Scheduled')),
                    );
                  },
                  child: Text("Submit", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScheduledRemindersDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              title: Text(
                "Current Reminders",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _scheduledNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = _scheduledNotifications[index];
                    final time = TimeOfDay(hour: notif.hour, minute: notif.minute).format(context);
                    return ListTile(
                      title: Text(
                        notif.title,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      subtitle: Text(
                        "${notif.body}\nTime: $time",
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try {
                            await model.NotificationsAccessor.deleteNotification(notif);
                            setState(() {
                              _scheduledNotifications.removeAt(index);
                            });
                          } catch (e) {
                            log('Error deleting notification: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete notification')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); 
                  },
                  child: Text(
                    "Close",
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}*/
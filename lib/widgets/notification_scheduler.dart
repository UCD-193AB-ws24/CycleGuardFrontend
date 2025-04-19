import 'dart:developer';
import 'package:cycle_guard_app/pages/local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_guard_app/data/notifications_accessor.dart' as model;
import 'package:flutter/material.dart';

class NotificationScheduler extends StatefulWidget {
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

}
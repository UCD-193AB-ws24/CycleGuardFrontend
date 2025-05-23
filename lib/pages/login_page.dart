import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:cycle_guard_app/pages/create_account.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:cycle_guard_app/data/notifications_accessor.dart'
    as app_notifications;
import 'package:cycle_guard_app/pages/local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:fluttertoast/fluttertoast.dart';

/*
Username: javagod123
Password: c++sucks
*/

class LoginPage extends StatefulWidget {
  @override
  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<LoginPage> {
  final poppinsStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void _tryLogin() async {
    final username = usernameController.text;
    final password = passwordController.text;

    Fluttertoast.showToast(
        msg: "Logging in...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0);

    CreateAccountStatus loginStatus = await AuthUtil.login(username, password);
    final loginSuccess = loginStatus == CreateAccountStatus.success;
    print(loginSuccess ? "Login success!" : "Login failed!");

    if (loginSuccess) {
      Fluttertoast.cancel();
      final appState = Provider.of<MyAppState>(context, listen: false);
      await appState.loadUserSettings();
      await appState.fetchOwnedThemes();
      await appState.loadUserProfile();

      try {
        final notificationList =
            await app_notifications.NotificationsAccessor.getNotifications();
        final notifications = notificationList.notifications;
        final LocalNotificationService _notificationService =
            LocalNotificationService();

        int scheduledCount = 0;

        for (final notification in notifications) {
          // Assuming your notification object has a 'type' field or similar
          // to determine if it's daily, weekly, or one-time
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
                matchDateTimeComponents: DateTimeComponents.time,
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
                year: 2025, // should store on the backend in the future
                month: notification.month,
                day: notification.dayOfWeek,
              );
              break;
          }

          scheduledCount++;
        }

        print(
            "[Login] Scheduled $scheduledCount notifications of different types.");
      } catch (e) {
        print("[Login] Failed to schedule notifications: $e");
      }

      /*for (final notification in notifications) {
          await _notificationService.scheduleNotification(
            id: notification.hour * 60 + notification.minute,
            title: notification.title,
            body: notification.body,
            hour: notification.hour,
            minute: notification.minute,
          );
        }

        print("[Login] Scheduled ${notifications.length} notifications.");
      } catch (e) {
        print("[Login] Failed to schedule notifications: $e");
      }*/

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyHomePage()));
    } else {
      Fluttertoast.cancel();
      Fluttertoast.showToast(
          msg: "Incorrect username or password",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  void _createAccount() {
    print("Creating account...");
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => CreateAccountPage()));
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget usernameTextField() => TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'username',
          labelText: 'username',
          prefixIcon: Icon(Icons.account_circle),
          border: OutlineInputBorder(),
        ),
        controller: usernameController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
      );

  bool isVisible = true;
  Widget passwordTextField() => TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: 'password',
          //errorText: 'Incorrect Password',
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon:
                isVisible ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
            onPressed: () => setState(() => isVisible = !isVisible),
          ),
        ),
        controller: passwordController,
        textInputAction: TextInputAction.done,
        obscureText: isVisible,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAECCF), 
      appBar: AppBar(
        title:
            Text('Login', style: GoogleFonts.poppins(textStyle: poppinsStyle)),
        backgroundColor: Color(0xFFFAECCF),
      ),
      body: Center(
          child: ListView(
        padding: EdgeInsets.all(32),
        children: [
          usernameTextField(),
          const SizedBox(height: 24),
          passwordTextField(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // foregroundColor: Colors.purple,
              elevation: 5,
            ),
            onPressed: _tryLogin,
            child: Text("Log in"),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _createAccount,
            child: const Text(
              'Create account',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF555555),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      )),
    );
  }
}

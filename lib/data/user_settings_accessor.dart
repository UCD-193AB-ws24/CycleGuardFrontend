import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';

class UserSettingsAccessor {
  UserSettingsAccessor._();

  static Future<UserSettings> getUserSettings() async {
    final response = await RequestsUtil.getWithToken("/user/getSettings");

    if (response.statusCode == 200) {
      return UserSettings.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user stats');
    }
  }

  static Future<void> updateUserSettings(UserSettings settings) async {
    final body = settings.toJson();
    final response = await RequestsUtil.postWithToken("/user/updateSettings", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to add ride');
    }
  }
}

class UserSettings {
  final bool darkModeEnabled;
  final String currentTheme;

  const UserSettings({
    required this.darkModeEnabled,
    required this.currentTheme,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "darkModeEnabled": bool darkModeEnabled,
      "currentTheme": String currentTheme,

      } => UserSettings(
          darkModeEnabled: darkModeEnabled,
          currentTheme: currentTheme,
      ),
      _ => throw const FormatException("failed to load UserSettings"),
    };
  }

  Map<String, dynamic> toJson() => {
    'darkModeEnabled': darkModeEnabled,
    'currentTheme': currentTheme
  };

  @override
  String toString() {
    return 'UserSettings{darkModeEnabled: $darkModeEnabled, currentTheme: $currentTheme}';
  }
}
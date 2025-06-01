import 'package:cycle_guard_app/data/user_stats_accessor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/settings_page.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';

import '../Mock/Mock_UserStatsProvider.dart';

void main() {
  group('SettingsPage Tests', () {
    late MyAppState mockAppState;
    late UserStatsProvider mockUserStatsProvider;

    setUp(() {
      mockAppState = MyAppState();
      mockUserStatsProvider = MockUserStatsProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MyAppState>.value(value: mockAppState),
          ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
        ],
        child: MaterialApp(
          home: SettingsPage(),
        ),
      );
    }

    testWidgets('renders SettingsPage correctly', (WidgetTester tester) async {
      await mockUserStatsProvider.fetchUserStats();
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select Theme Color:'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Restart Tutorial'), findsOneWidget);
      expect(find.text('Reset Default Settings'), findsOneWidget);
      expect(find.text('App Contributors'), findsOneWidget);
    });

    testWidgets('updates theme color on selection', (WidgetTester tester) async {
      await mockUserStatsProvider.fetchUserStats();
      await tester.pumpWidget(createTestWidget());

      final dropdownFinder = find.byType(DropdownButton<Color>);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      final dropdownItemFinder = find.text(mockAppState.availableThemes.keys.first).last;
      await tester.tap(dropdownItemFinder);
      await tester.pumpAndSettle();

      expect(mockAppState.selectedColor, mockAppState.availableThemes.values.first);
    });

    testWidgets('toggles dark mode', (WidgetTester tester) async {
      await mockUserStatsProvider.fetchUserStats();
      await tester.pumpWidget(createTestWidget());

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(mockAppState.isDarkMode, true);
    });

    testWidgets('resets default settings', (WidgetTester tester) async {
      await mockUserStatsProvider.fetchUserStats();
      await tester.pumpWidget(createTestWidget());

      final resetButtonFinder = find.text('Reset Default Settings');
      expect(resetButtonFinder, findsOneWidget);

      await tester.tap(resetButtonFinder);
      await tester.pumpAndSettle();

      expect(mockAppState.selectedColor, Colors.orange);
      expect(mockAppState.isDarkMode, false);
    });

    testWidgets('shows contributors dialog', (WidgetTester tester) async {
      await mockUserStatsProvider.fetchUserStats();
      await tester.pumpWidget(createTestWidget());

      final contributorsButtonFinder = find.text('App Contributors');
      expect(contributorsButtonFinder, findsOneWidget);

      await tester.tap(contributorsButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Contributors'), findsOneWidget);
      expect(find.text('Developers'), findsOneWidget);
    });
  });
}
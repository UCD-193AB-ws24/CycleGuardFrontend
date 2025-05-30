import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../Mock/Mock_UserStatsProvider.dart';

void main() {
  group('HomePage Tests', () {
    testWidgets('Navigation bar displays correct items', (WidgetTester tester) async {
      final mockUserStatsProvider = MockUserStatsProvider();

      // 👇 This is the part you forgot
      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsProvider>.value(
          value: mockUserStatsProvider,
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Let widgets build fully

      // 🧪 Test for expected icons
      expect(find.byIcon(Icons.pedal_bike), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      expect(tester.takeException(), isNull); // Check for build errors
    });
  });
}

import 'package:cycle_guard_app/auth/dim_util.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cycle_guard_app/pages/start_page.dart';

void main() {
  group('StartPage Widget Tests', () {
    testWidgets('renders StartPage correctly', (WidgetTester tester) async {
      final mockPageController = PageController();
      await tester.pumpWidget(MaterialApp(home: StartPage(mockPageController)));

      // Act
      final startPageFinder = find.byType(StartPage);

      // Assert
      expect(startPageFinder, findsOneWidget);
    });

    testWidgets('contains expected UI elements', (WidgetTester tester) async {
      final mockPageController = PageController();
      await tester.pumpWidget(MaterialApp(home: StartPage(mockPageController)));

      // Act

      final buttonFinder = find.byType(ElevatedButton); // Replace with actual button type
      expect(buttonFinder, findsWidgets);

    });

    testWidgets('displays logo on StartPage', (WidgetTester tester) async {
      final mockPageController = PageController();
      await tester.pumpWidget(MaterialApp(home: StartPage(mockPageController)));

      // Act
      final logoFinder = find.byWidgetPredicate(
            (widget) => widget is SvgPicture && widget.toString().contains('assets/cg_type_logo.svg'),
      );
      expect(logoFinder, findsOneWidget);

      // Assert
      expect(logoFinder, findsOneWidget);
    });

    // Add more tests as needed
  });
}
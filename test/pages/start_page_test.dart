import 'package:cycle_guard_app/auth/dim_util.dart';
import 'package:cycle_guard_app/pages/login_page.dart';
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

    testWidgets('button triggers page navigation', (WidgetTester tester) async {
      final mockPageController = PageController();
      await tester.pumpWidget(MaterialApp(home: StartPage(mockPageController)));

      // Act
      final buttonFinder = find.byType(ElevatedButton);
      await tester.drag(buttonFinder, const Offset(300.0, 0.0)); // Swipe right
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull); // Ensure no exceptions occurred


    });

    testWidgets('background color is correct', (WidgetTester tester) async {
      final mockPageController = PageController();
      await tester.pumpWidget(MaterialApp(home: StartPage(mockPageController)));

      // Act
      final scaffoldFinder = find.byType(Scaffold);

      // Assert
      final scaffoldWidget = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffoldWidget.backgroundColor, const Color(0xFFFAECCF));
    });

    testWidgets('renders all SVG assets', (WidgetTester tester) async {
      final mockPageController = PageController();
      await tester.pumpWidget(MaterialApp(home: StartPage(mockPageController)));

      // Act
      final logomarkFinder = find.byWidgetPredicate(
            (widget) => widget is SvgPicture && widget.toString().contains('assets/cg_logomark.svg'),
      );
      final typeLogoFinder = find.byWidgetPredicate(
            (widget) => widget is SvgPicture && widget.toString().contains('assets/cg_type_logo.svg'),
      );
      final ctaFinder = find.byWidgetPredicate(
            (widget) => widget is SvgPicture && widget.toString().contains('assets/cg_cta.svg'),
      );

      // Assert
      expect(logomarkFinder, findsOneWidget);
      expect(typeLogoFinder, findsOneWidget);
      expect(ctaFinder, findsOneWidget);
    });

    // Add more tests as needed
  });
}
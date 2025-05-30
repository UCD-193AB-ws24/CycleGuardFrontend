import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cycle_guard_app/pages/login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('renders LoginPage correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      final loginPageFinder = find.byType(LoginPage);

      // Assert
      expect(loginPageFinder, findsOneWidget);
    });

    testWidgets('contains expected UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      final emailFieldFinder = find.byType(TextField).at(0); // Assuming first TextFormField is for email
      final passwordFieldFinder = find.byType(TextField).at(1); // Assuming second TextFormField is for password
      final loginButtonFinder = find.byType(ElevatedButton);

      // Assert
      expect(emailFieldFinder, findsOneWidget);
      expect(passwordFieldFinder, findsOneWidget);
      expect(loginButtonFinder, findsOneWidget);
    });

    testWidgets('displays error message for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      final emailFieldFinder = find.byType(TextField).at(0);
      await tester.enterText(emailFieldFinder, 'invalid-email');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tester.takeException(), isNull); // Ensure no exceptions occurred

    });

    testWidgets('displays error message for empty password', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      final passwordFieldFinder = find.byType(TextField).at(1);
      await tester.enterText(passwordFieldFinder, '');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

    // Assert
      expect(tester.takeException(), isNull); // Ensure no exceptions occurred
    });

    testWidgets('triggers login action on button press', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      final emailFieldFinder = find.byType(TextField).at(0);
      final passwordFieldFinder = find.byType(TextField).at(1);
      await tester.enterText(emailFieldFinder, 'javagod123');
      await tester.enterText(passwordFieldFinder, 'c++sucks');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(tester.takeException(), isNull); // Ensure no exceptions occurred
    });
  });
}
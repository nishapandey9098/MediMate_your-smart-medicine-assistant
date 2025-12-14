// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medimate/main.dart';

void main() {
  testWidgets('MediMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MediMateApp(),
      ),
    );

    // Wait for async operations to complete
    await tester.pumpAndSettle();

    // Verify that we're on the login screen initially
    expect(find.text('Welcome to MediMate'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediMateApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify login screen elements
    expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);
    expect(find.text('Your Medicine Companion'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password fields
  });
}
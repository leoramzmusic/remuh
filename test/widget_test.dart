import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:remuh/main.dart';

void main() {
  testWidgets('REMUH app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RemuhApp()));

    // Verify that the app bar title is present
    expect(find.text('REMUH'), findsWidgets);

    // Verify that the library screen is loaded by checking for the shuffle icon in the header
    expect(find.byIcon(Icons.shuffle), findsWidgets);
  });
}

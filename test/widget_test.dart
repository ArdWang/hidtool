import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hidtool/main.dart';

void main() {
  testWidgets('renders HID device manager shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('HID Device Manager'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}

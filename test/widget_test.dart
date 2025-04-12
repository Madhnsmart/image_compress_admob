
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_compressor_admob/main.dart';

void main() {
  testWidgets('HomeScreen loads and has compression toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Image Compressor'), findsOneWidget);
    expect(find.byKey(const Key('compressionToggle')), findsOneWidget);
  });

  testWidgets('Theme change dialog opens and can select option', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Theme'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Theme'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);
  });
}

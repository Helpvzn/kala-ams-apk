import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kala_ams/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KalaAmsApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

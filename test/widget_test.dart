import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sohoj_scan/features/result/result_screen.dart';
import 'package:sohoj_scan/theme/sohoj_theme.dart';

void main() {
  testWidgets('result screen shows the number and the copy button', (tester) async {
    // Design is for a phone screen (see design/screens.html, 360x760dp); the
    // default test surface is wider and much shorter, which overflows it.
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: buildSohojTheme(SohojThemeMode.dark),
      home: const ResultScreen(number: '01712345678'),
    ));
    await tester.pump();
    expect(find.text('017'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('5678'), findsOneWidget);
    expect(find.text('কপি করুন'), findsOneWidget);
  });
}

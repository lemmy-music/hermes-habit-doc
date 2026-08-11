import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/providers/theme_provider.dart';

/// Regression test for the time-format toggle bug:
///
/// The 24h/12h setting must be controlled exclusively by TimeFormatPref
/// (via MediaQuery.alwaysUse24HourFormat), independent of the app locale.
/// Previously the picker inherited the German (`de`) Material localizations,
/// whose raw time format is always 24h (`HH_colon_mm`) — so selecting 12h
/// had no effect while the date format (and thus the app locale) was German.
Widget _app(Locale locale, bool use24Hour) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('de'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 14, minute: 30),
                builder: ThemeProvider.timePickerBuilder(use24Hour),
              );
            },
            child: const Text('Pick time'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('12h mode works even with German (de) app locale',
      (tester) async {
    await tester.pumpWidget(_app(const Locale('de'), false));
    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();

    // A 12-hour dial shows the AM/PM day-period selector.
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
  });

  testWidgets('24h mode hides AM/PM with German (de) app locale',
      (tester) async {
    await tester.pumpWidget(_app(const Locale('de'), true));
    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();

    // A 24-hour dial has no day-period selector.
    expect(find.text('AM'), findsNothing);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('12h mode works with English (en) app locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), false));
    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();

    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
  });

  testWidgets('24h mode hides AM/PM with English (en) app locale',
      (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), true));
    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();

    expect(find.text('AM'), findsNothing);
    expect(find.text('PM'), findsNothing);
  });
}

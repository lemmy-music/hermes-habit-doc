import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('German locale date picker works when localizations are wired',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
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
                  await showDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 8, 11),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                },
                child: const Text('Pick date'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick date'));
    await tester.pumpAndSettle();

    // Date picker dialog must be visible (not just the blurred barrier).
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}

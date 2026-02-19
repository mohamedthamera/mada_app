import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:mada_mobile/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding shows continue button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
        ],
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('متابعة'), findsOneWidget);
  });
}


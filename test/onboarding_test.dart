import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suhbah/data/today_provider.dart';
import 'package:suhbah/features/onboarding/location_form.dart';
import 'package:suhbah/features/onboarding/onboarding_flow.dart';
import 'package:suhbah/core/member_colors.dart';
import 'package:suhbah/features/onboarding/widgets.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 340, child: child))));

void main() {
  testWidgets('seats wait, then fill when the partner joins', (t) async {
    await t.pumpWidget(_host(const Seats(myName: 'Ornob', myColor: Color(0xFF0B7D5E))));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    await t.pumpWidget(_host(const Seats(myName: 'Ornob', myColor: Color(0xFF0B7D5E), partner: ('Khadija', Color(0xFFC7224F)))));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('K'), findsOneWidget);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('flip code shows every letter and fits', (t) async {
    await t.pumpWidget(_host(const FlipCode(code: 'TMBH5M')));
    await t.pumpAndSettle();
    for (final c in 'TMBH5M'.split('').toSet()) {
      expect(find.text(c), findsWidgets);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('sun path and arch progress render without errors', (t) async {
    final d = DateTime(2026, 11, 16);
    await t.pumpWidget(_host(Column(children: [
      const StepDots(step: 2, steps: 4),
      SunPath(now: d.add(const Duration(hours: 15)), times: [for (final h in [5, 12, 15, 17, 19]) d.add(Duration(hours: h))]),
    ])));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  test('every palette color has an onboarding note', () {
    for (final m in memberColors) {
      expect(m.note, isNotEmpty, reason: m.name);
    }
  });

  testWidgets('name, color and location steps all lay out on a small phone', (t) async {
    t.view.physicalSize = const Size(360, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [authUserProvider.overrideWith((ref) => Stream.value(null))],
      child: const MaterialApp(home: OnboardingFlow()),
    ));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Ornob');
    await t.pumpAndSettle();
    expect(find.text('Assalamu alaikum, Ornob!'), findsOneWidget);
    await t.tap(find.text("That's me"));
    await t.pumpAndSettle();
    expect(find.text('Emerald it is'), findsOneWidget);
    await t.ensureVisible(find.text('Lapis'));
    await t.pumpAndSettle();
    await t.tap(find.text('Lapis'));
    await t.pumpAndSettle();
    expect(find.text('The blue of Samarkand domes'), findsOneWidget);
    await t.tap(find.text('Lapis it is'));
    await t.pumpAndSettle();
    expect(find.text('Where do you pray?'), findsOneWidget);
    expect(find.byType(LocationForm), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

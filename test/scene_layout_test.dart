import 'package:depth_flow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cardTitles = ['This week', 'Design review', 'Reading list', 'Quick capture'];

Rect _cardRect(WidgetTester tester, String title) {
  final card = find.ancestor(
    of: find.text(title),
    matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_LayerCard'),
  );
  expect(card, findsOneWidget);
  return tester.getRect(card);
}

void main() {
  for (final size in const [Size(1280, 800), Size(390, 844)]) {
    testWidgets('cards size to their content and do not cover each other at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DepthFlowApp());
      await tester.pumpAndSettle();

      final rects = {for (final t in _cardTitles) t: _cardRect(tester, t)};
      for (final entry in rects.entries) {
        expect(entry.value.height, lessThan(120), reason: '${entry.key} card should hug its content');
      }
      for (var i = 0; i < _cardTitles.length; i++) {
        for (var j = i + 1; j < _cardTitles.length; j++) {
          final a = rects[_cardTitles[i]]!, b = rects[_cardTitles[j]]!;
          expect(a.overlaps(b), isFalse, reason: '${_cardTitles[i]} and ${_cardTitles[j]} overlap');
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app_for_model/screens/auth_screen.dart';
import 'package:mobile_app_for_model/screens/prediction_home_page.dart';
import 'package:mobile_app_for_model/theme/app_theme.dart';

/// Renders each screen at common phone sizes and fails on any layout
/// overflow, which is the main risk when restyling.
void main() {
  Future<void> renderAt(
    WidgetTester tester,
    Widget screen,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: screen),
    );
    await tester.pumpAndSettle();
  }

  const sizes = <String, Size>{
    'small phone': Size(360, 640),
    'large phone': Size(430, 932),
  };

  sizes.forEach((name, size) {
    testWidgets('PredictionHomePage renders on $name', (tester) async {
      await renderAt(tester, const PredictionHomePage(), size);
      expect(tester.takeException(), isNull);

      // Walk all three tabs.
      for (final label in ['History', 'Tips']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label tab on $name');
      }
    });

    testWidgets('LoginScreen renders on $name', (tester) async {
      await renderAt(tester, const LoginScreen(), size);
      expect(tester.takeException(), isNull);
    });
  });
}

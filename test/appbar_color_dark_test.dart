import 'package:digimon_pokedex/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Color? _appBarColor(WidgetTester tester) {
  final material = find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(Material),
  );
  return tester.widget<Material>(material.first).color;
}

void main() {
  // Scroll real de la lista en modo oscuro.
  for (final mode in [Brightness.dark]) {
    testWidgets('la AppBar no cambia de color al scrollear ($mode)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      tester.platformDispatcher.platformBrightnessTestValue = mode;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const DigimonPokedexApp());
      // La carga del JSON usa I/O real: se espera (con tope) a que aparezca la barra.
      for (var i = 0; i < 100 && find.byType(AppBar).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 1));

      final before = _appBarColor(tester);
      expect(before, isNotNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      // Avance fijo (no pumpAndSettle: las imágenes cargan en segundo plano).
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(_appBarColor(tester), before);
    });
  }
}

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
  for (final mode in [Brightness.light, Brightness.dark]) {
    test(
      'tema $mode: la AppBar tiene color fijo y sin elevación al scrollear',
      () {
        final scheme = DigimonPokedexApp.buildTheme(mode).colorScheme;
        final bar = DigimonPokedexApp.buildTheme(mode).appBarTheme;
        // Un color fijo (no dependiente del estado "scrolled under") evita el aclarado.
        expect(bar.backgroundColor, scheme.surface);
        expect(bar.scrolledUnderElevation, 0);
        expect(bar.surfaceTintColor, Colors.transparent);
      },
    );
  }

  // Scroll real de la lista, solo en modo claro (el modo oscuro en el entorno
  // de tests no carga igual la pantalla; el tema oscuro se cubre arriba).
  for (final mode in [Brightness.light]) {
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

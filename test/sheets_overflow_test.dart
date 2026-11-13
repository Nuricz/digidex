import 'package:digimon_pokedex/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(
    720,
    1000,
  ); // 360x500 lógicos: pantalla baja
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  // Desmontar la app al terminar: sin esto el siguiente test del archivo no carga.
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(const DigimonPokedexApp());
  for (var i = 0; i < 100 && find.byType(AppBar).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets(
    'hoja de ordenar: sin overflow en pantalla baja y se puede desplazar',
    (tester) async {
      await _boot(tester);
      await tester.tap(find.byTooltip('Ordenar'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: 'overflow al abrir');
      expect(find.text('Dato aparte (no es un stat)'), findsOneWidget);

      // Hasta abajo: el botón Restablecer tiene que poder alcanzarse.
      await tester.scrollUntilVisible(
        find.text('Restablecer'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Restablecer'), findsOneWidget);
    },
  );
}

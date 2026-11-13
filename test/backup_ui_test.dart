import 'package:digimon_pokedex/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
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
  testWidgets('menú: importar un texto inválido muestra el error y no cierra', (
    tester,
  ) async {
    await _boot(tester);
    await tester.tap(find.byTooltip('Más opciones'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('Importar favoritos y registrados'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.enterText(find.byType(TextField).last, 'hola');
    await tester.tap(find.text('Importar').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('El texto no es un respaldo válido.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

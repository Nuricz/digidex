import 'package:digimon_pokedex/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('menú: exportar muestra el respaldo con los conteos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['agumon'],
      'registered': ['agumon', 'kuramon'],
    });
    // El portapapeles no existe en el entorno de tests: se simula (guarda lo copiado).
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
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

    await tester.tap(find.byTooltip('Más opciones'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('Exportar favoritos y registrados'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.textContaining('1 favoritos y 2 registrados'), findsOneWidget);
    expect(find.textContaining('"app":"digidex"'), findsOneWidget);
    expect(copied, contains('"favorites":["agumon"]'));
    expect(copied, contains('"registered":["agumon","kuramon"]'));
    expect(tester.takeException(), isNull);
  });
}

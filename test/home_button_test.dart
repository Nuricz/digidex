import 'package:digimon_pokedex/main.dart';
import 'package:digimon_pokedex/screens/digimon_detail_screen.dart';
import 'package:digimon_pokedex/screens/digimon_list_screen.dart';
import 'package:digimon_pokedex/widgets/digimon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('el botón Inicio descarta todas las fichas apiladas', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DigimonPokedexApp());
    // La carga del JSON usa I/O real: se deja correr fuera del reloj falso.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(DigimonListScreen), findsOneWidget);

    // Primera ficha (Kuramon).
    await tester.tap(find.byType(DigimonCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(DigimonDetailScreen), findsOneWidget);

    // Apilar otra ficha entrando por una evolución.
    final detail = tester.widget<DigimonDetailScreen>(
      find.byType(DigimonDetailScreen),
    );
    final evoName = detail.digimon.evolvesTo.first.name;
    final evo = find.descendant(
      of: find.byType(DigimonDetailScreen),
      matching: find.text(evoName),
    );
    await tester.scrollUntilVisible(
      evo,
      300,
      // El scroll vertical de la ficha (no el de la lista que queda debajo).
      scrollable: find
          .descendant(
            of: find.byType(DigimonDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // scrollUntilVisible alcanza con que exista; ensureVisible lo trae a pantalla.
    await tester.ensureVisible(evo);
    await tester.pumpAndSettle();
    await tester.tap(evo);
    await tester.pumpAndSettle();
    expect(
      find.byType(DigimonDetailScreen, skipOffstage: false),
      findsNWidgets(2),
    );

    // Inicio: vuelve a la lista y no queda nada apilado.
    await tester.tap(find.byTooltip('Inicio'));
    await tester.pumpAndSettle();
    expect(find.byType(DigimonDetailScreen, skipOffstage: false), findsNothing);
    expect(find.byType(DigimonListScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(DigimonListScreen))).canPop(),
      isFalse,
    );
  });
}

import 'dart:io';

import 'package:digimon_pokedex/data/repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = DigimonRepository.fromJsonString(
    File('assets/data/digimon.json').readAsStringSync(),
  );

  test('carga los 341 Digimon con 6 stats y sin dex repetidos', () {
    expect(repo.digimon.length, 341);
    expect(repo.digimon.map((d) => d.dex).toSet().length, 341);
    expect(
      repo.digimon.every((d) => d.stats.values.every((s) => s.lv99 != null)),
      isTrue,
    );
  });

  test('Agumon y Agumon (Blk) son distintos y evolucionan distinto', () {
    final a = repo.byName('Agumon')!, b = repo.byName('Agumon (Blk)')!;
    expect(a.slug == b.slug, isFalse);
    expect(a.evolvesTo.map((e) => e.name), contains('Greymon'));
    expect(b.evolvesTo.map((e) => e.name), contains('Greymon (Blue)'));
  });

  test('toda evolución referencia un Digimon existente', () {
    for (final d in repo.digimon) {
      for (final e in [...d.evolvesFrom, ...d.evolvesTo]) {
        expect(
          repo.byName(e.name),
          isNotNull,
          reason: '${d.name} -> ${e.name}',
        );
      }
    }
  });

  test(
    'índice de movimientos: Desolation Claw lo aprende Cyberdramon en Nv 1',
    () {
      final m = repo.moves.firstWhere((m) => m.name == 'Desolation Claw');
      final l = m.learners.firstWhere((l) => l.digimon.name == 'Cyberdramon');
      expect(l.level, 1);
    },
  );

  test('todos tienen descripción y habilidad traducidas', () {
    for (final d in repo.digimon) {
      expect(d.descriptionEs, isNotEmpty, reason: d.name);
      expect(d.supportSkillEffectEs, isNotEmpty, reason: d.name);
    }
  });

  test('imágenes: 341 con artwork y todas existen en disco', () {
    final con = repo.digimon.where((d) => d.image != null).toList();
    expect(con.length, 341);
    for (final d in con) {
      expect(File(d.image!).existsSync(), isTrue, reason: d.name);
    }
  });

  test(
    'anterior/siguiente siguen el orden del dex y cortan en los extremos',
    () {
      final first = repo.digimon.first, last = repo.digimon.last;
      expect(repo.previousOf(first), isNull);
      expect(repo.nextOf(last), isNull);
      final a = repo.byName('Agumon')!;
      expect(repo.nextOf(a)!.dex, a.dex + 1);
      expect(repo.previousOf(repo.nextOf(a)!)!.slug, a.slug);
    },
  );

  test('los 492 movimientos tienen efecto traducido', () {
    expect(repo.moves.length, 492);
    for (final m in repo.moves) {
      expect(repo.moveEffect(m.name), isNotEmpty, reason: m.name);
    }
    expect(repo.moveEffect('Desolation Claw'), contains('Ataque físico'));
  });

  test('hay datos suficientes para ordenar por cada stat en cada nivel', () {
    for (final k in ['hp', 'sp', 'atk', 'def', 'int', 'spd']) {
      for (final lv in [1, 50, 99]) {
        expect(
          repo.digimon.every((d) => d.stats[k]!.atLevel(lv) != null),
          isTrue,
          reason: '$k Lv$lv',
        );
      }
    }
  });

  test('hay Digimon marcados CS y solo-HM', () {
    expect(repo.digimon.where((d) => d.inCyberSleuth).length, 244);
  });
}

import 'dart:io';

import 'package:digimon_pokedex/data/repository.dart';
import 'package:digimon_pokedex/data/sorting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = DigimonRepository.fromJsonString(
    File('assets/data/digimon.json').readAsStringSync(),
  );

  List<int?> values(SortKey k, bool desc, [int lv = 99]) => sortDigimon(
    repo.digimon,
    key: k,
    desc: desc,
    level: lv,
  ).map((d) => sortValue(d, k, lv)).toList();

  test('ABI y stats son criterios distintos', () {
    expect(SortKey.abi.isStat, isFalse);
    expect(SortKey.abi.isNumeric, isTrue);
    expect(SortKey.atk.isStat, isTrue);
    expect(SortKey.dex.isNumeric, isFalse);
  });

  test('ABI requerido: de mayor a menor, y sin dato al final', () {
    final v = values(SortKey.abi, true);
    final firstNull = v.indexOf(null);
    expect(firstNull, greaterThan(0), reason: 'hay Digimon sin ABI requerido');
    expect(v.sublist(firstNull).every((x) => x == null), isTrue);
    final nums = v.sublist(0, firstNull).cast<int>();
    for (var i = 1; i < nums.length; i++) {
      expect(nums[i - 1] >= nums[i], isTrue);
    }
  });

  test('ABI de menor a mayor: los sin dato siguen al final', () {
    final v = values(SortKey.abi, false);
    final firstNull = v.indexOf(null);
    expect(v.sublist(firstNull).every((x) => x == null), isTrue);
    final nums = v.sublist(0, firstNull).cast<int>();
    for (var i = 1; i < nums.length; i++) {
      expect(nums[i - 1] <= nums[i], isTrue);
    }
  });

  test('cada stat ordena bien en ambas direcciones y niveles', () {
    for (final k in [
      SortKey.hp,
      SortKey.sp,
      SortKey.atk,
      SortKey.def,
      SortKey.int,
      SortKey.spd,
    ]) {
      for (final lv in [1, 50, 99]) {
        final d = values(k, true, lv).cast<int>();
        final a = values(k, false, lv).cast<int>();
        for (var i = 1; i < d.length; i++) {
          expect(d[i - 1] >= d[i], isTrue, reason: '${k.name} Lv$lv desc');
          expect(a[i - 1] <= a[i], isTrue, reason: '${k.name} Lv$lv asc');
        }
      }
    }
  });

  test('el orden no modifica la lista original', () {
    final before = repo.digimon.map((d) => d.dex).toList();
    sortDigimon(repo.digimon, key: SortKey.atk, desc: true, level: 99);
    expect(repo.digimon.map((d) => d.dex).toList(), before);
  });
}

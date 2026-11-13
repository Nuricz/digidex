import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class DigimonRepository {
  final List<Digimon> digimon;
  final List<MoveEntry> moves;
  final Map<String, Digimon> _byName;
  final Map<String, MoveInfo> _moveInfo;

  DigimonRepository._(this.digimon, this.moves, this._byName, this._moveInfo);

  static Future<DigimonRepository> load() async {
    final raw = await rootBundle.loadString('assets/data/digimon.json');
    return DigimonRepository.fromJsonString(raw);
  }

  factory DigimonRepository.fromJsonString(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final list = [
      for (final j in root['digimon'] as List)
        Digimon.fromJson(j as Map<String, dynamic>),
    ]..sort((a, b) => a.dex.compareTo(b.dex));

    final byName = {for (final d in list) d.name: d};

    // Índice de movimientos: nombre -> quién lo aprende y en qué nivel.
    final acc = <String, List<Learner>>{};
    final meta = <String, Move>{};
    for (final d in list) {
      for (final m in d.moves) {
        meta.putIfAbsent(m.name, () => m);
        acc.putIfAbsent(m.name, () => []).add(Learner(d, m.level, m.learnType));
      }
    }
    final moves = [
      for (final e in acc.entries)
        MoveEntry(
          e.key,
          meta[e.key]!.attribute,
          meta[e.key]!.category,
          meta[e.key]!.spCost,
          meta[e.key]!.power,
          e.value..sort((a, b) {
            final c = (a.level ?? 999).compareTo(b.level ?? 999);
            return c != 0 ? c : a.digimon.dex.compareTo(b.digimon.dex);
          }),
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final info = {
      for (final e
          in (root['moveInfo'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: MoveInfo(
          (e.value as Map<String, dynamic>)['description'] as String?,
          (e.value as Map<String, dynamic>)['descriptionEs'] as String?,
        ),
    };

    return DigimonRepository._(list, moves, byName, info);
  }

  /// Vecinos en el orden del dex (null en los extremos).
  Digimon? previousOf(Digimon d) {
    final i = digimon.indexWhere((x) => x.slug == d.slug);
    return i > 0 ? digimon[i - 1] : null;
  }

  Digimon? nextOf(Digimon d) {
    final i = digimon.indexWhere((x) => x.slug == d.slug);
    return i != -1 && i < digimon.length - 1 ? digimon[i + 1] : null;
  }

  /// Qué hace el movimiento (español, o inglés si faltara la traducción).
  String? moveEffect(String name) => _moveInfo[name]?.text;

  /// Las evoluciones referencian por nombre exacto de Grindosaur.
  Digimon? byName(String name) => _byName[name];

  static const stageOrder = [
    'Training 1',
    'Training 2',
    'Rookie',
    'Armor',
    'Champion',
    'Ultimate',
    'Mega',
    'Ultra',
    'Attribute',
  ];

  List<String> get stages => _sorted(digimon.map((d) => d.stage), stageOrder);
  List<String> get attributes => _sorted(digimon.map((d) => d.attribute));
  List<String> get types => _sorted(digimon.map((d) => d.type));
  List<String> get moveAttributes => _sorted(moves.map((m) => m.attribute));

  static List<String> _sorted(Iterable<String> v, [List<String>? order]) {
    final s = v.toSet().toList();
    s.sort((a, b) {
      if (order != null) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        if (ia != -1 || ib != -1) {
          return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
        }
      }
      return a.compareTo(b);
    });
    return s;
  }
}

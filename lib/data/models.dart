const statKeys = ['hp', 'sp', 'atk', 'def', 'int', 'spd'];

class StatValues {
  final int? lv1, lv50, lv99;
  const StatValues(this.lv1, this.lv50, this.lv99);

  factory StatValues.fromJson(Map<String, dynamic>? j) =>
      StatValues(j?['lv1'] as int?, j?['lv50'] as int?, j?['lv99'] as int?);

  int? atLevel(int level) => switch (level) {
    1 => lv1,
    50 => lv50,
    _ => lv99,
  };
}

class Move {
  final String name;
  final int? level;
  final String attribute;
  final String category;
  final int? spCost;
  final int? power;
  final String learnType;

  const Move({
    required this.name,
    required this.level,
    required this.attribute,
    required this.category,
    required this.spCost,
    required this.power,
    required this.learnType,
  });

  factory Move.fromJson(Map<String, dynamic> j) => Move(
    name: j['name'] as String,
    level: j['level'] as int?,
    attribute: j['attribute'] as String? ?? '',
    category: j['category'] as String? ?? '',
    spCost: j['spCost'] as int?,
    power: j['power'] as int?,
    learnType: j['learnType'] as String? ?? '',
  );
}

class EvoLink {
  final String name, stage, attribute, type;
  const EvoLink(this.name, this.stage, this.attribute, this.type);

  factory EvoLink.fromJson(Map<String, dynamic> j) => EvoLink(
    j['name'] as String,
    j['stage'] as String? ?? '',
    j['attribute'] as String? ?? '',
    j['type'] as String? ?? '',
  );
}

class DigivolveReq {
  final Map<String, int?> values; // level, atk, def, hp, int, sp, spd, abi, cam
  final String? extra;
  const DigivolveReq(this.values, this.extra);

  factory DigivolveReq.fromJson(Map<String, dynamic> j) {
    final v = <String, int?>{};
    j.forEach((k, val) {
      if (k != 'extra') v[k] = val as int?;
    });
    return DigivolveReq(v, j['extra'] as String?);
  }

  /// Solo los requisitos que existen, ej. "Nv 28 · ATK 75 · SPD 75".
  String get summary {
    const labels = {
      'level': 'Nv',
      'hp': 'HP',
      'sp': 'SP',
      'atk': 'ATK',
      'def': 'DEF',
      'int': 'INT',
      'spd': 'SPD',
      'abi': 'ABI',
      'cam': 'CAM',
    };
    final parts = <String>[
      for (final e in labels.entries)
        if (values[e.key] != null) '${e.value} ${values[e.key]}',
      ?extra,
    ];
    return parts.isEmpty ? 'Sin requisitos' : parts.join(' · ');
  }
}

class Digimon {
  final String slug, name, stage, attribute, type;
  final String? image; // artwork grande (puede faltar)
  final bool
  imageOpaque; // true: trae fondo blanco, se muestra sobre tarjeta blanca
  final int dex;
  final int? memory, equipSlots;
  final String? description, descriptionEs;
  final String? supportSkillName, supportSkillEffect, supportSkillEffectEs;
  final Map<String, StatValues> stats;
  final List<Move> moves;
  final List<EvoLink> evolvesFrom, evolvesTo;
  final DigivolveReq? digivolveReq;

  /// Estimado: cruce con Wikimon + mapeos a mano. Ver README.
  final bool inCyberSleuth;

  const Digimon({
    required this.slug,
    required this.image,
    required this.imageOpaque,
    required this.name,
    required this.stage,
    required this.attribute,
    required this.type,
    required this.dex,
    required this.memory,
    required this.equipSlots,
    required this.description,
    required this.descriptionEs,
    required this.supportSkillName,
    required this.supportSkillEffect,
    required this.supportSkillEffectEs,
    required this.stats,
    required this.moves,
    required this.evolvesFrom,
    required this.evolvesTo,
    required this.digivolveReq,
    required this.inCyberSleuth,
  });

  String get iconAsset => 'assets/icons/$slug.png';

  /// Texto en español si existe; si no, el original en inglés.
  String? get descriptionText => descriptionEs ?? description;
  String? get supportSkillEffectText =>
      supportSkillEffectEs ?? supportSkillEffect;

  /// ABI necesario para digievolucionar A este Digimon (null si no pide).
  int? get abiRequired => digivolveReq?.values['abi'];

  String get dexLabel => '#${dex.toString().padLeft(3, '0')}';

  factory Digimon.fromJson(Map<String, dynamic> j) {
    final skill = j['supportSkill'] as Map<String, dynamic>?;
    final req = j['digivolveRequirements'] as Map<String, dynamic>?;
    return Digimon(
      slug: j['slug'] as String,
      image: j['image'] as String?,
      imageOpaque: j['imageOpaque'] as bool? ?? false,
      name: j['name'] as String,
      stage: j['stage'] as String? ?? '-',
      attribute: j['attribute'] as String? ?? '-',
      type: j['type'] as String? ?? '-',
      dex: j['dex'] as int,
      memory: j['memory'] as int?,
      equipSlots: j['equipSlots'] as int?,
      description: j['description'] as String?,
      descriptionEs: j['descriptionEs'] as String?,
      supportSkillName: skill?['name'] as String?,
      supportSkillEffect: skill?['effect'] as String?,
      supportSkillEffectEs: skill?['effectEs'] as String?,
      stats: {
        for (final k in statKeys)
          k: StatValues.fromJson(
            (j['stats'] as Map<String, dynamic>?)?[k] as Map<String, dynamic>?,
          ),
      },
      moves: [
        for (final m in (j['moves'] as List? ?? const []))
          Move.fromJson(m as Map<String, dynamic>),
      ],
      evolvesFrom: [
        for (final e in (j['evolvesFrom'] as List? ?? const []))
          EvoLink.fromJson(e as Map<String, dynamic>),
      ],
      evolvesTo: [
        for (final e in (j['evolvesTo'] as List? ?? const []))
          EvoLink.fromJson(e as Map<String, dynamic>),
      ],
      digivolveReq: req == null ? null : DigivolveReq.fromJson(req),
      inCyberSleuth: j['inCyberSleuth_estimated'] as bool? ?? false,
    );
  }
}

/// Un movimiento (por nombre) y los Digimon que lo aprenden.
class MoveEntry {
  final String name;
  final String attribute, category;
  final int? spCost, power;
  final List<Learner> learners;
  const MoveEntry(
    this.name,
    this.attribute,
    this.category,
    this.spCost,
    this.power,
    this.learners,
  );
}

class Learner {
  final Digimon digimon;
  final int? level;
  final String learnType;
  const Learner(this.digimon, this.level, this.learnType);
}

/// Efecto de un movimiento (texto del juego + traducción).
class MoveInfo {
  final String? description, descriptionEs;
  const MoveInfo(this.description, this.descriptionEs);

  /// Español si existe; si no, el original en inglés.
  String? get text => descriptionEs ?? description;
}

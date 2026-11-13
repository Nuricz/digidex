import 'models.dart';

/// Criterios de orden de la lista. El ABI requerido NO es un stat: se trata
/// aparte (es el ABI que hay que tener para digievolucionar a ese Digimon).
enum SortKey {
  dex('Nº dex'),
  name('Nombre'),
  hp('HP'),
  sp('SP'),
  atk('ATK'),
  def('DEF'),
  int('INT'),
  spd('SPD'),
  abi('ABI requerido');

  final String label;
  const SortKey(this.label);

  bool get isAbi => this == SortKey.abi;
  bool get isStat => index >= SortKey.hp.index && !isAbi;

  /// Criterios numéricos (stat o ABI): se ordenan de mayor a menor / menor a mayor.
  bool get isNumeric => isStat || isAbi;

  String get statKey => this.name; // hp, sp, atk, def, int, spd
}

/// Valor numérico por el que se ordena (null si no aplica o no hay dato).
int? sortValue(Digimon d, SortKey key, int level) {
  if (key.isAbi) return d.abiRequired;
  if (key.isStat) return d.stats[key.statKey]?.atLevel(level);
  return null;
}

/// Ordena una copia. Los Digimon sin dato (p. ej. sin ABI requerido) van
/// siempre al final, sea cual sea la dirección. Empates: por número de dex.
List<Digimon> sortDigimon(
  Iterable<Digimon> items, {
  required SortKey key,
  required bool desc,
  required int level,
}) {
  final list = [...items];
  int byDex(Digimon a, Digimon b) => a.dex.compareTo(b.dex);
  list.sort((a, b) {
    int c;
    if (key.isNumeric) {
      final va = sortValue(a, key, level), vb = sortValue(b, key, level);
      if (va == null && vb == null) return byDex(a, b);
      if (va == null) return 1;
      if (vb == null) return -1;
      c = va.compareTo(vb);
    } else if (key == SortKey.name) {
      c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    } else {
      c = byDex(a, b);
    }
    if (desc) c = -c;
    return c != 0 ? c : byDex(a, b);
  });
  return list;
}

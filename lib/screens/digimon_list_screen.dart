import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/sorting.dart';
import '../state/collection_store.dart';
import '../widgets/backup_dialogs.dart';
import '../widgets/digimon_card.dart';
import '../widgets/element_icon.dart';
import 'digimon_detail_screen.dart';

enum GameFilter { all, inCs, onlyHm }

/// Filtro por check de "registrado en el juego".
enum RegFilter {
  all('Todos'),
  registered('Registrados'),
  missing('Sin registrar');

  final String label;
  const RegFilter(this.label);
}

class DigimonListScreen extends StatefulWidget {
  final DigimonRepository repo;
  const DigimonListScreen({super.key, required this.repo});

  @override
  State<DigimonListScreen> createState() => _DigimonListScreenState();
}

class _DigimonListScreenState extends State<DigimonListScreen> {
  String _query = '';
  String? _stage, _attribute, _type;
  GameFilter _game = GameFilter.all;
  bool _onlyFav = false;
  RegFilter _reg = RegFilter.all;
  SortKey _sort = SortKey.dex;
  bool _desc = false; // para stats: true = mayor -> menor
  int _sortLevel = 99;
  bool _showAbi = false; // mostrar ABI requerido en cada tarjeta
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  /// Alterna: todos -> registrados -> sin registrar -> todos.
  void _cycleReg() {
    setState(
      () => _reg = RegFilter.values[(_reg.index + 1) % RegFilter.values.length],
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Registro: ${_reg.label}'),
          duration: const Duration(milliseconds: 900),
        ),
      );
  }

  int? _valueOf(Digimon d) => sortValue(d, _sort, _sortLevel);

  List<Digimon> _sorted(List<Digimon> items) =>
      sortDigimon(items, key: _sort, desc: _desc, level: _sortLevel);

  /// Texto destacado de cada tarjeta: stat ordenado y/o ABI requerido.
  String? _badgeFor(Digimon d) {
    final parts = <String>[
      if (_sort.isStat) '${_sort.label} ${_valueOf(d) ?? '-'}',
      if (_showAbi || _sort.isAbi) 'ABI ${d.abiRequired ?? '-'}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Future<void> _openSort() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      // Desplazable: la hoja ya no entra completa en pantallas bajas.
      builder: (ctx) => SingleChildScrollView(
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            void update(VoidCallback f) {
              setState(f);
              setSheet(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordenar por',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final k in SortKey.values.where((k) => !k.isAbi))
                          ChoiceChip(
                            label: Text(k.label),
                            selected: _sort == k,
                            onSelected: (_) => update(() {
                              _sort = k;
                              // Los stats arrancan de mayor a menor; dex/nombre ascendente.
                              _desc = k.isNumeric;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dato aparte (no es un stat)',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('ABI requerido'),
                          selected: _sort.isAbi,
                          onSelected: (_) => update(() {
                            _sort = SortKey.abi;
                            _desc = true; // mayor -> menor
                          }),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostrar ABI requerido'),
                      subtitle: const Text(
                        'ABI que hay que tener para digievolucionar a cada Digimon',
                      ),
                      value: _showAbi,
                      onChanged: (v) => update(() => _showAbi = v),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: true,
                          icon: const Icon(Icons.arrow_downward),
                          label: Text(
                            _sort.isNumeric
                                ? 'Mayor → menor'
                                : 'Z → A / último',
                          ),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: const Icon(Icons.arrow_upward),
                          label: Text(
                            _sort.isNumeric
                                ? 'Menor → mayor'
                                : 'A → Z / primero',
                          ),
                        ),
                      ],
                      selected: {_desc},
                      onSelectionChanged: (s) => update(() => _desc = s.first),
                    ),
                    if (_sort.isStat) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Stat en el nivel',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 1, label: Text('Lv 1')),
                          ButtonSegment(value: 50, label: Text('Lv 50')),
                          ButtonSegment(value: 99, label: Text('Lv 99')),
                        ],
                        selected: {_sortLevel},
                        onSelectionChanged: (s) =>
                            update(() => _sortLevel = s.first),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => update(() {
                          _sort = SortKey.dex;
                          _desc = false;
                          _sortLevel = 99;
                        }),
                        child: const Text('Restablecer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int get _activeFilters =>
      [_stage, _attribute, _type].where((e) => e != null).length +
      (_game != GameFilter.all ? 1 : 0);

  List<Digimon> _filtered(CollectionStore store) {
    final q = _query.trim().toLowerCase();
    return [
      for (final d in widget.repo.digimon)
        if ((q.isEmpty ||
                d.name.toLowerCase().contains(q) ||
                d.dex.toString() == q) &&
            (_stage == null || d.stage == _stage) &&
            (_attribute == null || d.attribute == _attribute) &&
            (_type == null || d.type == _type) &&
            (!_onlyFav || store.isFavorite(d.slug)) &&
            switch (_reg) {
              RegFilter.all => true,
              RegFilter.registered => store.isRegistered(d.slug),
              RegFilter.missing => !store.isRegistered(d.slug),
            } &&
            switch (_game) {
              GameFilter.all => true,
              GameFilter.inCs => d.inCyberSleuth,
              GameFilter.onlyHm => !d.inCyberSleuth,
            })
          d,
    ];
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _FilterSheet(
        repo: widget.repo,
        stage: _stage,
        attribute: _attribute,
        type: _type,
        game: _game,
        onApply: (s, a, t, g) => setState(() {
          _stage = s;
          _attribute = a;
          _type = t;
          _game = g;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CollectionStore>();
    final items = _sorted(_filtered(store));
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digimon'),
            Text(
              '${store.registeredCount}/${widget.repo.digimon.length} registrados · ${store.favoriteCount} favoritos'
              '${_reg == RegFilter.all ? '' : ' · mostrando: ${_reg.label.toLowerCase()}'}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ordenar',
            onPressed: _openSort,
            icon: Badge(
              isLabelVisible: _sort != SortKey.dex || _desc,
              smallSize: 8,
              child: const Icon(Icons.sort),
            ),
          ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _activeFilters > 0,
              label: Text('$_activeFilters'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (v) {
              final store = context.read<CollectionStore>();
              if (v == 'export') exportCollection(context, store);
              if (v == 'import') importCollection(context, store, widget.repo);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: Text('Exportar favoritos y registrados'),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text('Importar favoritos y registrados'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              focusNode: _searchFocus,
              hintText: 'Buscar por nombre o número',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 3,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Registro: ${_reg.label} (tocá para cambiar)',
                  onPressed: _cycleReg,
                  icon: switch (_reg) {
                    RegFilter.all => const Icon(Icons.check_circle_outline),
                    RegFilter.registered => const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    RegFilter.missing => const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.orange,
                    ),
                  },
                ),
                IconButton(
                  tooltip: 'Solo favoritos',
                  isSelected: _onlyFav,
                  onPressed: () => setState(() => _onlyFav = !_onlyFav),
                  icon: const Icon(Icons.favorite_border),
                  selectedIcon: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: null,
            tooltip: 'Buscar',
            shape: const CircleBorder(),
            onPressed: () => _searchFocus.requestFocus(),
            child: const Icon(Icons.search),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                _onlyFav || _reg != RegFilter.all
                    ? 'No hay Digimon con esos filtros marcados'
                    : 'Sin resultados',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 96),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final d = items[i];
                return DigimonCard(
                  digimon: d,
                  badge: _badgeFor(d),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DigimonDetailScreen(repo: widget.repo, digimon: d),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final DigimonRepository repo;
  final String? stage, attribute, type;
  final GameFilter game;
  final void Function(String?, String?, String?, GameFilter) onApply;
  const _FilterSheet({
    required this.repo,
    required this.stage,
    required this.attribute,
    required this.type,
    required this.game,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _stage = widget.stage;
  late String? _attribute = widget.attribute;
  late String? _type = widget.type;
  late GameFilter _game = widget.game;

  Widget _chips(
    String title,
    List<String> values,
    String? selected,
    void Function(String?) onChanged, {
    bool elements = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final v in values)
              FilterChip(
                avatar: elements ? ElementIcon(v) : null,
                label: Text(v),
                selected: selected == v,
                onSelected: (on) => setState(() => onChanged(on ? v : null)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Juego', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SegmentedButton<GameFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: GameFilter.all, label: Text('Todos')),
                ButtonSegment(
                  value: GameFilter.inCs,
                  label: Text('Cyber Sleuth'),
                ),
                ButtonSegment(value: GameFilter.onlyHm, label: Text('Solo HM')),
              ],
              selected: {_game},
              onSelectionChanged: (s) => setState(() => _game = s.first),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Dato estimado: puede haber errores en algunos Digimon.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            _chips('Stage', widget.repo.stages, _stage, (v) => _stage = v),
            _chips(
              'Atributo',
              widget.repo.attributes,
              _attribute,
              (v) => _attribute = v,
              elements: true,
            ),
            _chips('Tipo', widget.repo.types, _type, (v) => _type = v),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _stage = _attribute = _type = null;
                    _game = GameFilter.all;
                  }),
                  child: const Text('Limpiar'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    widget.onApply(_stage, _attribute, _type, _game);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

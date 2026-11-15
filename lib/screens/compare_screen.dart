import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/digimon_icon.dart';
import '../widgets/digimon_picker.dart';

/// Compara los stats de dos Digimon. Sirve como pestaña y como pantalla suelta.
class CompareScreen extends StatefulWidget {
  final DigimonRepository repo;
  final Digimon? initialA;
  const CompareScreen({super.key, required this.repo, this.initialA});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  Digimon? _a, _b;
  int _level = 99;
  Digimon? _cachedFrom, _cachedTo;
  List<_Route> _cachedRoutes = const [];

  @override
  void initState() {
    super.initState();
    _a = widget.initialA;
  }

  Future<void> _pick(bool first) async {
    final d = await pickDigimon(context, widget.repo);
    if (d == null) return;
    setState(() => first ? _a = d : _b = d);
  }

  int _total(Digimon d) =>
      statKeys.fold(0, (s, k) => s + (d.stats[k]!.atLevel(_level) ?? 0));

  List<_Route> _routes(Digimon from, Digimon to) {
    if (identical(from, _cachedFrom) && identical(to, _cachedTo)) {
      return _cachedRoutes;
    }
    if (from.slug == to.slug) {
      _cachedFrom = from;
      _cachedTo = to;
      return _cachedRoutes = [
        _Route([from], []),
      ];
    }

    // evolvesTo is the canonical edge list. Walking it backwards represents
    // a de-digivolution and keeps each transition's direction explicit.
    final graph = <String, List<_Transition>>{
      for (final d in widget.repo.digimon) d.slug: <_Transition>[],
    };
    for (final d in widget.repo.digimon) {
      for (final link in d.evolvesTo) {
        final next = widget.repo.byName(link.name);
        if (next == null) continue;
        graph[d.slug]!.add(_Transition(next, true));
        graph[next.slug]!.add(_Transition(d, false));
      }
    }

    // Reject disconnected pairs before enumerating alternative routes.
    final reachable = <String>{from.slug};
    final pending = <String>[from.slug];
    for (var i = 0; i < pending.length; i++) {
      for (final edge in graph[pending[i]] ?? const <_Transition>[]) {
        if (reachable.add(edge.digimon.slug)) pending.add(edge.digimon.slug);
      }
    }
    if (!reachable.contains(to.slug)) {
      _cachedFrom = from;
      _cachedTo = to;
      return _cachedRoutes = const [];
    }

    // Breadth-first search visits paths in increasing length. Stop as soon as
    // five routes have been found so dense parts of the graph stay responsive.
    final found = <_Route>[];
    final queue = <_Route>[
      _Route([from], []),
    ];
    var queueIndex = 0;
    while (queueIndex < queue.length && found.length < 5) {
      final route = queue[queueIndex++];
      final current = route.nodes.last;
      for (final edge in graph[current.slug] ?? const <_Transition>[]) {
        if (route.nodes.any((d) => d.slug == edge.digimon.slug)) continue;
        final next = _Route(
          [...route.nodes, edge.digimon],
          [...route.steps, edge.isEvolution],
        );
        if (edge.digimon.slug == to.slug) {
          found.add(next);
          if (found.length == 5) break;
        } else {
          queue.add(next);
        }
      }
    }
    _cachedFrom = from;
    _cachedTo = to;
    return _cachedRoutes = found;
  }

  @override
  Widget build(BuildContext context) {
    final a = _a, b = _b;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar'),
        actions: [
          IconButton(
            tooltip: 'Intercambiar',
            onPressed: (a == null && b == null)
                ? null
                : () => setState(() {
                    final t = _a;
                    _a = _b;
                    _b = t;
                  }),
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Slot(a, () => _pick(true))),
              const SizedBox(width: 12),
              Expanded(child: _Slot(b, () => _pick(false))),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1, label: Text('Lv 1')),
              ButtonSegment(value: 50, label: Text('Lv 50')),
              ButtonSegment(value: 99, label: Text('Lv 99')),
            ],
            selected: {_level},
            onSelectionChanged: (s) => setState(() => _level = s.first),
          ),
          const SizedBox(height: 16),
          if (a == null || b == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Elegí dos Digimon para compararlos')),
            )
          else ...[
            for (final k in statKeys)
              _CompareRow(
                label: k.toUpperCase(),
                a: a.stats[k]!.atLevel(_level) ?? 0,
                b: b.stats[k]!.atLevel(_level) ?? 0,
              ),
            const Divider(height: 28),
            _CompareRow(label: 'TOTAL', a: _total(a), b: _total(b), bold: true),
            const SizedBox(height: 20),
            _EvolutionRoutes(routes: _routes(a, b)),
          ],
        ],
      ),
    );
  }
}

class _Transition {
  final Digimon digimon;
  final bool isEvolution;
  const _Transition(this.digimon, this.isEvolution);
}

class _Route {
  final List<Digimon> nodes;
  final List<bool> steps;
  const _Route(this.nodes, this.steps);
}

class _EvolutionRoutes extends StatelessWidget {
  final List<_Route> routes;
  const _EvolutionRoutes({required this.routes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Caminos de evolución', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          routes.isEmpty
              ? 'No hay un camino entre estos Digimon en los datos disponibles.'
              : '${routes.length} ${routes.length == 1 ? 'camino' : 'caminos'} · hasta 5 rutas más cortas',
          style: theme.textTheme.bodySmall,
        ),
        if (routes.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (var index = 0; index < routes.length; index++) ...[
            _RouteCard(route: routes[index], index: index),
            if (index < routes.length - 1) const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final _Route route;
  final int index;
  const _RouteCard({required this.route, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 210,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index == 0 ? 'Más corto · ' : ''}${route.steps.length} ${route.steps.length == 1 ? 'paso' : 'pasos'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Divider(height: 14),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: route.nodes.length,
                  itemBuilder: (context, i) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DigimonIcon(route.nodes[i], size: 42),
                            const SizedBox(height: 4),
                            Text(
                              route.nodes[i].name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      if (i < route.steps.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: cs.primary,
                              ),
                              Text(
                                route.steps[i] ? 'Evo.' : 'Devo.',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              if (route.steps[i] &&
                                  route.nodes[i + 1].digivolveReq != null)
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    route.nodes[i + 1].digivolveReq!.summary,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final Digimon? d;
  final VoidCallback onTap;
  const _Slot(this.d, this.onTap);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: d == null
              ? const SizedBox(
                  height: 96,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, size: 32),
                        SizedBox(height: 4),
                        Text('Elegir'),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    DigimonIcon(d!, size: 64),
                    const SizedBox(height: 6),
                    Text(
                      d!.name,
                      style: t.titleSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${d!.dexLabel} · ${d!.stage}',
                      style: t.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final int a, b;
  final bool bold;
  const _CompareRow({
    required this.label,
    required this.a,
    required this.b,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    TextStyle style(bool wins) => TextStyle(
      fontSize: bold ? 18 : 16,
      fontWeight: wins || bold ? FontWeight.bold : FontWeight.normal,
      color: wins ? cs.primary : null,
    );
    final diff = a - b;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text('$a', textAlign: TextAlign.end, style: style(a > b)),
          ),
          SizedBox(
            width: 84,
            child: Column(
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  diff == 0 ? '=' : (diff > 0 ? '◀ +$diff' : '+${-diff} ▶'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text('$b', textAlign: TextAlign.start, style: style(b > a)),
          ),
        ],
      ),
    );
  }
}

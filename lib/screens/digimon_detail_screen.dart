import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../state/collection_store.dart';
import '../widgets/digimon_icon.dart';
import '../widgets/element_icon.dart';
import 'compare_screen.dart';

class DigimonDetailScreen extends StatefulWidget {
  final DigimonRepository repo;
  final Digimon digimon;
  const DigimonDetailScreen({
    super.key,
    required this.repo,
    required this.digimon,
  });

  @override
  State<DigimonDetailScreen> createState() => _DigimonDetailScreenState();
}

class _DigimonDetailScreenState extends State<DigimonDetailScreen> {
  int _level = 99;

  Digimon get d => widget.digimon;

  void _open(String name) {
    final target = widget.repo.byName(name);
    if (target == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DigimonDetailScreen(repo: widget.repo, digimon: target),
      ),
    );
  }

  /// Vuelve al inicio descartando todas las pantallas apiladas
  /// (fichas abiertas desde evoluciones, movimientos, comparador, etc.).
  void _goHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  /// Anterior/siguiente reemplazan la pantalla (el "atrás" sigue volviendo a la lista).
  void _goTo(Digimon target) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DigimonDetailScreen(repo: widget.repo, digimon: target),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final store = context.watch<CollectionStore>();
    final prev = widget.repo.previousOf(d);
    final next = widget.repo.nextOf(d);
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: prev == null
                    ? const SizedBox.shrink()
                    : _NeighborButton(
                        prev,
                        isNext: false,
                        onTap: () => _goTo(prev),
                      ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Inicio',
                onPressed: _goHome,
                icon: const Icon(Icons.home),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: next == null
                    ? const SizedBox.shrink()
                    : _NeighborButton(
                        next,
                        isNext: true,
                        onTap: () => _goTo(next),
                      ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            DigimonIcon(d, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.dexLabel, style: t.labelMedium),
                  Text(
                    d.name,
                    style: t.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _GameBadge('CS', active: d.inCyberSleuth),
          const SizedBox(width: 6),
          const _GameBadge('HM', active: true),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (d.image != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: d.imageOpaque ? Colors.white : null,
                  child: Image.asset(
                    d.image!,
                    height: 240,
                    width: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const SizedBox(height: 240, width: 240),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                FilterChip(
                  avatar: Icon(
                    store.isFavorite(d.slug)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: store.isFavorite(d.slug) ? Colors.redAccent : null,
                  ),
                  label: const Text('Favorito'),
                  selected: store.isFavorite(d.slug),
                  showCheckmark: false,
                  onSelected: (_) => store.toggleFavorite(d.slug),
                ),
                FilterChip(
                  avatar: Icon(
                    store.isRegistered(d.slug)
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: store.isRegistered(d.slug) ? Colors.green : null,
                  ),
                  label: const Text('Registrado'),
                  selected: store.isRegistered(d.slug),
                  showCheckmark: false,
                  onSelected: (_) => store.toggleRegistered(d.slug),
                ),
                ActionChip(
                  avatar: const Icon(Icons.compare_arrows),
                  label: const Text('Comparar'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CompareScreen(repo: widget.repo, initialA: d),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(label: Text(d.stage)),
                    Chip(
                      avatar: ElementIcon(d.attribute),
                      label: Text(d.attribute),
                    ),
                    Chip(label: Text(d.type)),
                  ],
                ),
                if (d.descriptionText != null) ...[
                  const SizedBox(height: 8),
                  Text(d.descriptionText!, style: t.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    if (d.memory != null) 'Memoria ${d.memory}',
                    if (d.equipSlots != null) 'Slots ${d.equipSlots}',
                  ].join(' · '),
                  style: t.bodySmall,
                ),
                if (d.supportSkillName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Support skill: ${d.supportSkillName}',
                    style: t.titleSmall,
                  ),
                  Text(d.supportSkillEffectText ?? '', style: t.bodySmall),
                ],
                if (!d.inCyberSleuth)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Según nuestros datos (estimados), este Digimon no está en Cyber Sleuth.',
                      style: t.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
              ],
            ),
          ),
          _Section(
            title: 'Estadísticas',
            child: Column(
              children: [
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
                const SizedBox(height: 12),
                for (final k in statKeys)
                  _StatBar(statKeys: k, value: d.stats[k]!.atLevel(_level)),
                const Divider(height: 24),
                Text('TOTAL  $_total', style: t.titleMedium),
                Text('Total ponderado (HP/10)  $_weighted', style: t.bodySmall),
              ],
            ),
          ),
          _Section(
            title: 'Movimientos',
            child: d.moves.isEmpty
                ? const Text('Sin movimientos')
                : Column(
                    children: [
                      for (final m in d.moves)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  m.level == null ? '-' : 'Nv ${m.level}',
                                  style: t.labelLarge,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ElementIcon(m.attribute),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            m.name,
                                            style: t.titleSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${m.attribute} · ${m.category} · SP ${m.spCost ?? '-'} · Poder ${m.power ?? '-'} · ${m.learnType}',
                                      style: t.bodySmall,
                                    ),
                                    if (widget.repo.moveEffect(m.name) != null)
                                      Text(
                                        widget.repo.moveEffect(m.name)!,
                                        style: t.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          _Section(
            title: 'Cadena evolutiva',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.digivolveReq != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Para llegar a ${d.name}: ${d.digivolveReq!.summary}',
                      style: t.bodySmall,
                    ),
                  ),
                Text('Evoluciona desde', style: t.titleSmall),
                const SizedBox(height: 8),
                _EvoRow(d.evolvesFrom, widget.repo, _open),
                const SizedBox(height: 16),
                Text('Evoluciona a', style: t.titleSmall),
                const SizedBox(height: 8),
                _EvoRow(d.evolvesTo, widget.repo, _open),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int get _total =>
      statKeys.fold(0, (s, k) => s + (d.stats[k]!.atLevel(_level) ?? 0));
  int get _weighted =>
      _total - ((d.stats['hp']!.atLevel(_level) ?? 0) * 9 ~/ 10);
}

class _GameBadge extends StatelessWidget {
  final String label;
  final bool active;
  const _GameBadge(this.label, {required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? cs.primaryContainer : Colors.transparent,
        border: Border.all(color: active ? cs.primary : cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: active ? cs.onPrimaryContainer : cs.outline,
          decoration: active ? null : TextDecoration.lineThrough,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String statKeys;
  final int? value;
  const _StatBar({required this.statKeys, required this.value});

  // HP escala ~10x respecto del resto: cada barra usa su propio máximo.
  static const _max = {
    'hp': 4000.0,
    'sp': 400.0,
    'atk': 600.0,
    'def': 600.0,
    'int': 600.0,
    'spd': 600.0,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final frac = ((value ?? 0) / _max[statKeys]!).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, c) {
          return Stack(
            children: [
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 36,
                width: (c.maxWidth * frac).clamp(36.0, c.maxWidth),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Text(statKeys.toUpperCase()),
                      const Spacer(),
                      Text(
                        value?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EvoRow extends StatelessWidget {
  final List<EvoLink> links;
  final DigimonRepository repo;
  final void Function(String) onTap;
  const _EvoRow(this.links, this.repo, this.onTap);

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const Text('Ninguno');
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: links.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final e = links[i];
          final target = repo.byName(e.name);
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: target == null ? null : () => onTap(e.name),
            child: SizedBox(
              width: 88,
              child: Column(
                children: [
                  target == null
                      ? const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.help_outline),
                        )
                      : DigimonIcon(target, size: 56),
                  const SizedBox(height: 4),
                  Text(
                    e.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    e.stage,
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NeighborButton extends StatelessWidget {
  final Digimon digimon;
  final bool isNext;
  final VoidCallback onTap;
  const _NeighborButton(
    this.digimon, {
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = Flexible(
      child: Column(
        crossAxisAlignment: isNext
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(digimon.dexLabel, style: Theme.of(context).textTheme.labelSmall),
          Text(digimon.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        children: isNext
            ? [
                label,
                const SizedBox(width: 8),
                DigimonIcon(digimon, size: 28),
                const Icon(Icons.chevron_right),
              ]
            : [
                const Icon(Icons.chevron_left),
                DigimonIcon(digimon, size: 28),
                const SizedBox(width: 8),
                label,
              ],
      ),
    );
  }
}

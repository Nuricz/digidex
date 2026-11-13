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
          ],
        ],
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

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/digimon_icon.dart';
import '../widgets/element_icon.dart';
import 'digimon_detail_screen.dart';

class MovesListScreen extends StatefulWidget {
  final DigimonRepository repo;
  const MovesListScreen({super.key, required this.repo});

  @override
  State<MovesListScreen> createState() => _MovesListScreenState();
}

class _MovesListScreenState extends State<MovesListScreen> {
  String _query = '';
  String? _attribute;
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List<MoveEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    return [
      for (final m in widget.repo.moves)
        if ((q.isEmpty || m.name.toLowerCase().contains(q)) &&
            (_attribute == null || m.attribute == _attribute))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos (${items.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  focusNode: _searchFocus,
                  hintText: 'Buscar movimiento',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final a in widget.repo.moveAttributes)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          avatar: ElementIcon(a),
                          label: Text(a),
                          selected: _attribute == a,
                          onSelected: (on) =>
                              setState(() => _attribute = on ? a : null),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Buscar',
        shape: const CircleBorder(),
        onPressed: () => _searchFocus.requestFocus(),
        child: const Icon(Icons.search),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Sin resultados'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final m = items[i];
                return ListTile(
                  leading: ElementIcon(m.attribute, size: 32),
                  title: Text(m.name),
                  subtitle: Text(
                    '${m.attribute} · ${m.category} · SP ${m.spCost ?? '-'} · Poder ${m.power ?? '-'}',
                  ),
                  trailing: Text('${m.learners.length}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MoveDetailScreen(repo: widget.repo, move: m),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class MoveDetailScreen extends StatelessWidget {
  final DigimonRepository repo;
  final MoveEntry move;
  const MoveDetailScreen({super.key, required this.repo, required this.move});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ElementIcon(move.attribute, size: 28),
            const SizedBox(width: 8),
            Flexible(child: Text(move.name)),
          ],
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${move.attribute} · ${move.category} · SP ${move.spCost ?? '-'} · Poder ${move.power ?? '-'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (repo.moveEffect(move.name) != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    repo.moveEffect(move.name)!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Lo aprenden:'),
          ),
          for (final l in move.learners)
            ListTile(
              leading: DigimonIcon(l.digimon, size: 40),
              title: Text(l.digimon.name),
              subtitle: Text(l.learnType),
              trailing: Text(l.level == null ? '-' : 'Nv ${l.level}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DigimonDetailScreen(repo: repo, digimon: l.digimon),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

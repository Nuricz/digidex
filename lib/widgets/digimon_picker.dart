import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'digimon_icon.dart';

/// Hoja con buscador para elegir un Digimon. Devuelve null si se cierra.
Future<Digimon?> pickDigimon(BuildContext context, DigimonRepository repo) {
  return showModalBottomSheet<Digimon>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _Picker(repo: repo, controller: scroll),
    ),
  );
}

class _Picker extends StatefulWidget {
  final DigimonRepository repo;
  final ScrollController controller;
  const _Picker({required this.repo, required this.controller});

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final items = [
      for (final d in widget.repo.digimon)
        if (q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            d.dex.toString() == q)
          d,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchBar(
            autoFocus: true,
            hintText: 'Buscar Digimon',
            leading: const Icon(Icons.search),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.controller,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final d = items[i];
              return ListTile(
                leading: DigimonIcon(d, size: 40),
                title: Text(d.name),
                subtitle: Text('${d.stage} · ${d.attribute}'),
                trailing: Text(d.dexLabel),
                onTap: () => Navigator.of(context).pop(d),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/element_colors.dart';
import '../widgets/element_icon.dart';

/// Relaciones elementales: (fuerte contra, débil contra).
/// Neutral no tiene ventajas ni desventajas.
const _matchups = <String, ({List<String> strong, List<String> weak})>{
  'Fire': (strong: ['Plant'], weak: ['Water']),
  'Water': (strong: ['Fire'], weak: ['Plant']),
  'Plant': (strong: ['Water'], weak: ['Fire']),
  'Electric': (strong: ['Wind'], weak: ['Earth']),
  'Wind': (strong: ['Earth'], weak: ['Electric']),
  'Earth': (strong: ['Electric'], weak: ['Wind']),
  'Light': (strong: ['Dark'], weak: ['Dark']),
  'Dark': (strong: ['Light'], weak: ['Light']),
  'Neutral': (strong: [], weak: []),
};

const _names = <String, String>{
  'Fire': 'Fuego',
  'Water': 'Agua',
  'Plant': 'Planta',
  'Electric': 'Eléctrico',
  'Wind': 'Viento',
  'Earth': 'Tierra',
  'Light': 'Luz',
  'Dark': 'Oscuridad',
  'Neutral': 'Neutral',
};

/// Relaciones entre tipos (Vaccine > Virus > Data > Vaccine). Free es neutral.
const _typeMatchups = <String, ({String? strong, String? weak})>{
  'Vaccine': (strong: 'Virus', weak: 'Data'),
  'Virus': (strong: 'Data', weak: 'Vaccine'),
  'Data': (strong: 'Vaccine', weak: 'Virus'),
  'Free': (strong: null, weak: null),
};

const _typeNames = <String, String>{
  'Vaccine': 'Vacuna',
  'Virus': 'Virus',
  'Data': 'Dato',
  'Free': 'Libre',
};

const _typeColors = <String, Color>{
  'Vaccine': Color(0xFF3F8FD9),
  'Virus': Color(0xFF7A5BB5),
  'Data': Color(0xFF4FAE5B),
  'Free': Color(0xFF8A8F98),
};

class ElementsScreen extends StatelessWidget {
  const ElementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elementos')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const _SectionTitle('Elementos'),
          for (final e in _matchups.entries)
            _ElementCard(
              element: e.key,
              strong: e.value.strong,
              weak: e.value.weak,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Una ventaja elemental aumenta el daño (≈1.5x). '
              'Luz y Oscuridad son fuertes entre sí; Neutral no tiene ventajas.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const _SectionTitle('Tipos'),
          for (final t in _typeMatchups.entries)
            _TypeCard(type: t.key, strong: t.value.strong, weak: t.value.weak),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Vacuna > Virus > Dato > Vacuna. Libre no tiene ventajas ni '
              'desventajas. El tipo se suma al elemento al calcular el daño.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElementCard extends StatelessWidget {
  final String element;
  final List<String> strong;
  final List<String> weak;
  const _ElementCard({
    required this.element,
    required this.strong,
    required this.weak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: elementColor(element).withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Row(
                children: [
                  ElementIcon(element, size: 28),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _names[element]!,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(
                    Icons.arrow_upward,
                    Colors.green,
                    'Fuerte contra',
                    strong,
                  ),
                  const SizedBox(height: 4),
                  _line(Icons.arrow_downward, Colors.red, 'Débil contra', weak),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, Color color, String label, List<String> els) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12)),
        if (els.isEmpty)
          const Text('—')
        else
          for (final e in els) ...[
            ElementIcon(e, size: 22),
            const SizedBox(width: 4),
          ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Ícono + nombre del tipo, sin chip. `big` lo dibuja como el título de una tarjeta.
class _TypeLabel extends StatelessWidget {
  final String type;
  final bool big;
  const _TypeLabel(this.type, {this.big = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/attributes/${type.toLowerCase()}.webp',
          width: big ? 28 : 22,
          height: big ? 28 : 22,
        ),
        const SizedBox(width: 4),
        Text(
          _typeNames[type]!,
          style: big
              ? Theme.of(context).textTheme.titleSmall
              : const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String type;
  final String? strong;
  final String? weak;
  const _TypeCard({required this.type, this.strong, this.weak});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _typeColors[type]!.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypeLabel(type, big: true),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(
                    Icons.arrow_upward,
                    Colors.green,
                    'Fuerte contra',
                    strong,
                  ),
                  const SizedBox(height: 4),
                  _line(Icons.arrow_downward, Colors.red, 'Débil contra', weak),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, Color color, String label, String? t) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(fontSize: 12)),
      if (t == null) const Text('—') else _TypeLabel(t),
    ],
  );
}

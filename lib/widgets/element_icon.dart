import 'package:flutter/material.dart';

/// Ícono de elemento (Fire, Water, ...). Si no hay imagen (ej. "None"), no dibuja nada.
class ElementIcon extends StatelessWidget {
  final String element;
  final double size;
  const ElementIcon(this.element, {super.key, this.size = 20});

  static const _known = {
    'dark',
    'earth',
    'electric',
    'fire',
    'light',
    'neutral',
    'plant',
    'water',
    'wind',
  };

  @override
  Widget build(BuildContext context) {
    final key = element.toLowerCase();
    if (!_known.contains(key)) return SizedBox(width: size, height: size);
    return Image.asset('assets/elements/$key.png', width: size, height: size);
  }
}

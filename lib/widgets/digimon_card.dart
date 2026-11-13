import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/collection_store.dart';
import 'digimon_icon.dart';
import 'element_colors.dart';
import 'element_icon.dart';

/// Fila de la lista: ícono a la izquierda, nombre, chips de atributo y etapa
/// (solo el de atributo lleva el color del elemento) y, a la derecha, número y
/// los botones de favorito y "registrado".
class DigimonCard extends StatelessWidget {
  final Digimon digimon;
  final VoidCallback onTap;

  /// Texto destacado bajo los chips (ej. "ATK 237" o "ABI 75").
  final String? badge;
  const DigimonCard({
    super.key,
    required this.digimon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final d = digimon;
    final store = context.watch<CollectionStore>();
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final tone = elementColor(d.attribute);
    final fav = store.isFavorite(d.slug), reg = store.isRegistered(d.slug);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                DigimonIcon(d, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: t.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Pill(
                            color: tone,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElementIcon(d.attribute, size: 14),
                                const SizedBox(width: 4),
                                Text(d.attribute, style: t.labelSmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              d.stage,
                              style: t.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (badge != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            badge!,
                            style: t.labelLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(d.dexLabel, style: t.labelLarge),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Toggle(
                          tooltip: 'Favorito',
                          on: fav,
                          iconOn: Icons.favorite,
                          iconOff: Icons.favorite_border,
                          onColor: Colors.redAccent,
                          onTap: () => store.toggleFavorite(d.slug),
                        ),
                        _Toggle(
                          tooltip: 'Registrado en el juego',
                          on: reg,
                          iconOn: Icons.check_circle,
                          iconOff: Icons.check_circle_outline,
                          onColor: Colors.green,
                          onTap: () => store.toggleRegistered(d.slug),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 84, color: cs.outlineVariant),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String tooltip;
  final bool on;
  final IconData iconOn, iconOff;
  final Color onColor;
  final VoidCallback onTap;
  const _Toggle({
    required this.tooltip,
    required this.on,
    required this.iconOn,
    required this.iconOff,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
    onPressed: onTap,
    icon: Icon(on ? iconOn : iconOff, color: on ? onColor : null, size: 24),
  );
}

/// Chip del atributo, teñido con el color del elemento.
class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Pill({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

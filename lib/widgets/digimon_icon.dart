import 'package:flutter/material.dart';

import '../data/models.dart';

class DigimonIcon extends StatelessWidget {
  final Digimon digimon;
  final double size;
  const DigimonIcon(this.digimon, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        digimon.iconAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}

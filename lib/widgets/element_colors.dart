import 'package:flutter/material.dart';

/// Color asociado a cada elemento, para teñir tarjetas.
Color elementColor(String element) => switch (element.toLowerCase()) {
  'fire' => const Color(0xFFE5533D),
  'water' => const Color(0xFF3F8FD9),
  'plant' => const Color(0xFF4FAE5B),
  'wind' => const Color(0xFF3FB5A8),
  'earth' => const Color(0xFFA9794B),
  'electric' => const Color(0xFFE2B52B),
  'light' => const Color(0xFFD9C45A),
  'dark' => const Color(0xFF7A5BB5),
  _ => const Color(0xFF8A8F98), // Neutral / None
};

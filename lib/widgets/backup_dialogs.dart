import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../state/collection_store.dart';

void _snack(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));

/// Copia el respaldo al portapapeles y lo muestra para poder guardarlo.
Future<void> exportCollection(
  BuildContext context,
  CollectionStore store,
) async {
  final backup = store.snapshot();
  final text = backup.toJson();
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exportar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${backup.favorites.length} favoritos y '
              '${backup.registered.length} registrados copiados al portapapeles.\n\n'
              'Pegalo en una nota, un chat o un mail para guardarlo. '
              'Para recuperarlo: Importar y pegar este texto.',
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(child: SelectableText(text)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (ctx.mounted) _snack(ctx, 'Copiado de nuevo');
          },
          child: const Text('Copiar de nuevo'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

/// Pide el texto del respaldo, lo valida y lo aplica (combinar o reemplazar).
Future<void> importCollection(
  BuildContext context,
  CollectionStore store,
  DigimonRepository repo,
) async {
  final controller = TextEditingController();
  var replace = false;
  String? error;
  final slugs = repo.digimon.map((d) => d.slug).toSet();

  final done = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Importar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pegá acá el texto que exportaste.'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '{"app":"digidex", ...}',
                  errorText: error,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Pegar'),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      setState(() {
                        controller.text = data!.text!;
                        error = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 4),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Combinar')),
                  ButtonSegment(value: true, label: Text('Reemplazar')),
                ],
                selected: {replace},
                onSelectionChanged: (s) => setState(() => replace = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                replace
                    ? 'Se borran tus marcas actuales y quedan solo las del texto.'
                    : 'Se suman a las que ya tenés; no se borra nada.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final CollectionBackup backup;
              try {
                backup = CollectionBackup.parse(controller.text);
              } on FormatException catch (e) {
                setState(() => error = e.message);
                return;
              }
              if (replace &&
                  (store.favoriteCount + store.registeredCount) > 0) {
                final ok = await showDialog<bool>(
                  context: ctx,
                  builder: (c) => AlertDialog(
                    title: const Text('¿Reemplazar todo?'),
                    content: const Text(
                      'Se van a perder tus favoritos y registrados actuales.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('Reemplazar'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
              }
              final r = await store.restore(
                backup,
                replace: replace,
                validSlugs: slugs,
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(true);
              if (context.mounted) {
                _snack(
                  context,
                  'Importado: ${r.favorites} favoritos, ${r.registered} registrados'
                  '${r.ignored > 0 ? ' (${r.ignored} ignorados por no existir)' : ''}',
                );
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (done != true) return;
}

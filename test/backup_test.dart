import 'package:digimon_pokedex/state/collection_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final valid = {'agumon', 'gabumon', 'kuramon', 'patamon'};

  Future<CollectionStore> storeWith({
    List<String> fav = const [],
    List<String> reg = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final s = CollectionStore();
    await s.load();
    for (final f in fav) {
      await s.toggleFavorite(f);
    }
    for (final r in reg) {
      await s.toggleRegistered(r);
    }
    return s;
  }

  test(
    'exportar e importar en otra instancia conserva todo (ida y vuelta)',
    () async {
      final a = await storeWith(fav: ['agumon'], reg: ['agumon', 'kuramon']);
      final text = a.snapshot().toJson();

      final b = await storeWith();
      final r = await b.restore(
        CollectionBackup.parse(text),
        replace: false,
        validSlugs: valid,
      );
      expect(r.favorites, 1);
      expect(r.registered, 2);
      expect(r.ignored, 0);
      expect(b.isFavorite('agumon'), isTrue);
      expect(b.isRegistered('kuramon'), isTrue);
    },
  );

  test('combinar suma sin borrar; reemplazar pisa lo actual', () async {
    final backup = CollectionBackup({'gabumon'}, {'patamon'});

    final merge = await storeWith(fav: ['agumon'], reg: ['kuramon']);
    await merge.restore(backup, replace: false, validSlugs: valid);
    expect(merge.isFavorite('agumon'), isTrue);
    expect(merge.isFavorite('gabumon'), isTrue);
    expect(merge.isRegistered('kuramon'), isTrue);
    expect(merge.isRegistered('patamon'), isTrue);

    final repl = await storeWith(fav: ['agumon'], reg: ['kuramon']);
    await repl.restore(backup, replace: true, validSlugs: valid);
    expect(repl.isFavorite('agumon'), isFalse);
    expect(repl.isFavorite('gabumon'), isTrue);
    expect(repl.isRegistered('kuramon'), isFalse);
    expect(repl.isRegistered('patamon'), isTrue);
  });

  test('los Digimon que no existen se ignoran y se cuentan', () async {
    final s = await storeWith();
    final r = await s.restore(
      CollectionBackup({'agumon', 'noexiste'}, {'otro-inexistente'}),
      replace: false,
      validSlugs: valid,
    );
    expect(r.favorites, 1);
    expect(r.registered, 0);
    expect(r.ignored, 2);
    expect(s.isFavorite('noexiste'), isFalse);
  });

  test('lo importado se persiste (una instancia nueva lo ve)', () async {
    final s = await storeWith();
    await s.restore(
      CollectionBackup({'agumon'}, {'gabumon'}),
      replace: true,
      validSlugs: valid,
    );
    final again = CollectionStore();
    await again.load();
    expect(again.isFavorite('agumon'), isTrue);
    expect(again.isRegistered('gabumon'), isTrue);
  });

  test('textos inválidos dan un error claro y no rompen nada', () {
    for (final bad in [
      '',
      'hola',
      '[]',
      '{"app":"otra-cosa"}',
      '{"app":"digidex","version":99,"favorites":[],"registered":[]}',
      '{"app":"digidex","version":1,"registered":[]}',
    ]) {
      expect(
        () => CollectionBackup.parse(bad),
        throwsA(isA<FormatException>()),
        reason: 'debía rechazar: $bad',
      );
    }
  });

  test('tolera espacios y elementos que no son texto', () {
    final b = CollectionBackup.parse(
      '  {"app":"digidex","version":1,"favorites":["agumon",5,null],"registered":[]}  ',
    );
    expect(b.favorites, {'agumon'});
  });
}

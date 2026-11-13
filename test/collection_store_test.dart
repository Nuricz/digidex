import 'package:digimon_pokedex/state/collection_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favoritos y registrados se guardan y se recuperan', () async {
    SharedPreferences.setMockInitialValues({});
    final a = CollectionStore();
    await a.load();
    await a.toggleFavorite('agumon');
    await a.toggleRegistered('agumon');
    await a.toggleRegistered('gabumon');
    await a.toggleRegistered('gabumon'); // lo desmarca

    final b = CollectionStore();
    await b.load(); // instancia nueva: lee lo persistido
    expect(b.isFavorite('agumon'), isTrue);
    expect(b.isRegistered('agumon'), isTrue);
    expect(b.isRegistered('gabumon'), isFalse);
    expect(b.favoriteCount, 1);
    expect(b.registeredCount, 1);
  });
}

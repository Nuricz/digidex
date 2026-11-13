import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'state/collection_store.dart';
import 'screens/compare_screen.dart';
import 'screens/digimon_list_screen.dart';
import 'screens/moves_list_screen.dart';

void main() {
  runApp(const DigimonPokedexApp());
}

class DigimonPokedexApp extends StatelessWidget {
  const DigimonPokedexApp({super.key});

  /// La AppBar de Material 3 cambia de color al scrollear (estado "scrolled under")
  /// salvo que se le fije un color explícito: por eso backgroundColor fijo.
  static ThemeData buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CollectionStore()..load(),
      child: MaterialApp(
        title: 'DigiDex',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const _Loader(),
      ),
    );
  }
}

class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  late final Future<DigimonRepository> _future = DigimonRepository.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DigimonRepository>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Error cargando datos:\n${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeShell(repo: snap.data!);
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  final DigimonRepository repo;
  const HomeShell({super.key, required this.repo});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DigimonListScreen(repo: widget.repo),
          MovesListScreen(repo: widget.repo),
          CompareScreen(repo: widget.repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            label: 'Digimon',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Comparar',
          ),
        ],
      ),
    );
  }
}

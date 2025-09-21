import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/game_screen.dart';
import 'models/game_state.dart';

void main() {
  runApp(const KlondikeApp());
}

class KlondikeApp extends StatelessWidget {
  const KlondikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Klondike Solitaire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
    );
  }

  static final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final gameId = state.pathParameters['id']!;
          final seedParam = state.uri.queryParameters['seed'];
          final seed = seedParam != null ? int.tryParse(seedParam) : null;
          return ChangeNotifierProvider(
            create: (context) => GameProvider(gameId: gameId, seed: seed),
            child: const GameScreen(),
          );
        },
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final gameId = GameState().gameId;
          return '/game/$gameId';
        },
      ),
    ],
  );
}
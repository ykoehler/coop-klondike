import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/game_screen.dart';
import 'screens/error_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/game_state.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase.instance.databaseURL = 'https://coop-klondike-default-rtdb.firebaseio.com';
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
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final gameId = state.pathParameters['id']!;
          if (!RegExp(r'^[A-Z0-9]{5}-[A-Z0-9]{5}$').hasMatch(gameId)) {
            return const ErrorScreen(message: 'Invalid game ID format');
          }
          return ChangeNotifierProvider(
            create: (context) => GameProvider(
              firebaseService: FirebaseService(),
              gameId: gameId,
            ),
            child: const GameScreen(),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          // Create a new game state when hitting the root
          final gameState = GameState();
          return ChangeNotifierProvider(
            create: (context) => GameProvider(
              firebaseService: FirebaseService(),
              gameId: gameState.gameId,
              isInitialSetup: true,
            ),
            child: Builder(
              builder: (context) {
                // Redirect to the game URL after provider is ready
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.go('/game/${gameState.gameId}');
                  }
                });
                return const GameScreen();
              },
            ),
          );
        },
      ),
    ],
  );
}
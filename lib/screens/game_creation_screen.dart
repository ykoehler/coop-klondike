import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/seed_generator.dart';
import '../models/game_state.dart';

class GameCreationScreen extends StatefulWidget {
  const GameCreationScreen({super.key});

  @override
  State<GameCreationScreen> createState() => _GameCreationScreenState();
}

class _GameCreationScreenState extends State<GameCreationScreen> {
  late TextEditingController _seedController;
  DrawMode _selectedDrawMode = DrawMode.three;

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(text: SeedGenerator.generateSeed());
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _generateNewSeed() {
    setState(() {
      _seedController.text = SeedGenerator.generateSeed();
    });
  }

  void _startGame() {
    String seed = _seedController.text.trim();
    if (seed.isEmpty) {
      seed = SeedGenerator.generateSeed();
      _seedController.text = seed;
    }
    final gameId = _generateGameId();
    context.go('/game/$gameId', extra: {'seed': seed, 'drawMode': _selectedDrawMode});
  }

  static String _generateGameId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String part1 = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    String part2 = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    return '$part1-$part2';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a seed for the game deck (optional):',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seedController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g., whale42jump',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _generateNewSeed,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Generate new seed',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Stock draw mode:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            SegmentedButton<DrawMode>(
              segments: const [
                ButtonSegment<DrawMode>(
                  value: DrawMode.one,
                  label: Text('1 Card'),
                ),
                ButtonSegment<DrawMode>(
                  value: DrawMode.three,
                  label: Text('3 Cards'),
                ),
              ],
              selected: {_selectedDrawMode},
              onSelectionChanged: (Set<DrawMode> selected) {
                setState(() {
                  _selectedDrawMode = selected.first;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final isWon = provider.isGameWon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klondike Solitaire'),
        actions: [
          ElevatedButton(
            onPressed: () => provider.newGame(),
            child: const Text('New Game'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const GameBoard(),
          if (isWon)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Congratulations!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('You won the game!'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => provider.newGame(),
                          child: const Text('Play Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
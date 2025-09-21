import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';
import '../models/game_state.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GoRouter _router;
  DrawMode _selectedDrawMode = DrawMode.one;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDrawModeDialog();
    });
  }

  void _showDrawModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Choose Draw Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<DrawMode>(
              title: const Text('1 Card Draw'),
              value: DrawMode.one,
              groupValue: _selectedDrawMode,
              onChanged: (value) => setState(() => _selectedDrawMode = value!),
            ),
            RadioListTile<DrawMode>(
              title: const Text('3 Card Draw'),
              subtitle: const Text('3 Card Draw is more challenging'),
              value: DrawMode.three,
              groupValue: _selectedDrawMode,
              onChanged: (value) => setState(() => _selectedDrawMode = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<GameProvider>(context, listen: false);
              provider.changeDrawMode(_selectedDrawMode);
              provider.newGame();
              final newGameId = provider.gameId;
              _router.go('/game/$newGameId');
              Navigator.of(context).pop();
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }
  void _showSettingsDialog() {
    final provider = Provider.of<GameProvider>(context, listen: false);
    setState(() => _selectedDrawMode = provider.drawMode);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draw Mode Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<DrawMode>(
              title: const Text('1 Card Draw'),
              value: DrawMode.one,
              groupValue: _selectedDrawMode,
              onChanged: (value) => setState(() => _selectedDrawMode = value!),
            ),
            RadioListTile<DrawMode>(
              title: const Text('3 Card Draw'),
              value: DrawMode.three,
              groupValue: _selectedDrawMode,
              onChanged: (value) => setState(() => _selectedDrawMode = value!),
            ),
            const SizedBox(height: 10),
            const Text(
              'Changing the mode affects future draws.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.changeDrawMode(_selectedDrawMode);
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _copyGameId() {
    final provider = Provider.of<GameProvider>(context, listen: false);
    Clipboard.setData(ClipboardData(text: provider.gameId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game ID copied to clipboard')),
    );
  }

  @override

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final isWon = provider.isGameWon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klondike Solitaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy Game ID',
            onPressed: _copyGameId,
          ),
          Text(
            'Game: ${provider.gameId}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          ElevatedButton(
            onPressed: _showDrawModeDialog,
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
                          onPressed: _showDrawModeDialog,
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
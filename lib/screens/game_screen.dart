import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';
import '../models/game_state.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_utils.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  DrawMode _selectedDrawMode = DrawMode.one;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDrawModeDialog();
    });
  }

  void _showDrawModeDialog() {
    print('DEBUG: _showDrawModeDialog called, current _selectedDrawMode: $_selectedDrawMode');
    final provider = Provider.of<GameProvider>(context, listen: false);
    final router = GoRouter.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DrawModeDialog(
        initialDrawMode: _selectedDrawMode,
        onModeSelected: (selectedMode) {
          print('DEBUG: Draw mode selected: $selectedMode');
          print('DEBUG: Provider drawMode before change: ${provider.drawMode}');
          provider.changeDrawMode(selectedMode);
          print('DEBUG: Provider drawMode after change: ${provider.drawMode}');
          provider.newGame();
          final newGameId = provider.gameId;
          print('DEBUG: New game ID: $newGameId');
          router.go('/game/$newGameId');
          Navigator.of(dialogContext).pop();
        },
        onCancel: () {
          print('DEBUG: Cancel button pressed');
          Navigator.of(dialogContext).pop();
        },
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResponsiveUtils.getAppBarHeight(context)),
        child: AppBar(
          title: const Text('Klondike Solitaire'),
          actions: [
            IconButton(
              icon: const Icon(Icons.content_copy),
              tooltip: 'Copy Game ID',
              onPressed: _copyGameId,
            ),
            Text(
              'Game: ${provider.gameId}',
              style: TextStyle(fontSize: ResponsiveUtils.getAppBarFontSize(context)),
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
      ),
      body: SafeArea(
        child: Stack(
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
      ),
    );
  }
}

class _DrawModeDialog extends StatefulWidget {
  final DrawMode initialDrawMode;
  final Function(DrawMode) onModeSelected;
  final VoidCallback onCancel;

  const _DrawModeDialog({
    required this.initialDrawMode,
    required this.onModeSelected,
    required this.onCancel,
  });

  @override
  State<_DrawModeDialog> createState() => _DrawModeDialogState();
}

class _DrawModeDialogState extends State<_DrawModeDialog> {
  late DrawMode _selectedDrawMode;

  @override
  void initState() {
    super.initState();
    _selectedDrawMode = widget.initialDrawMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Draw Mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<DrawMode>(
            title: const Text('1 Card Draw'),
            value: DrawMode.one,
            groupValue: _selectedDrawMode,
            onChanged: (value) {
              print('DEBUG: 1 Card Draw selected, value: $value');
              setState(() => _selectedDrawMode = value!);
              print('DEBUG: _selectedDrawMode updated to: $_selectedDrawMode');
            },
          ),
          RadioListTile<DrawMode>(
            title: const Text('3 Card Draw'),
            subtitle: const Text('3 Card Draw is more challenging'),
            value: DrawMode.three,
            groupValue: _selectedDrawMode,
            onChanged: (value) {
              print('DEBUG: 3 Card Draw selected, value: $value');
              setState(() => _selectedDrawMode = value!);
              print('DEBUG: _selectedDrawMode updated to: $_selectedDrawMode');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onModeSelected(_selectedDrawMode),
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}
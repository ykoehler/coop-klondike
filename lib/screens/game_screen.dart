import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';
import '../models/game_state.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_utils.dart';
import '../utils/test_hooks.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  DrawMode _selectedDrawMode = DrawMode.three;
  bool _hooksRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDialogDisplay();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hooksRegistered) {
      final provider = Provider.of<GameProvider>(context, listen: false);
      registerTestHooks(provider);
      _hooksRegistered = true;
    }
  }

  void _checkForDialogDisplay() {
    final provider = Provider.of<GameProvider>(context, listen: false);
    
    // If still initializing, wait for completion
    if (provider.isInitializing) {
      // Schedule another check after initialization might be complete
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _checkForDialogDisplay();
        }
      });
      return;
    }
    
    // Only show dialog if this is a new game (not existing in Firebase)
    if (!provider.gameState.existsInFirebase) {
      _showDrawModeDialog();
    }
  }

  void _showDrawModeDialog() {
    final provider = Provider.of<GameProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,  // Prevent dialog from being dismissed with back button
        child: _DrawModeDialog(
          initialDrawMode: _selectedDrawMode,
          onModeSelected: (selectedMode) async {
            try {
              provider.changeDrawMode(selectedMode);
              await provider.setupInitialGameState();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            } catch (e) {
              print('Error starting game: $e');
            }
          },
          onCancel: () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        ),
      ),
    );
  }
  
  void _showNewGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _NewGameDialog(
        onCreateGame: (seed, drawMode) async {
          final provider = Provider.of<GameProvider>(context, listen: false);
          final newGameId = await provider.newGame(seed: seed, drawMode: drawMode);
          if (newGameId != null && mounted) {
            context.go('/game/$newGameId');
          }
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
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DrawMode>(
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
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedDrawMode = selection.first;
                  });
                },
              ),
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
              onPressed: _showNewGameDialog,
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

class _NewGameDialog extends StatefulWidget {
  final Function(String seed, DrawMode drawMode) onCreateGame;

  const _NewGameDialog({
    required this.onCreateGame,
  });

  @override
  State<_NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<_NewGameDialog> {
  late TextEditingController _seedController;
  DrawMode _selectedDrawMode = DrawMode.three;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(text: _generateSeed());
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  String _generateSeed() {
    const adjectives = ['blue', 'red', 'green', 'yellow', 'purple', 'orange', 'pink', 'crimson', 'silver', 'golden'];
    const nouns = ['whale', 'tiger', 'eagle', 'dolphin', 'lion', 'shark', 'wolf', 'bear', 'hawk', 'fox'];
    final random = DateTime.now().millisecondsSinceEpoch;
    final adj = adjectives[random % adjectives.length];
    final num = (random % 100).toString().padLeft(2, '0');
    final noun = nouns[(random ~/ 100) % nouns.length];
    return '$adj$num$noun';
  }

  void _generateNewSeed() {
    setState(() {
      _seedController.text = _generateSeed();
    });
  }

  Future<void> _handleCreateGame() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    try {
      String seed = _seedController.text.trim();
      if (seed.isEmpty) {
        seed = _generateSeed();
      }
      await widget.onCreateGame(seed, _selectedDrawMode);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating game: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Game Setup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter a seed for the game deck:',
            style: TextStyle(fontSize: 14),
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
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isProcessing ? null : _generateNewSeed,
                icon: const Icon(Icons.refresh),
                tooltip: 'Generate new seed',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Stock draw mode:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<DrawMode>(
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
              onSelectionChanged: _isProcessing
                  ? null
                  : (Set<DrawMode> selected) {
                      setState(() {
                        _selectedDrawMode = selected.first;
                      });
                    },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '3 Card Draw is more challenging',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleCreateGame,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Game'),
        ),
      ],
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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedDrawMode = widget.initialDrawMode;
  }

  void _handleModeChange(Set<DrawMode> selection) {
    if (!_isProcessing) {
      setState(() {
        _selectedDrawMode = selection.first;
      });
    }
  }

  Future<void> _handleStartGame() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    try {
      await widget.onModeSelected(_selectedDrawMode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Choose Draw Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DrawMode>(
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
                onSelectionChanged: _handleModeChange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '3 Card Draw is more challenging',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleStartGame,
            child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Game'),
          ),
        ],
      ),
    );
  }
}
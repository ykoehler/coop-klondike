import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgDebugScreen extends StatefulWidget {
  const SvgDebugScreen({super.key});

  @override
  State<SvgDebugScreen> createState() => _SvgDebugScreenState();
}

class _SvgDebugScreenState extends State<SvgDebugScreen> {
  final List<String> _logs = [];

  void _log(String message, {bool isError = false}) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 23);
      _logs.add('[$timestamp] ${isError ? "❌" : "✓"} $message');
    });
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Loading Debug'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SVG Loading Tests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test 1: Face Down Card
            _buildTestSection(
              'Test 1: Face Down Card',
              'assets/cards/svgs/card_face_down.svg',
              'Face Down',
            ),
            
            const SizedBox(height: 20),
            
            // Test 2: Sample Face Up Cards
            _buildTestSection(
              'Test 2: Ace of Hearts',
              'assets/cards/svgs/hearts_a.svg',
              'Hearts A',
            ),
            
            const SizedBox(height: 20),
            
            _buildTestSection(
              'Test 3: King of Spades',
              'assets/cards/svgs/spades_k.svg',
              'Spades K',
            ),
            
            const SizedBox(height: 20),
            
            _buildTestSection(
              'Test 4: 10 of Diamonds',
              'assets/cards/svgs/diamonds_10.svg',
              'Diamonds 10',
            ),
            
            const SizedBox(height: 20),
            
            // Invalid path test
            _buildTestSection(
              'Test 5: Invalid Path (should fail)',
              'assets/cards/svgs/invalid_card.svg',
              'Invalid',
            ),
            
            const SizedBox(height: 30),
            
            // Logs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Console Logs:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _logs.map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: log.contains('❌') ? Colors.red : Colors.green,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(String title, String assetPath, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Path: $assetPath',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 120,
                height: 168,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  assetPath,
                  width: 120,
                  height: 168,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) {
                    _log('Loading $label...');
                    return Container(
                      color: Colors.blue,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    _log('Failed to load $label: $error', isError: true);
                    return Container(
                      color: Colors.red,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Error\n$label',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _log('Manually reloading $label');
                        setState(() {});
                      },
                      child: const Text('Reload'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

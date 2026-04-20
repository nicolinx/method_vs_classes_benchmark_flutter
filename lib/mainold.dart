import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Real World GC Stutter Test',
      home: AnimationBenchmarkScreen(),
    );
  }
}

class AnimationBenchmarkScreen extends StatefulWidget {
  const AnimationBenchmarkScreen({super.key});

  @override
  State<AnimationBenchmarkScreen> createState() =>
      _AnimationBenchmarkScreenState();
}

class _AnimationBenchmarkScreenState extends State<AnimationBenchmarkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _useConstClass = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ❌ THE METHOD: Allocates thousands of objects per frame natively.
  // This causes real Garbage Collection pauses and Diffing lag.
  Widget _buildMassivePixelGrid() {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: List.generate(
        2500, // 2,500 widgets created 60 times a second
        (index) => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: index % 2 == 0 ? Colors.red.shade200 : Colors.red.shade700,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Performance: Method vs Class')),
      body: Center(
        child: Column(
          children: [
            // Control Panel
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _useConstClass,
                    activeThumbColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    inactiveTrackColor: Colors.red.shade200,
                    onChanged: (value) =>
                        setState(() => _useConstClass = value),
                  ),
                  const Text(
                    'Class',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // The Animation Rebuilder
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: _controller.value * 2 * pi,
                        child: Icon(
                          Icons.settings,
                          size: 72,
                          color: _useConstClass ? Colors.green : Colors.red,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1E1E1E,
                          ), // Authentic VS Code Dark Theme background
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: _useConstClass ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            // Default text style for the code block
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15,
                              height: 1.5, // Adds breathing room between lines
                              color: Colors.white70,
                            ),
                            children: [
                              const TextSpan(text: 'List.generate(\n'),
                              const TextSpan(
                                text: '  2500,\n',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                ), // Numbers in orange
                              ),
                              const TextSpan(text: '  (index) => '),

                              // This is where the magic happens. It swaps the code and colors!
                              if (_useConstClass) ...[
                                const TextSpan(
                                  text: 'const ',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'ConstPixelGrid(),\n',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ] else ...[
                                const TextSpan(
                                  text: '_buildMassivePixelGrid(),\n',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],

                              const TextSpan(text: ');'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // THE PAYLOAD 👇
                      // We wrap it in a SizedBox so it doesn't overflow
                      SizedBox(
                        width: 400,
                        child: _useConstClass
                            ? const ConstPixelGrid() // ✅ 0 allocations per frame
                            : _buildMassivePixelGrid(), // ❌ 2,500 allocations per frame
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ THE CONST CLASS: The 2,500 pixels are cached in memory.
// Flutter skips diffing them, and the Garbage Collector rests easy.
class ConstPixelGrid extends StatelessWidget {
  const ConstPixelGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: List.generate(
        2500,
        (index) => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: index % 2 == 0
                ? Colors.green.shade200
                : Colors.green.shade700,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

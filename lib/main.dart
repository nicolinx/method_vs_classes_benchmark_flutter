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
      title: 'GC Overload Test',
      debugShowCheckedModeBanner: false,
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

  // ❌ THE METHOD: Allocates a brand new Container and BoxDecoration in memory
  // every single time it is called.
  Widget _buildPixelMethod() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter Performance: Method vs Class',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
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

            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spinning Gear
                      Transform.rotate(
                        angle: _controller.value * 2 * pi,
                        child: Icon(
                          Icons.settings,
                          size: 72,
                          color: _useConstClass ? Colors.green : Colors.red,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _useConstClass
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF5252),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 8,
                            //     vertical: 4,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: _useConstClass
                            //         ? const Color(
                            //             0xFF00E676,
                            //           ).withValues(alpha: 0.25)
                            //         : const Color(
                            //             0xFFFF5252,
                            //           ).withValues(alpha: 0.25),
                            //     borderRadius: BorderRadius.circular(4),
                            //   ),
                            //   child: Text(
                            //     _useConstClass
                            //         ? '✅ 1 single memory allocation reused 2500x'
                            //         : '❌ 2500 new memory allocations/frame',
                            //     style: TextStyle(
                            //       color: _useConstClass
                            //           ? const Color(0xFF00E676)
                            //           : const Color(0xFFFF5252),
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),

                            // const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                  color: Color(0xFFFFFFFF),
                                ),
                                children: [
                                  const TextSpan(text: 'List.generate(\n'),
                                  const TextSpan(
                                    text: '  2500,\n',
                                    style: TextStyle(
                                      color: Color(0xFFFFCA28),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: '  (index) => '),
                                  if (_useConstClass)
                                    const TextSpan(
                                      text: 'const PixelClass(),\n',
                                      style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    const TextSpan(
                                      text: '_buildPixelMethod(),\n',
                                      style: TextStyle(
                                        color: Color(0xFFFF5252),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const TextSpan(text: ');'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: 400,
                        child: Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: List.generate(
                            2500,
                            (index) => _useConstClass
                                ? const PixelClass()
                                : _buildPixelMethod(),
                          ),
                        ),
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

// ✅ THE CONST CLASS: Flutter allocates this exact blueprint in memory ONE time.
// It uses that same cached memory reference for all 2,500 pixels.
class PixelClass extends StatelessWidget {
  const PixelClass({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.green.shade400,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

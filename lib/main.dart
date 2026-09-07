import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'core/depth.dart';

void main() => runApp(const DepthFlowApp());

class DepthFlowApp extends StatelessWidget {
  const DepthFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DepthFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF080A12)),
      home: const DepthScreen(),
    );
  }
}

class DepthScreen extends StatefulWidget {
  const DepthScreen({super.key});

  @override
  State<DepthScreen> createState() => _DepthScreenState();
}

class _DepthScreenState extends State<DepthScreen> {
  Vec2 _tilt = const Vec2(0, 0);
  final _layers = demoScene();

  void _onHover(Offset local, Size size) {
    setState(() => _tilt = tiltFromPointer(local.dx, local.dy, size.width, size.height));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return MouseRegion(
                onHover: (e) => _onHover(e.localPosition, size),
                child: GestureDetector(
                  onPanUpdate: (e) => _onHover(e.localPosition, size),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _Parallax(
                          tilt: _tilt,
                          depth: 0.05,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(-0.4, -0.7),
                                radius: 1.3,
                                colors: [Color(0xFF241E52), Color(0xFF080A12)],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _orb(0.15, const Alignment(-0.7, -0.3), 160, const Color(0x3341347C)),
                      _orb(0.35, const Alignment(0.8, 0.1), 120, const Color(0x2634D9C8)),
                      Positioned(
                        top: 46,
                        left: 20,
                        child: _Parallax(tilt: _tilt, depth: 0.6, child: const _Header()),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
                          child: _SceneStack(tilt: _tilt, layers: _layers),
                        ),
                      ),
                      const Positioned(
                        bottom: 18,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text('move your pointer to feel the depth', style: TextStyle(color: Color(0xFF6B7488), fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _orb(double depth, Alignment align, double diameter, Color color) {
    return Align(
      alignment: align,
      child: _Parallax(
        tilt: _tilt,
        depth: depth,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DepthFlow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
        SizedBox(height: 2),
        Text('A spatial workspace with real depth', style: TextStyle(color: Color(0xFF98A2B8), fontSize: 13)),
      ],
    );
  }
}

/// Lays the content layers out, each shifted, blurred, scaled and shadowed by its depth.
class _SceneStack extends StatelessWidget {
  const _SceneStack({required this.tilt, required this.layers});
  final Vec2 tilt;
  final List<DepthLayer> layers;

  @override
  Widget build(BuildContext context) {
    final content = layers.where((l) => l.id != 'bg').toList();
    return Stack(
      children: [
        for (var i = 0; i < content.length; i++)
          Align(
            alignment: Alignment(0, -0.5 + i * 0.32),
            child: _Parallax(
              tilt: tilt,
              depth: content[i].depth,
              child: _LayerCard(layer: content[i]),
            ),
          ),
      ],
    );
  }
}

/// Applies the depth math to a child: parallax translate + depth scale.
class _Parallax extends StatelessWidget {
  const _Parallax({required this.tilt, required this.depth, required this.child});
  final Vec2 tilt;
  final double depth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = parallaxFor(tilt, depth);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(p.dx, p.dy)
        ..scale(scaleFor(depth)),
      transformAlignment: Alignment.center,
      child: child,
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({required this.layer});
  final DepthLayer layer;

  @override
  Widget build(BuildContext context) {
    final elevation = shadowFor(layer.depth);
    final card = Container(
      width: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: layer.glass ? Colors.white.withOpacity(0.08) : const Color(0xFF161A28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: layer.glass ? Colors.white.withOpacity(0.25) : const Color(0x22FFFFFF)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: elevation, offset: Offset(0, elevation * 0.4))],
      ),
      child: Row(
        children: [
          Icon(layer.glass ? Icons.add_circle_outline : Icons.article_outlined, color: layer.glass ? const Color(0xFF34D9C8) : const Color(0xFF9A8CFF)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(layer.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              Text(layer.subtitle, style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );

    if (layer.glass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: card),
      );
    }
    return card;
  }
}

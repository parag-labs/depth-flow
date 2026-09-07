/// The depth scene model and the parallax math — the deterministic core of DepthFlow. Content
/// lives on discrete depth planes (0 = far background, 1 = near foreground). A pointer/tilt
/// offset drives a parallax translation per layer, and depth also determines blur, scale, and
/// shadow. All of this is pure Dart (no Flutter imports beyond the tiny `Offset` value type we
/// define here), so the spatial behaviour is unit-testable and reproducible.
library;

import 'dart:math' as math;

/// A minimal 2D offset so the core needs no Flutter dependency.
class Vec2 {
  const Vec2(this.dx, this.dy);
  final double dx;
  final double dy;

  Vec2 operator *(double s) => Vec2(dx * s, dy * s);
  Vec2 operator +(Vec2 o) => Vec2(dx + o.dx, dy + o.dy);

  @override
  bool operator ==(Object other) => other is Vec2 && other.dx == dx && other.dy == dy;
  @override
  int get hashCode => Object.hash(dx, dy);
  @override
  String toString() => 'Vec2($dx, $dy)';
}

/// One depth plane with content. `depth` in [0, 1]; larger = nearer the viewer.
class DepthLayer {
  const DepthLayer({required this.id, required this.depth, required this.title, required this.subtitle, this.glass = false});

  final String id;
  final double depth;
  final String title;
  final String subtitle;

  /// Whether this layer is a soft-glass surface (used surgically for overlays).
  final bool glass;
}

/// The maximum parallax shift, in logical pixels, for the nearest layer at full tilt.
const double kMaxParallax = 46;

/// The parallax translation for a layer given a normalized tilt in [-1, 1] on each axis.
///
/// Near layers (depth → 1) move the most; far layers (depth → 0) barely move. The relationship
/// is intentionally slightly non-linear (depth²-ish) so the foreground "pops". The result is
/// deterministic: the same tilt and depth always produce the same offset.
Vec2 parallaxFor(Vec2 tilt, double depth) {
  final d = depth.clamp(0.0, 1.0);
  final factor = (0.25 + 0.75 * d * d); // far layers still drift a little
  return Vec2(_clampUnit(tilt.dx) * -kMaxParallax * factor, _clampUnit(tilt.dy) * -kMaxParallax * factor);
}

/// Background blur (sigma) for a layer: farther layers are blurred more, foreground stays crisp.
double blurFor(double depth) {
  final d = depth.clamp(0.0, 1.0);
  return (1 - d) * 6.0;
}

/// Scale for a layer: nearer layers are slightly larger, reinforcing depth.
double scaleFor(double depth) {
  final d = depth.clamp(0.0, 1.0);
  return 0.92 + d * 0.16; // 0.92 (far) .. 1.08 (near)
}

/// Shadow elevation for a layer: nearer layers cast a bigger, softer shadow.
double shadowFor(double depth) {
  final d = depth.clamp(0.0, 1.0);
  return 4 + d * 26;
}

/// A helper to sort layers back-to-front for painting.
List<DepthLayer> paintOrder(Iterable<DepthLayer> layers) {
  final list = layers.toList()..sort((a, b) => a.depth.compareTo(b.depth));
  return list;
}

double _clampUnit(double v) => v.clamp(-1.0, 1.0).toDouble();

/// Convert a pointer position within a box into a normalized tilt in [-1, 1], where the centre
/// is (0, 0). Used by the UI to turn mouse/touch movement into parallax.
Vec2 tiltFromPointer(double x, double y, double width, double height) {
  if (width <= 0 || height <= 0) return const Vec2(0, 0);
  final nx = (x / width) * 2 - 1;
  final ny = (y / height) * 2 - 1;
  return Vec2(_clampUnit(nx), _clampUnit(ny));
}

/// The demo scene: a stack of layers from a far ambient background to a near glass card.
List<DepthLayer> demoScene() => const [
      DepthLayer(id: 'bg', depth: 0.0, title: 'Ambient', subtitle: 'Far background'),
      DepthLayer(id: 'stats', depth: 0.25, title: 'This week', subtitle: '4 notes · 2 tasks'),
      DepthLayer(id: 'note1', depth: 0.5, title: 'Design review', subtitle: 'Tomorrow, 10:00'),
      DepthLayer(id: 'note2', depth: 0.7, title: 'Reading list', subtitle: '3 articles saved'),
      DepthLayer(id: 'glass', depth: 0.95, title: 'Quick capture', subtitle: 'Tap to add', glass: true),
    ];

/// Round for stable comparisons in tests.
double round3(double v) => (v * 1000).roundToDouble() / 1000;

/// Euclidean magnitude — handy for asserting "near layers move more than far layers".
double magnitude(Vec2 v) => math.sqrt(v.dx * v.dx + v.dy * v.dy);

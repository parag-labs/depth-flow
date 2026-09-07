import 'package:flutter_test/flutter_test.dart';
import 'package:depth_flow/core/depth.dart';

void main() {
  group('parallaxFor', () {
    test('near layers move more than far layers at the same tilt', () {
      const tilt = Vec2(1, 0);
      expect(magnitude(parallaxFor(tilt, 0.95)), greaterThan(magnitude(parallaxFor(tilt, 0.1))));
    });

    test('zero tilt yields zero parallax', () {
      expect(parallaxFor(const Vec2(0, 0), 0.9), const Vec2(0, 0));
    });

    test('parallax opposes the tilt direction (content shifts against motion)', () {
      final p = parallaxFor(const Vec2(1, 1), 1.0);
      expect(p.dx, lessThan(0));
      expect(p.dy, lessThan(0));
    });

    test('is bounded by the max parallax constant', () {
      final p = parallaxFor(const Vec2(1, 0), 1.0);
      expect(p.dx.abs(), lessThanOrEqualTo(kMaxParallax));
    });

    test('clamps out-of-range tilt', () {
      final a = parallaxFor(const Vec2(5, 0), 1.0);
      final b = parallaxFor(const Vec2(1, 0), 1.0);
      expect(round3(a.dx), round3(b.dx));
    });

    test('is deterministic', () {
      expect(parallaxFor(const Vec2(0.5, -0.3), 0.6), parallaxFor(const Vec2(0.5, -0.3), 0.6));
    });
  });

  group('depth-driven visuals', () {
    test('far layers blur more; near layers stay crisp', () {
      expect(blurFor(0.0), greaterThan(blurFor(1.0)));
      expect(blurFor(1.0), 0);
    });

    test('near layers are scaled up; far layers down', () {
      expect(scaleFor(1.0), greaterThan(1.0));
      expect(scaleFor(0.0), lessThan(1.0));
    });

    test('near layers cast a larger shadow', () {
      expect(shadowFor(1.0), greaterThan(shadowFor(0.0)));
    });
  });

  group('scene', () {
    test('paintOrder sorts back-to-front', () {
      final ordered = paintOrder(demoScene());
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i].depth, greaterThanOrEqualTo(ordered[i - 1].depth));
      }
    });

    test('tiltFromPointer maps centre to zero and corners to +/-1', () {
      expect(tiltFromPointer(50, 50, 100, 100), const Vec2(0, 0));
      expect(tiltFromPointer(100, 100, 100, 100), const Vec2(1, 1));
      expect(tiltFromPointer(0, 0, 100, 100), const Vec2(-1, -1));
    });

    test('tiltFromPointer is safe for a zero-sized box', () {
      expect(tiltFromPointer(10, 10, 0, 0), const Vec2(0, 0));
    });
  });
}

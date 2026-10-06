import 'dart:math' as math;

/// Result of grading one screen on the device.
class Grade {
  const Grade({required this.correct, this.errorCode});

  final bool correct;
  final String? errorCode;

  static const correctAnswer = Grade(correct: true);
}

/// One labeled choice or match side.
class ChoiceOption {
  const ChoiceOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// A point on the practice plane.
class PlanePoint {
  const PlanePoint({required this.x, required this.y});

  final double x;
  final double y;
}

/// A matched pair of ids.
class MatchPair {
  const MatchPair({required this.leftId, required this.rightId});

  final String leftId;
  final String rightId;
}

/// Interaction payload stored on a screen.
sealed class Primitive {
  const Primitive();

  String get type;
}

/// An arrow drawn behind a choice, not graded.
class SceneArrow {
  const SceneArrow({
    required this.start,
    required this.tip,
    this.guide = false,
  });

  final PlanePoint start;
  final PlanePoint tip;
  final bool guide;
}

/// Pick one option id.
final class ChoicePrimitive extends Primitive {
  const ChoicePrimitive({
    required this.options,
    required this.correctOptionId,
    this.arrows = const [],
    this.score,
  });

  final List<ChoiceOption> options;
  final String correctOptionId;
  final List<SceneArrow> arrows;
  final String? score;

  @override
  String get type => 'choice';
}

/// Drag a number onto a target.
final class SliderPrimitive extends Primitive {
  const SliderPrimitive({
    required this.min,
    required this.max,
    required this.step,
    required this.correctValue,
    required this.tolerance,
  });

  final double min;
  final double max;
  final double step;
  final double correctValue;
  final double tolerance;

  @override
  String get type => 'slider';
}

/// Drag an arrow tip on a plane.
final class DragArrowPrimitive extends Primitive {
  const DragArrowPrimitive({
    required this.planeWidth,
    required this.planeHeight,
    required this.start,
    required this.targetTip,
    required this.tolerance,
    this.guideStart,
    this.guideTip,
    this.score,
    this.showTarget = true,
  });

  final double planeWidth;
  final double planeHeight;
  final PlanePoint start;
  final PlanePoint targetTip;
  final double tolerance;
  final PlanePoint? guideStart;
  final PlanePoint? guideTip;
  final String? score;
  final bool showTarget;

  @override
  String get type => 'dragArrow';
}

/// Edit the four cells of a 2 by 2 matrix.
final class MatrixWarpPrimitive extends Primitive {
  const MatrixWarpPrimitive({
    required this.target,
    required this.initial,
    required this.tolerance,
    this.showTarget = false,
  });

  final List<double> target;
  final List<double> initial;
  final double tolerance;
  final bool showTarget;

  @override
  String get type => 'matrixWarp';
}

/// Pair every left item with a right item.
final class MatchPrimitive extends Primitive {
  const MatchPrimitive({
    required this.left,
    required this.right,
    required this.pairs,
  });

  final List<ChoiceOption> left;
  final List<ChoiceOption> right;
  final List<MatchPair> pairs;

  @override
  String get type => 'match';
}

/// One screen inside a lesson.
class Screen {
  const Screen({
    required this.id,
    required this.prompt,
    required this.primitive,
    required this.feedback,
    required this.easyWithinMs,
    required this.correctMessage,
  });

  final String id;
  final String prompt;
  final Primitive primitive;
  final Map<String, String> feedback;
  final int easyWithinMs;
  final String correctMessage;
}

/// A lesson the player can run without the network.
class Lesson {
  const Lesson({
    required this.id,
    required this.skillNodeId,
    required this.title,
    required this.version,
    required this.screens,
    required this.capstone,
    required this.whyItMatters,
  });

  final String id;
  final String skillNodeId;
  final String title;
  final int version;
  final List<Screen> screens;
  final bool capstone;
  final String whyItMatters;
}

/// Fact recorded for one screen, ready for the server.
class ScreenFact {
  const ScreenFact({
    required this.screenId,
    required this.correct,
    required this.latencyMs,
    required this.errorCode,
    required this.hadMiss,
    required this.clientResultId,
  });

  final String screenId;
  final bool correct;
  final int latencyMs;
  final String? errorCode;
  final bool hadMiss;
  final String clientResultId;
}

/// Everything the player emits when the last screen is done.
class LessonResult {
  const LessonResult(this.facts);

  final List<ScreenFact> facts;
}

double _angleDegrees(double ax, double ay, double bx, double by) {
  final aLen = math.sqrt(ax * ax + ay * ay);
  final bLen = math.sqrt(bx * bx + by * by);
  if (aLen == 0 || bLen == 0) return 180;
  final cos = ((ax * bx + ay * by) / (aLen * bLen)).clamp(-1.0, 1.0);
  return math.acos(cos) * 180 / math.pi;
}

/// Grades one primitive. Widgets do not contain these formulas.
abstract class Grader {
  const Grader();

  Grade grade(Primitive payload, Object? answer);
}

/// Exact option id.
class ChoiceGrader extends Grader {
  const ChoiceGrader();

  @override
  Grade grade(Primitive payload, Object? answer) {
    final choice = payload as ChoicePrimitive;
    if (answer == choice.correctOptionId) return Grade.correctAnswer;
    return const Grade(correct: false, errorCode: 'wrong_option');
  }
}

/// Too low, too high, or inside tolerance.
class SliderGrader extends Grader {
  const SliderGrader();

  @override
  Grade grade(Primitive payload, Object? answer) {
    final slider = payload as SliderPrimitive;
    final value = answer is num ? answer.toDouble() : null;
    if (value == null || value < slider.correctValue - slider.tolerance) {
      return const Grade(correct: false, errorCode: 'too_low');
    }
    if (value > slider.correctValue + slider.tolerance) {
      return const Grade(correct: false, errorCode: 'too_high');
    }
    return Grade.correctAnswer;
  }
}

/// Direction first, then tip distance.
class DragArrowGrader extends Grader {
  const DragArrowGrader();

  @override
  Grade grade(Primitive payload, Object? answer) {
    final arrow = payload as DragArrowPrimitive;
    final tip = _point(answer);
    if (tip == null) {
      return const Grade(correct: false, errorCode: 'wrong_length');
    }
    final dx = tip.x - arrow.start.x;
    final dy = tip.y - arrow.start.y;
    if (dx == 0 && dy == 0) {
      return const Grade(correct: false, errorCode: 'wrong_length');
    }
    final tx = arrow.targetTip.x - arrow.start.x;
    final ty = arrow.targetTip.y - arrow.start.y;
    if (_angleDegrees(tx, ty, dx, dy) > 25) {
      return const Grade(correct: false, errorCode: 'wrong_direction');
    }
    final distance = math.sqrt(
      math.pow(tip.x - arrow.targetTip.x, 2) +
          math.pow(tip.y - arrow.targetTip.y, 2),
    );
    if (distance > arrow.tolerance) {
      return const Grade(correct: false, errorCode: 'wrong_length');
    }
    return Grade.correctAnswer;
  }

  PlanePoint? _point(Object? answer) {
    if (answer is! Map) return null;
    final x = answer['x'];
    final y = answer['y'];
    if (x is! num || y is! num) return null;
    return PlanePoint(x: x.toDouble(), y: y.toDouble());
  }
}

/// Every cell must sit inside tolerance.
class MatrixWarpGrader extends Grader {
  const MatrixWarpGrader();

  @override
  Grade grade(Primitive payload, Object? answer) {
    final matrix = payload as MatrixWarpPrimitive;
    if (answer is! List || answer.length != matrix.target.length) {
      return const Grade(correct: false, errorCode: 'wrong_cell');
    }
    for (var index = 0; index < matrix.target.length; index++) {
      final value = answer[index];
      if (value is! num) {
        return const Grade(correct: false, errorCode: 'wrong_cell');
      }
      if ((value.toDouble() - matrix.target[index]).abs() > matrix.tolerance) {
        return const Grade(correct: false, errorCode: 'wrong_cell');
      }
    }
    return Grade.correctAnswer;
  }
}

/// All required pairs, and no swapped pair.
class MatchGrader extends Grader {
  const MatchGrader();

  @override
  Grade grade(Primitive payload, Object? answer) {
    final match = payload as MatchPrimitive;
    final pairs = _pairs(answer);
    if (pairs.length < match.pairs.length) {
      return const Grade(correct: false, errorCode: 'incomplete');
    }
    final keys = match.pairs
        .map((pair) => '${pair.leftId}:${pair.rightId}')
        .toSet();
    final wrong = pairs.any(
      (pair) => !keys.contains('${pair.leftId}:${pair.rightId}'),
    );
    if (wrong) return const Grade(correct: false, errorCode: 'wrong_pair');
    return Grade.correctAnswer;
  }

  List<MatchPair> _pairs(Object? answer) {
    final raw = answer is Map ? answer['pairs'] : answer;
    if (raw is! List) return const [];
    final pairs = <MatchPair>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final leftId = item['leftId'];
      final rightId = item['rightId'];
      if (leftId is String && rightId is String) {
        pairs.add(MatchPair(leftId: leftId, rightId: rightId));
      }
    }
    return pairs;
  }
}

/// Maps a primitive type string to its grader.
class PrimitiveRegistry {
  const PrimitiveRegistry();

  static const graders = <String, Grader>{
    'choice': ChoiceGrader(),
    'slider': SliderGrader(),
    'dragArrow': DragArrowGrader(),
    'matrixWarp': MatrixWarpGrader(),
    'match': MatchGrader(),
  };

  Grade grade(Primitive primitive, Object? answer) {
    final grader = graders[primitive.type];
    if (grader == null) {
      return const Grade(correct: false, errorCode: 'wrong_option');
    }
    return grader.grade(primitive, answer);
  }
}

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:fpdart/fpdart.dart';

/// A lesson document could not be parsed.
final class ParseException implements Exception {
  /// [message] is shown to the learner as a validation failure.
  ParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses a lesson document into domain objects.
Either<Failure, Lesson> parseLesson(Map<String, dynamic> json) {
  try {
    final screens = json['screens'];
    if (screens is! List || screens.isEmpty) {
      return left(const ValidationFailure('This lesson has no screens.'));
    }
    return right(
      Lesson(
        id: _string(json['id']),
        skillNodeId: _string(json['skillNodeId']),
        title: _string(json['title']),
        version: _int(json['version']),
        screens: screens.map(_screen).toList(),
        capstone: json['capstone'] == true,
        whyItMatters: _string(json['whyItMatters']),
      ),
    );
  } on ParseException catch (error) {
    return left(ValidationFailure(error.message));
  }
}

/// Parses one interaction payload.
Primitive parsePrimitive(Map<String, dynamic> json) => _primitive(json);
Either<Failure, Screen> parseScreen(Map<String, dynamic> json) {
  try {
    return right(_screen(json));
  } on ParseException catch (error) {
    return left(ValidationFailure(error.message));
  }
}

Screen _screen(Object? raw) {
  if (raw is! Map) {
    throw ParseException('A screen is missing.');
  }
  final json = Map<String, dynamic>.from(raw);
  final feedback = json['feedback'];
  if (feedback is! Map) {
    throw ParseException('Screen feedback is missing.');
  }
  return Screen(
    id: _string(json['id']),
    prompt: _string(json['prompt']),
    primitive: _primitive(json['primitive']),
    feedback: feedback.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    ),
    easyWithinMs: _int(json['easyWithinMs']),
    correctMessage: _string(json['correctMessage']),
  );
}

Primitive _primitive(Object? raw) {
  if (raw is! Map) {
    throw ParseException('This screen has no interaction.');
  }
  final json = Map<String, dynamic>.from(raw);
  final type = json['type'];
  switch (type) {
    case 'choice':
      return ChoicePrimitive(
        options: _options(json['options']),
        correctOptionId: _string(json['correctOptionId']),
      );
    case 'slider':
      return SliderPrimitive(
        min: _double(json['min']),
        max: _double(json['max']),
        step: _double(json['step']),
        correctValue: _double(json['correctValue']),
        tolerance: _double(json['tolerance']),
      );
    case 'dragArrow':
      return DragArrowPrimitive(
        planeWidth: _double(json['planeWidth']),
        planeHeight: _double(json['planeHeight']),
        start: _point(json['start']),
        targetTip: _point(json['targetTip']),
        tolerance: _double(json['tolerance']),
        guideStart: json['guideStart'] == null
            ? null
            : _point(json['guideStart']),
        guideTip: json['guideTip'] == null ? null : _point(json['guideTip']),
      );
    case 'matrixWarp':
      return MatrixWarpPrimitive(
        target: _doubles(json['target']),
        initial: _doubles(json['initial']),
        tolerance: _double(json['tolerance']),
        showTarget: json['showTarget'] == true,
      );
    case 'match':
      return MatchPrimitive(
        left: _options(json['left']),
        right: _options(json['right']),
        pairs: _pairs(json['pairs']),
      );
    default:
      throw ParseException('Unknown interaction: $type');
  }
}

List<ChoiceOption> _options(Object? raw) {
  if (raw is! List) {
    throw ParseException('Options are missing.');
  }
  return raw.map((item) {
    if (item is! Map) {
      throw ParseException('An option is missing.');
    }
    return ChoiceOption(
      id: _string(item['id']),
      label: _string(item['label']),
    );
  }).toList();
}

List<MatchPair> _pairs(Object? raw) {
  if (raw is! List) throw ParseException('Pairs are missing.');
  return raw.map((item) {
    if (item is! Map) throw ParseException('A pair is missing.');
    return MatchPair(
      leftId: _string(item['leftId']),
      rightId: _string(item['rightId']),
    );
  }).toList();
}

PlanePoint _point(Object? raw) {
  if (raw is! Map) throw ParseException('A point is missing.');
  return PlanePoint(x: _double(raw['x']), y: _double(raw['y']));
}

List<double> _doubles(Object? raw) {
  if (raw is! List) throw ParseException('Matrix cells are missing.');
  return raw.map(_double).toList();
}

String _string(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  throw ParseException('A lesson field is missing.');
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw ParseException('A lesson number is missing.');
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  throw ParseException('A lesson number is missing.');
}

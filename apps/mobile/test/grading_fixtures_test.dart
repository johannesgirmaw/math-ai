import 'dart:convert';
import 'dart:io';

import 'package:axiom/features/lesson_player/data/lesson_parser.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final file = File('../../packages/algorithm-vectors/fixtures/grading.json');
  final cases = (jsonDecode(file.readAsStringSync()) as Map)['cases'] as List;

  for (final raw in cases) {
    final fixture = Map<String, dynamic>.from(raw as Map);
    test(fixture['id'] as String, () {
      final primitive = parsePrimitive(
        Map<String, dynamic>.from(fixture['primitive'] as Map),
      );
      final expectGrade = Map<String, dynamic>.from(fixture['expect'] as Map);
      final grade = const PrimitiveRegistry().grade(
        primitive,
        fixture['answer'],
      );
      expect(grade.correct, expectGrade['correct']);
      expect(grade.errorCode, expectGrade['errorCode']);
    });
  }
}

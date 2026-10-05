import 'package:axiom/features/auth/data/auth_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('me json becomes a learner', () {
    final learner = AuthDto.fromMe({
      'id': 'user-1',
      'email': 'ada@axiom.app',
      'displayName': 'Ada',
      'dailyGoalMinutes': 10,
      'role': 'learner',
    });

    expect(learner.id, 'user-1');
    expect(learner.email, 'ada@axiom.app');
    expect(learner.displayName, 'Ada');
    expect(learner.dailyGoalMinutes, 10);
    expect(learner.role, 'learner');
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_hung_cuong_kt/core/liveness.dart';

const _calm = FaceSample(smile: 0.05, roll: 1, pitch: 0);

FaceSample _for(LivenessChallenge c) => switch (c) {
      LivenessChallenge.smile => const FaceSample(smile: 0.95),
      LivenessChallenge.tilt => const FaceSample(smile: 0.05, roll: 25),
      LivenessChallenge.lookUp => const FaceSample(smile: 0.05, pitch: 22),
    };

void _feed(LivenessTracker t, FaceSample s, int n) {
  for (var i = 0; i < n; i++) {
    t.update(faces: 1, sample: s);
  }
}

void main() {
  test('chọn đúng 2 thử thách khác nhau', () {
    for (var seed = 0; seed < 30; seed++) {
      final t = LivenessTracker(random: Random(seed));
      expect(t.challenges.length, 2);
      expect(t.challenges.toSet().length, 2);
    }
  });

  test('làm đúng hai động tác theo thứ tự thì vượt qua', () {
    final t = LivenessTracker(random: Random(1));
    _feed(t, _calm, 4);
    expect(t.phase, LivenessPhase.challenge);
    for (final c in t.challenges.toList()) {
      _feed(t, _for(c), 3);
    }
    expect(t.isDone, isTrue);
    expect(t.progress, 1);
  });

  test('ảnh tĩnh (mặt tự nhiên mãi) không bao giờ qua được', () {
    final t = LivenessTracker();
    _feed(t, _calm, 500);
    expect(t.isDone, isFalse);
    expect(t.phase, LivenessPhase.challenge);
  });

  test('động tác chỉ thoáng qua một khung hình thì không tính', () {
    final t = LivenessTracker(random: Random(2));
    _feed(t, _calm, 4);
    final first = t.challenges.first;
    _feed(t, _for(first), 2); // chưa đủ 3 khung
    _feed(t, _calm, 1); // bị ngắt
    _feed(t, _for(first), 2);
    expect(t.completed, 0);
    _feed(t, _for(first), 1);
    expect(t.completed, 1);
  });

  test('làm sai động tác yêu cầu thì không tiến', () {
    final t = LivenessTracker(random: Random(3));
    _feed(t, _calm, 4);
    final wrong = LivenessChallenge.values.firstWhere((c) => c != t.challenges.first);
    _feed(t, _for(wrong), 20);
    expect(t.completed, 0);
  });

  test('thấy 2 khuôn mặt thì làm lại từ đầu', () {
    final t = LivenessTracker(random: Random(4));
    _feed(t, _calm, 4);
    t.update(faces: 2);
    expect(t.phase, LivenessPhase.neutral);
    expect(t.completed, 0);
  });

  test('không thấy khuôn mặt thì không tiến và có lời nhắc', () {
    final t = LivenessTracker();
    t.update(faces: 0);
    expect(t.phase, LivenessPhase.neutral);
    expect(t.message, contains('khuôn mặt'));
  });

  test('chưa nhìn thẳng thì chưa tính mốc ban đầu', () {
    final t = LivenessTracker();
    _feed(t, const FaceSample(smile: 0.9), 50);
    expect(t.phase, LivenessPhase.neutral);
  });
}

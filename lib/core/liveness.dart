import 'dart:math';

/// Một thử thách "người thật" yêu cầu khuôn mặt làm động tác.
enum LivenessChallenge {
  smile('Hãy mỉm cười'),
  tilt('Hãy nghiêng đầu sang một bên'),
  lookUp('Hãy ngẩng đầu lên');

  const LivenessChallenge(this.instruction);
  final String instruction;
}

/// Số đo từ một khung hình có đúng một khuôn mặt (lấy từ ML Kit).
class FaceSample {
  const FaceSample({this.smile, this.roll = 0, this.pitch = 0});

  /// Xác suất đang cười 0..1 (null nếu máy không phân loại được).
  final double? smile;

  /// Nghiêng đầu (độ), dương/âm tuỳ chiều.
  final double roll;

  /// Ngẩng/cúi đầu (độ), dương là ngẩng.
  final double pitch;
}

enum LivenessPhase { neutral, challenge, done }

/// Máy trạng thái cho bước xác thực người thật khi chấm công:
/// 1) nhìn thẳng, mặt tự nhiên vài khung hình để lấy mốc;
/// 2) làm lần lượt hai động tác ngẫu nhiên (mỗi động tác phải giữ vài khung hình liên tiếp).
/// Một tấm ảnh chụp sẵn không cười/nghiêng/ngẩng theo yêu cầu được nên không qua được.
/// Không phụ thuộc Flutter để kiểm thử dễ dàng.
class LivenessTracker {
  LivenessTracker({Random? random, this.neutralFrames = 4, this.holdFrames = 3, this.challengeCount = 2})
      : _random = random ?? Random.secure() {
    reset();
  }

  final Random _random;
  final int neutralFrames;
  final int holdFrames;
  final int challengeCount;

  late List<LivenessChallenge> challenges;
  LivenessPhase phase = LivenessPhase.neutral;
  int _index = 0;
  int _streak = 0;

  /// Lời nhắc cho người dùng ở trạng thái hiện tại.
  String message = '';

  bool get isDone => phase == LivenessPhase.done;

  int get completed => _index;

  LivenessChallenge? get current => phase == LivenessPhase.challenge ? challenges[_index] : null;

  /// 0..1 để vẽ vòng tiến trình.
  double get progress {
    if (isDone) return 1;
    final base = _index / challengeCount;
    final inStep = phase == LivenessPhase.neutral ? 0.0 : (_streak / holdFrames).clamp(0.0, 1.0) / challengeCount;
    return (base + inStep).clamp(0.0, 1.0);
  }

  void reset() {
    final pool = List<LivenessChallenge>.of(LivenessChallenge.values)..shuffle(_random);
    challenges = pool.take(challengeCount).toList();
    phase = LivenessPhase.neutral;
    _index = 0;
    _streak = 0;
    message = 'Nhìn thẳng vào camera';
  }

  /// Gọi với mỗi khung hình. [faces] là số khuôn mặt thấy được, [sample] là số đo khi `faces == 1`.
  void update({required int faces, FaceSample? sample}) {
    if (isDone) return;
    if (faces == 0 || sample == null && faces == 1) {
      _streak = 0;
      message = 'Không thấy khuôn mặt, hãy đưa mặt vào khung tròn';
      return;
    }
    if (faces > 1) {
      // Có người thứ hai (hoặc ảnh) trong khung: làm lại từ đầu.
      reset();
      message = 'Chỉ một khuôn mặt trong khung hình';
      return;
    }
    final s = sample!;

    if (phase == LivenessPhase.neutral) {
      final calm = (s.smile ?? 0) < 0.35 && s.roll.abs() < 10 && s.pitch.abs() < 15;
      if (calm) {
        _streak++;
        message = 'Nhìn thẳng vào camera';
        if (_streak >= neutralFrames) {
          phase = LivenessPhase.challenge;
          _streak = 0;
          message = challenges[0].instruction;
        }
      } else {
        _streak = 0;
        message = 'Giữ mặt thẳng, tự nhiên trong giây lát';
      }
      return;
    }

    final challenge = challenges[_index];
    if (_met(challenge, s)) {
      _streak++;
      if (_streak >= holdFrames) {
        _index++;
        _streak = 0;
        if (_index >= challengeCount) {
          phase = LivenessPhase.done;
          message = 'Xác thực thành công';
        } else {
          message = challenges[_index].instruction;
        }
      }
    } else {
      _streak = 0;
      message = challenge.instruction;
    }
  }

  static bool _met(LivenessChallenge c, FaceSample s) => switch (c) {
        LivenessChallenge.smile => (s.smile ?? 0) > 0.8,
        LivenessChallenge.tilt => s.roll.abs() > 18,
        LivenessChallenge.lookUp => s.pitch > 14,
      };
}

/// Optional base class for all cue events.
///
/// You can freely extend this for all cue data classes for better
/// timestamp tracking and dev tooling.
abstract class Cue {
  final DateTime timestamp;

  Cue() : timestamp = DateTime.now();
}

import 'package:joker_state/joker_state.dart';

// Defines a cue (event) for when the counter is incremented.
class CounterIncrementedCue extends Cue {
  final int newValue;
  CounterIncrementedCue(this.newValue);
}

// Defines a cue for when a milestone is reached.
class CounterMilestoneReachedCue extends Cue {
  final int milestoneValue;
  CounterMilestoneReachedCue(this.milestoneValue);
}

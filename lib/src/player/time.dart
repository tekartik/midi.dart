import 'package:tekartik_midi/midi.dart';

/// Convert a midi delta time to milliseconds according to various parameters,
/// either frameCountPerSecond and divisionCountPerFrame are needed.
/// otherwiser ppq is used defaulting to 120 ppq.
num midiDeltaTimeToMillis(
  num deltaTime, {
  int? ppq,
  int? bpm,
  int? frameCountPerSecond,
  int? divisionCountPerFrame,
}) {
  return deltaTime *
      midiDeltaTimeUnitToMillis(
        ppq: ppq,
        bpm: bpm,
        frameCountPerSecond: frameCountPerSecond,
        divisionCountPerFrame: divisionCountPerFrame,
      );
}

/// Convert a midi delta time to milliseconds according to various parameters,
/// either frameCountPerSecond and divisionCountPerFrame are needed.
/// otherwiser ppq is used defaulting to 120 ppq.
num midiDeltaTimeUnitToMillis({
  int? ppq,
  int? bpm,
  int? frameCountPerSecond,
  int? divisionCountPerFrame,
}) {
  bpm ??= MidiFile.bpmDefault;
  var beatPerMillis = bpm / TempoEvent.millisecondsPerMinute;

  num ppqResult(int ppq) {
    return 1 / (ppq * beatPerMillis);
  }

  // check midi docs here
  if (ppq != null) {
    return ppqResult(ppq);
  } else if (frameCountPerSecond != null || divisionCountPerFrame != null) {
    return 1 / (frameCountPerSecond! * divisionCountPerFrame! * beatPerMillis);
  } else {
    return ppqResult(MidiFile.ppqDefault);
  }
}

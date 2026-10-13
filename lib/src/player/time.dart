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
  return midiMillisPerTick(
    ppq: ppq,
    beatPerMillis: bpm / TempoEvent.millisecondsPerMinute,
    frameCountPerSecond: frameCountPerSecond,
    divisionCountPerFrame: divisionCountPerFrame,
  );
}

/// Milliseconds per tick (the delta time unit), not exported.
///
/// With a SMPTE time division (frames per second and divisions per frame) a
/// tick has a fixed length, whatever the tempo. With [ppq] (defaulting to
/// 120 when no SMPTE division is given) it depends on the tempo,
/// [beatPerMillis] (0.002 for 120 bpm, the default).
num midiMillisPerTick({
  int? ppq,
  num? beatPerMillis,
  num? frameCountPerSecond,
  int? divisionCountPerFrame,
}) {
  if (ppq == null &&
      (frameCountPerSecond != null || divisionCountPerFrame != null)) {
    return 1000 / (frameCountPerSecond! * divisionCountPerFrame!);
  }
  beatPerMillis ??= MidiFile.bpmDefault / TempoEvent.millisecondsPerMinute;
  return 1 / ((ppq ?? MidiFile.ppqDefault) * beatPerMillis);
}

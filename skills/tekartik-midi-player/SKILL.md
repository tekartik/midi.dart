---
name: tekartik-midi-player
description: >-
  Use when sequencing or timing midi events in Dart with tekartik_midi: turning
  a MidiFile into timed PlayableEvent objects with MidiFilePlayer, computing a
  file duration with getMidiFileDuration, converting ticks to milliseconds with
  midiDeltaTimeToMillis / midiDeltaTimeUnitToMillis, and implementing a real
  player by extending MidiPlayerBase (rawPlayEvent, now, load, resume, pause,
  panic, allNotesOff, setSpeedRadio, NoteOnKey, LocatedEvent).
---

# Midi playback and timing (tekartik_midi)

`tekartik_midi` has no sound output of its own: it flattens a `MidiFile` into
events located in milliseconds and calls you back when each one is due, so you
only implement "send this event to my synth". Building and parsing files is
covered by the sibling skill [tekartik-midi-files](../tekartik-midi-files/SKILL.md).

## Guidelines

* Dependency (git only, not on pub.dev); the README asks for the `dart3a` ref:
  ```yaml
  dependencies:
    tekartik_midi:
      git:
        url: https://github.com/tekartik/midi.dart
        ref: dart3a
  ```
* Imports: `package:tekartik_midi/midi_file_player.dart` for `MidiFilePlayer`,
  `PlayableEvent`, `LocatedEvent`, `LocatedTrackPlayer`, `NoteOnKey`,
  `getMidiFileDuration`, `midiDeltaTimeToMillis` and
  `midiDeltaTimeUnitToMillis`; `package:tekartik_midi/midi_player_base.dart`
  for the `MidiPlayerBase` base class; `package:tekartik_midi/midi.dart` for
  the events themselves. Everything here is platform neutral.
* Timestamps are `num` **milliseconds in your own clock**, not `Duration`. Pick
  one time source (a `Stopwatch` on the VM, `window.performance.now()` on the
  web, the audio context time in a synth) and be consistent.
* `getMidiFileDuration(file)` returns the total `Duration` of a file; it builds
  a throwaway `MidiFilePlayer` internally, so cache the result.
* Low level: `MidiFilePlayer(file)` merges every track, sorts the events by
  tick and converts them to absolute milliseconds, following the `TempoEvent`s
  it meets and the file `ppq` or SMPTE division.
  * `start(timestamp)` sets the origin and rewinds; `pause(timestamp)` and
    `resume(timestamp)` shift the origin; `isPlaying` is true between them.
  * `next` returns the next `PlayableEvent` (a `timestamp` in your clock and a
    `midiEvent`) or `null` at the end. It returns events as fast as you ask:
    it is your job to wait until `event.timestamp` is due, which is exactly
    what `MidiPlayerBase` does for you.
  * `totalDurationMs`, `getProgress(currentTimestamp)` (0 to 1),
    `absoluteMsToTimestamp` / `timestampToAbsoluteMs` convert between file
    position and clock, `setSpeedRatio(ratio, [currentTimestamp])` plays faster
    (2) or slower (0.5) without touching the tempo; pass the current timestamp
    so the position is preserved across the change.
  * `locatedEvents` exposes the flattened `LocatedEvent` list (`time` in ticks,
    `absoluteMs`, `midiEvent`); `LocatedTrackPlayer(track).preLocatedEvents`
    does the same for a single track. Members marked `@visibleForTesting`
    (`notesOn`, `currentNoteOnEvents`, `tempoBpm`,
    `currentDeltaTimeUnitInMillis`, `currentLocatedEventIndex`) are not API.
* High level: extend `MidiPlayerBase` and implement two members: `num get now`
  (your clock in milliseconds) and `void rawPlayEvent(PlayableEvent event)`
  (actually emit the event). The super constructor takes the initial
  `noteOnLastTimestamp`, normally `null`.
  * `load(file)` prepares a file (it pauses and unloads the previous one),
    `resume([time])` starts or resumes playback, `pause()` stops it and
    automatically emits a `NoteOffEvent` for every note left on.
  * `await player.done` waits for the end of the file (`done` is `Future?` and
    is null before the first `load`). `isPlaying`, `isPaused`, `isDone`,
    `currentTimestamp`, `currentTimestampDuration`, `totalDurationMs` and
    `currentAbsoluteMs` report the state.
  * Override `playEvent` only if you call `super.playEvent(event)`: it is what
    maintains `noteOnKeys` (a `Set<NoteOnKey>`) used by `pause()`.
  * Panic helpers send on all 16 channels: `allSoundOff()`, `allNotesOff()`,
    `allReset()` and `panic()` (a note off for every note of every channel,
    2048 events, use it only when something is stuck).
  * Speed: `setSpeedRadio(ratio)` applies now, `setNextSpeedRadio(ratio)` at
    the next load, `currentSpeedRadio` reads it back (the `Radio` spelling is
    the real API on `MidiPlayerBase`, while `MidiFilePlayer` spells it
    `setSpeedRatio`).
  * Listen to `player.playingController.stream` for play/pause transitions. The
    `playingStream` field is never assigned by the base class: do not read it.
* Without any player, `midiDeltaTimeToMillis(deltaTime, ppq: ..., bpm: ...)`
  converts ticks to milliseconds, and `midiDeltaTimeUnitToMillis(...)` gives
  the duration of one tick; both accept `frameCountPerSecond` /
  `divisionCountPerFrame` instead of `ppq` for SMPTE files and default to
  `MidiFile.ppqDefault` (120) and `MidiFile.bpmDefault` (120) bpm.
* Anti-patterns: calling `next` in a tight loop without honouring
  `event.timestamp`; mixing two different clocks in `now`; forgetting that
  `pause()` needs the note tracking done by `super.playEvent`; assuming a note
  off exists for every note on (a note on with velocity 0 is a note off).

## Examples

### Total duration of a file

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';

void printDuration(MidiFile file) {
  var duration = getMidiFileDuration(file);
  print('${duration.inSeconds}s');
}
```

### A console player: extend MidiPlayerBase

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';
import 'package:tekartik_midi/midi_player_base.dart';

class StdoutMidiPlayer extends MidiPlayerBase {
  StdoutMidiPlayer() : super(null);

  final _stopwatch = Stopwatch();

  @override
  num get now {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    return _stopwatch.elapsed.inMilliseconds;
  }

  @override
  void rawPlayEvent(PlayableEvent event) {
    // Send to a synth here; timestamp is in milliseconds.
    print('${event.timestamp} ${event.midiEvent}');
  }
}

Future<void> play(MidiFile file) async {
  var player = StdoutMidiPlayer();
  player.playingController.stream.listen((playing) => print('playing: $playing'));
  player.load(file);
  player.resume();
  await player.done;
}
```

### Drive MidiFilePlayer yourself (seek, speed, progress)

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';

/// Dump the events of the first second, at double speed.
void dumpFirstSecond(MidiFile file) {
  var player = MidiFilePlayer(file);
  player.start(0);
  player.setSpeedRatio(2);
  print('total ${player.totalDurationMs} ms');
  while (true) {
    var event = player.next;
    if (event == null || event.timestamp > 1000) {
      break;
    }
    print('${event.timestamp} ${event.midiEvent} '
        '${(player.getProgress(event.timestamp) * 100).round()}%');
  }
}
```

### Tick to millisecond conversion without a player

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';

void main() {
  // One quarter note at 240 ppq / 120 bpm is 500 ms.
  print(midiDeltaTimeToMillis(240, ppq: 240, bpm: 120));
  // Duration of a single tick.
  print(midiDeltaTimeUnitToMillis(ppq: MidiFile.ppqDefault));
  // SMPTE variant.
  print(midiDeltaTimeUnitToMillis(frameCountPerSecond: 25, divisionCountPerFrame: 40));
}
```

### Absolute positions of every event of a file

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';

void listNotes(MidiFile file) {
  for (var located in MidiFilePlayer(file).locatedEvents!) {
    var event = located.midiEvent;
    if (event is NoteOnEvent && event.velocity > 0) {
      print('${located.absoluteMs} ms (tick ${located.time}) note ${event.note}');
    }
  }
}
```

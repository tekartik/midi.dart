# tekartik_midi

Standard MIDI files (`.mid`) in pure Dart: a model (`MidiFile`, `MidiTrack`,
events), a parser, a writer, and the timing of the events for a player. It
makes no sound: a player built on it sends each event, when due, to your synth.

*API subject to change.* Not on pub.dev, used as a git dependency
([versioning](https://github.com/tekartik/common.dart/blob/main/doc/tekartik_versioning.md)).

## Getting started

```bash
dart pub add tekartik_midi --git-url=https://github.com/tekartik/midi.dart
```

or in `pubspec.yaml` (the package is at the root of the repo, no `ref`, no
`path`):

```yaml
dependencies:
  tekartik_midi:
    git:
      url: https://github.com/tekartik/midi.dart
```

Read a file and list its notes:

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';

void printNotes(List<int> bytes) {
  // Throws a FormatException when the bytes are not a valid midi file.
  var file = FileParser.dataFile(bytes)!;
  print('format ${file.fileFormat}, ${file.trackCount} tracks, ppq ${file.ppq}');
  for (var track in file.tracks) {
    var ticks = 0;
    for (var trackEvent in track.events) {
      // deltaTime: ticks since the previous event of the same track.
      ticks += trackEvent.deltaTime;
      var event = trackEvent.midiEvent;
      if (event is NoteOnEvent && event.velocity > 0) {
        print('$ticks: note ${event.note} on channel ${event.channel}');
      }
    }
  }
}
```

Create one and get its bytes:

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

List<int> twoNotes() {
  var file = MidiFile()..ppq = 240; // ticks per quarter note
  var track = MidiTrack()
    ..addEvent(0, TempoEvent.bpm(120))
    ..addEvent(0, NoteOnEvent(0, 60, 100)) // channel 0, middle C
    ..addEvent(240, NoteOffEvent(0, 60, 0)) // a quarter note later
    ..addEvent(0, NoteOnEvent(0, 64, 100))
    ..addEvent(240, NoteOffEvent(0, 64, 0))
    ..addEvent(0, EndOfTrackEvent()); // every track ends with it
  file.addTrack(track);
  return FileWriter.fileData(file);
}
```

[example/main.dart](example/main.dart) does both, plus the duration, and runs
anywhere (`dart run example/main.dart`).

### Platforms

Everything is pure Dart and runs on the VM, Flutter (mobile, desktop, web) and
the web, except `package:tekartik_midi/midi_io.dart` (`ioReadMidiFile`,
`ioWriteMidiFile`), which uses `dart:io`: not on the web. On the web or in
Flutter, read the bytes yourself (an asset, a file picker, http) and give them
to `FileParser.dataFile`.

## What to use

| Import | For |
|---|---|
| `package:tekartik_midi/midi.dart` | The model: `MidiFile`, `MidiTrack`, `TrackEvent` (delta time + event), the events (`NoteOnEvent`, `NoteOffEvent`, `ControlChangeEvent`, `ProgramChangeEvent`, `PitchWheelChangeEvent`, `SysExEvent`, `TempoEvent`, `TimeSigEvent`, `KeySigEvent`, `TrackNameEvent`, `MetaTextEvent`, `EndOfTrackEvent`, any `MetaEvent`). |
| `package:tekartik_midi/midi_parser.dart` | Bytes to model: `FileParser.dataFile(bytes)`, one event: `EventParser.dataParseMidiEvent(bytes)`. |
| `package:tekartik_midi/midi_writer.dart` | Model to bytes: `FileWriter.fileData(file)`, one event: `EventWriter.midiEventToBytes(event)`. |
| `package:tekartik_midi/midi_file_player.dart` | Time: `getMidiFileDuration(file)`, `MidiFilePlayer` (the events located in milliseconds, tempo changes and speed included), `midiDeltaTimeToMillis`. |
| `package:tekartik_midi/midi_player_base.dart` | A real time player: extend `MidiPlayerBase`, implement `now` (your clock in ms) and `rawPlayEvent` (send the event to your synth); `load`, `resume`, `pause` (sends the note offs), `done`. See [example/midi_play.dart](example/midi_play.dart). |
| `package:tekartik_midi/midi_io.dart` | `ioReadMidiFile(path)`, `ioWriteMidiFile(path, file)` (VM, Flutter native). |

## Bad files

`FileParser.dataFile` and `FileParser.parseFile` throw a `FormatException` for
anything that is not a valid file: bad header, truncated data, a length larger
than the file, a zero time division. A bad file never allocates more than its
own size, and the chunks that are not tracks (not `MTrk`) are skipped, as the
format asks. Catch the `FormatException` around the parse.

Known gap: a tempo, time or key signature event shorter than its type parses,
then its getters throw (`tempo`, `toString`), during `getMidiFileDuration` or
playback for a tempo.

## Common mistakes

* `deltaTime` is relative: the ticks since the previous event of the same
  track, not an absolute position (`track.absoluteTimeAt(index)` sums them).
* `ppq` is `null` for a SMPTE file (`frameCountPerSecond` and
  `divisionCountPerFrame` are set instead).
* `TimeSigEvent(4, 2)` is 4/4 (the bottom is a power of 2):
  `TimeSigEvent.topBottom(4, 4)` is clearer.
* A note on with velocity 0 is a note off.
* Timestamps of the players are milliseconds of your own clock (`num`), not
  `Duration`s.
* `MidiPlayerBase` spells the speed `setSpeedRadio`, `MidiFilePlayer`
  `setSpeedRatio`.

## More

* Agent skills: [tekartik-midi-files](skills/tekartik-midi-files/SKILL.md)
  (model, parse, write) and [tekartik-midi-player](skills/tekartik-midi-player/SKILL.md)
  (timing, players).
* The format: [doc/midifile.txt](doc/midifile.txt).

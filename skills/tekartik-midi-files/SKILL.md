---
name: tekartik-midi-files
description: >-
  Use when building, reading or writing standard midi (.mid) files in Dart with
  tekartik_midi: MidiFile, MidiTrack, TrackEvent, MidiEvent and its subclasses
  (NoteOnEvent, NoteOffEvent, ProgramChangeEvent, ControlChangeEvent,
  PitchWheelChangeEvent, SysExEvent, TempoEvent, TimeSigEvent, KeySigEvent,
  TrackNameEvent, MetaTextEvent, EndOfTrackEvent), the MidiParser / FileParser /
  TrackParser / EventParser parsing side, the MidiWriter / FileWriter /
  TrackWriter / EventWriter writing side, ppq and time division, and the
  ioReadMidiFile / ioWriteMidiFile dart:io helpers.
---

# Midi files and events (tekartik_midi)

`tekartik_midi` is a pure Dart (no `dart:io` except in `midi_io.dart`) model,
parser and writer for standard midi files: a `MidiFile` holds `MidiTrack`s, a
track holds `TrackEvent`s (a delta time plus a `MidiEvent`). Playback timing is
covered by the sibling skill [tekartik-midi-player](../tekartik-midi-player/SKILL.md).

## Guidelines

* Dependency (git only, not on pub.dev); the README asks for the `dart3a` ref:
  ```yaml
  dependencies:
    tekartik_midi:
      git:
        url: https://github.com/tekartik/midi.dart
        ref: dart3a
  ```
  The package is at the repo root, so no `path:` entry.
* Imports: `package:tekartik_midi/midi.dart` for the model (`MidiFile`,
  `MidiTrack`, `TrackEvent`, `MidiEvent` and every event class),
  `package:tekartik_midi/midi_parser.dart` for `MidiParser`, `FileParser`,
  `TrackParser`, `EventParser`, `package:tekartik_midi/midi_writer.dart` for
  `MidiWriter`, `FileWriter`, `TrackWriter`, `EventWriter`, and
  `package:tekartik_midi/midi_io.dart` (VM/Flutter native only) for
  `ioReadMidiFile` / `ioWriteMidiFile`. Never import `src/`;
  `midi_buffer.dart` is deprecated, do not use it.
* Build a file with `MidiFile()`, then `file.fileFormat =
  MidiFile.formatMultiTrack` (1) and `file.ppq = 240` (pulses per quarter
  note, default `MidiFile.ppqDefault` = 120). `addTrack(track)` appends a
  `MidiTrack`; `tracks` is read only (mutate it through `addTrack`), and
  adding the same track instance twice throws a `StateError` in debug mode.
* SMPTE timing instead of ppq: `file.setFrameDivision(frameCountPerSecond,
  divisionCountPerFrame)` with 24, 25, 29 (meaning 29.97) or 30 frames. `ppq`
  is then `null` and `frameCountPerSecond` / `divisionCountPerFrame` are set.
  Setting `ppq` with the top bit set throws a `FormatException`. `timeDivision`
  is the raw 16 bit header value behind both.
* Add events with `track.addEvent(deltaTime, event)` where `deltaTime` is the
  number of ticks **since the previous event of that track** (0 for
  simultaneous events), or `track.addAbsolutionEvent(absoluteTime, event)`
  which inserts at the right place and returns the index (delta times of the
  following event are not fixed up, so prefer `addEvent` when appending in
  order). `absoluteTimeAt(index)` sums the delta times up to an index.
  End every track with `EndOfTrackEvent()`.
* Channel events (channel is 0..15, `MidiEvent.channelCount` is 16, notes 0..127,
  `MidiEvent.noteCount` is 128): `NoteOnEvent(channel, note, velocity)`,
  `NoteOffEvent(channel, note, velocity)`, `KeyAfterTouchEvent(channel, note,
  velocity)`, `ProgramChangeEvent(channel, program)`,
  `ChannelAfterTouchEvent(command, channel, amount)`,
  `PitchWheelChangeEvent(channel, bottom, top)`,
  `ControlChangeEvent.withParam(channel, controller, value)` plus the helpers
  `ControlChangeEvent.newAllSoundOffEvent(channel)`, `newAllNotesOffEvent`,
  `newAllResetEvent` and the controller numbers `ControlChangeEvent.allSoundOff`
  (120), `allReset` (121), `allNotesOff` (123). A note on with velocity 0 is a
  note off.
* Meta events: `TempoEvent.bpm(120)` or `TempoEvent(microsecondsPerQuarter)`
  (read back with `tempo`, `tempoBpm`, `beatPerMillis`),
  `TimeSigEvent(top, denomPowerOfTwo)` (4/4 is `TimeSigEvent(4, 2)`) or the
  clearer `TimeSigEvent.topBottom(4, 4)` (read back with `top` / `bottom`),
  `KeySigEvent(alterations, scale)` (`alterations` signed, `scale` 0 major /
  1 minor), `TrackNameEvent(data: ...)` with the `trackName` getter,
  `MetaTextEvent.text('...')` with the `text` getter, `EndOfTrackEvent()`, and
  the generic `MetaEvent(metaCommand, data)` for anything else.
* Parse bytes with the one liner `FileParser.dataFile(bytes)` (returns
  `MidiFile?`, throws `FormatException` on a bad header), or keep the parser
  around: `var parser = FileParser(MidiParser(bytes)); parser.parseFile();` then
  `parser.file!`. `bytes` is any `List<int>` (`Uint8List` included).
  `EventParser.dataParseEvent(bytes)` / `dataParseMidiEvent(bytes)` parse a
  single event, `TrackParser(midiParser).parseTrack()` a single track chunk.
* Write bytes with `FileWriter.fileData(file)` (a `List<int>` ready to save) or
  `EventWriter.midiEventToBytes(event)` for one event (`Uint8List`). A round
  trip parse/write is stable: `MidiFile` and `MidiTrack` implement `==`.
* On the VM, `await ioReadMidiFile(path)` and `await ioWriteMidiFile(path,
  file)` wrap the above with `dart:io`. Keep them out of web code; the rest of
  the package compiles everywhere.
* `file.dump()` / `track.dump()` print the parsed structure to the console:
  debugging only, not a stable format.
* Anti-patterns: treating `deltaTime` as an absolute tick position; writing a
  track without `EndOfTrackEvent`; assuming `ppq` is non null on a parsed file
  (it is null for SMPTE files); mutating `file.tracks` or `track.events`
  directly instead of `addTrack` / `addEvent`.

## Examples

### Create a midi file and save it

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_io.dart';

MidiFile buildCde() {
  var file = MidiFile();
  file.fileFormat = MidiFile.formatMultiTrack;
  file.ppq = 240;

  // First track: tempo map
  var track = MidiTrack();
  track.addEvent(0, TrackNameEvent(data: 'tempo'.codeUnits));
  track.addEvent(0, TimeSigEvent.topBottom(4, 4));
  track.addEvent(0, TempoEvent.bpm(120));
  track.addEvent(0, EndOfTrackEvent());
  file.addTrack(track);

  // Second track: a few notes on channel 1
  track = MidiTrack();
  track.addEvent(0, ProgramChangeEvent(1, 25));
  track.addEvent(0, NoteOnEvent(1, 42, 127));
  track.addEvent(240, NoteOffEvent(1, 42, 127));
  track.addEvent(240, NoteOnEvent(1, 44, 127));
  track.addEvent(240, NoteOffEvent(1, 44, 127));
  track.addEvent(0, EndOfTrackEvent());
  file.addTrack(track);

  return file;
}

Future<void> main() async {
  await ioWriteMidiFile('out.mid', buildCde());
}
```

### Parse a file and walk its events

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_io.dart';

Future<void> main(List<String> args) async {
  var file = await ioReadMidiFile(args.first);
  print('format ${file.fileFormat}, ${file.trackCount} tracks, ppq ${file.ppq}');
  for (var track in file.tracks) {
    var absoluteTime = 0;
    for (var trackEvent in track.events) {
      absoluteTime += trackEvent.deltaTime;
      var event = trackEvent.midiEvent;
      if (event is NoteOnEvent && event.velocity > 0) {
        print('$absoluteTime note on ${event.note} ch ${event.channel}');
      } else if (event is TempoEvent) {
        print('$absoluteTime tempo ${event.tempoBpm} bpm');
      } else if (event is TrackNameEvent) {
        print('$absoluteTime track name ${event.trackName}');
      }
    }
  }
}
```

### Parse from bytes, edit, write back to bytes (no dart:io)

```dart
import 'dart:typed_data';

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

/// Add a text marker at the beginning of the first track.
Uint8List annotate(List<int> bytes, String text) {
  var file = FileParser.dataFile(bytes)!;
  file.tracks.first.addAbsolutionEvent(0, MetaTextEvent.text(text));
  return Uint8List.fromList(FileWriter.fileData(file));
}

void main() {
  // A minimal 2 track file, header + tempo track + empty track.
  var midiFile = MidiFile()
    ..fileFormat = MidiFile.formatMultiTrack
    ..ppq = 480;
  midiFile.addTrack(MidiTrack()..addEvent(0, EndOfTrackEvent()));

  var bytes = annotate(FileWriter.fileData(midiFile), 'hello');
  print(FileParser.dataFile(bytes)!.trackCount);
}
```

### Encode and decode a single event

```dart
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

void main() {
  var bytes = EventWriter.midiEventToBytes(NoteOnEvent(0, 60, 127));
  print(bytes); // [0x90, 0x3C, 0x7F]

  var event = EventParser.dataParseMidiEvent(bytes) as NoteOnEvent;
  print('${event.channel} ${event.note} ${event.velocity}');
}
```

### SMPTE time division instead of ppq

```dart
import 'package:tekartik_midi/midi.dart';

void main() {
  var file = MidiFile()..fileFormat = MidiFile.formatMultiTrack;
  // 25 frames per second, 40 divisions per frame
  file.setFrameDivision(25, 40);
  print(file.ppq); // null
  print('${file.frameCountPerSecond} ${file.divisionCountPerFrame}');
}
```

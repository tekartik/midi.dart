# tekartik_midi.dart

Library for parsing, manipulation Midi files and for sequencing midi event

[![Build Status](https://travis-ci.org/tekartik/midi.dart.svg?branch=master)](https://travis-ci.org/tekartik/midi.dart)

*API subject to change*

## Setup

`pubspec.yaml`:

```yaml
dependencies:
  tekartik_midi:
    git:
      url: https://github.com/tekartik/midi.dart
      ref: dart2
```

## Usage example

### Creating a midi file

```dart
var file = MidiFile();
file.fileFormat = MidiFile.formatMultiTrack;
file.ppq = 240;

var track = MidiTrack();
track.addEvent(0, TimeSigEvent(4, 4));
track.addEvent(0, TempoEvent.bpm(120));
track.addEvent(0, EndOfTrackEvent());
file.addTrack(track);
```

### Parsing a midi file

```dart
Uint8List data; // the file binary data

// ... fill the data from a midi file

var midiParser = MidiParser(data);
var parser = FileParser(midiParser);
parser.parseFile();

// Resulting midi file
var file = parser.file;
```
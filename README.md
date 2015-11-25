# tekartik_midi.dart

Library for parsing, manipulation Midi files and for sequencing midi event

[![Build Status](https://travis-ci.org/alextekartik/tekartik_midi.dart.svg?branch=master)](https://travis-ci.org/alextekartik/tekartik_midi.dart)

*API subject to change*

## Usage example

### Creating a midi file

     MidiFile file = new MidiFile();
     file.fileFormat = MidiFile.FORMAT_MULTI_TRACK;
     file.ppq = 240;

     MidiTrack track = new MidiTrack();
     track.addEvent(0, new TimeSigEvent(4, 4));
     track.addEvent(0, new TempoEvent.bpm(120));
     track.addEvent(0, new EndOfTrackEvent());
     file.addTrack(track);

### Parsing a midi file

    List<int> data; // the file binary data

    MidiParser midiParser = new MidiParser(data);
    FileParser parser = new FileParser(midiParser);
    parser.parseFile();

    // Resulting midi file
    MidiFile file = parser.file;

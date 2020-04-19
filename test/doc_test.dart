import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';

void main() {
  group('doc', () {
    test('README creating midi file', () {
      var file = MidiFile();
      file.fileFormat = MidiFile.formatMultiTrack;
      file.ppq = 240;

      var track = MidiTrack();
      track.addEvent(0, TimeSigEvent(4, 4));
      track.addEvent(0, TempoEvent.bpm(120));
      track.addEvent(0, EndOfTrackEvent());
      file.addTrack(track);
    });

    test('README parsing midi file', () {
      try {
        Uint8List data; // the file binary data

        // ... fill the data from a midi file

        var midiParser = MidiParser(data);
        var parser = FileParser(midiParser);
        parser.parseFile();

        // Resulting midi file
        var file = parser.file;

        file.dump();
      } catch (_) {
        // Crashes since data is null
      }
    });
  });
}

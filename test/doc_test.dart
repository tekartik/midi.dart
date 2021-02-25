import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

final sampleData = Uint8List.fromList(parseHexString(
    '4d 54 68 64 00 00 00 06 00 01 00 02 01 e0 4d 54 72 6b 00 00 00 13 00 ff 58 04 04 02 18 08 00 ff 51 03 06 1a 80 00 ff 2f 00 4d 54 72 6b 00 00 00 00'));
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
      var someData = sampleData;
      try {
        // ignore: omit_local_variable_types
        Uint8List data = someData; // the file binary data

        // ... fill the data from a midi file

        var midiParser = MidiParser(data);
        var parser = FileParser(midiParser);
        parser.parseFile();

        // Resulting midi file
        var file = parser.file!;

        file.dump();
      } catch (_) {
        // Crashes since data is null
      }
    });
  });
}

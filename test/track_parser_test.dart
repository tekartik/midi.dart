library track_parser_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

main() {
  group('track parser', () {
    test('bad header', () {
      String data = "Dummy";
      MidiParser midiParser = MidiParser(data.codeUnits);
      TrackParser parser = TrackParser(midiParser);
      try {
        parser.parseHeader();
        fail("dummy header");
      } on FormatException catch (e) {
        expect(e.message, equals('Bad track header'));
      }
    });

    test('good header', () {
      List<int> data = [
        'M'.codeUnitAt(0),
        'T'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'k'.codeUnitAt(0),
        1,
        2,
        3,
        4
      ];
      MidiParser midiParser = MidiParser(data);
      TrackParser parser = TrackParser(midiParser);
      parser.parseHeader();
      expect(parser.trackSize, equals(0x01020304));
    });

    test('parse events', () {
      List<int> data = [0, 0xff, 0x2f, 0, 0, 0xff, 0x2f, 0];
      MidiParser midiParser = MidiParser(data);
      TrackParser parser = TrackParser(midiParser);
      parser.track = MidiTrack();
      parser.endPosition = 8;
      parser.parseEvents();
      expect(parser.track.events.length, equals(2));
    });

    test('parse track', () {
      //List<int> data = parseHexString("4d 54 68 64 00 00 00 06 00 01 00 02 01 e0 4d 54 72 6b 00 00 00 13 00 ff 58 04 04 02 18 08 00 ff 51 03 06 1a 80 00 ff 2f 00 4d 54 72 6b 00 00 00");
      List<int> data = parseHexString(
          "4d 54 72 6b 00 00 00 13 00 ff 58 04 04 02 18 08 00 ff 51 03 06 1a 80 00 ff 2f 00");
      MidiParser midiParser = MidiParser(data);
      TrackParser parser = TrackParser(midiParser);
      parser.parseTrack();
      expect(parser.track.events[0].midiEvent is TimeSigEvent, isTrue);
      expect(parser.track.events[1].midiEvent is TempoEvent, isTrue);
      expect(parser.track.events[2].midiEvent is EndOfTrackEvent, isTrue);
//      parser.track.events.forEach((MidiEvent e) {
//        print(e);
//      });
    });
  });
}

library;

import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';

import 'test_common.dart';

void main() {
  group('track parser', () {
    test('bad header', () {
      final data = 'Dummy';
      final midiParser = MidiParser(data.codeUnits);
      final parser = TrackParser(midiParser);
      try {
        parser.parseHeader();
        fail('dummy header');
      } on FormatException catch (e) {
        expect(e.message, equals('Bad track header'));
      }
    });

    test('good header', () {
      final data = <int>[
        'M'.codeUnitAt(0),
        'T'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'k'.codeUnitAt(0),
        1,
        2,
        3,
        4,
      ];
      final midiParser = MidiParser(data);
      final parser = TrackParser(midiParser);
      parser.parseHeader();
      expect(parser.trackSize, equals(0x01020304));
    });

    test('parse events', () {
      final data = <int>[0, 0xff, 0x2f, 0, 0, 0xff, 0x2f, 0];
      final midiParser = MidiParser(data);
      final parser = TrackParser(midiParser);
      parser.track = MidiTrack();
      parser.endPosition = 8;
      parser.parseEvents();
      expect(parser.track!.events.length, equals(2));
    });

    test('parse track', () {
      //final data = parseHexString('4d 54 68 64 00 00 00 06 00 01 00 02 01 e0 4d 54 72 6b 00 00 00 13 00 ff 58 04 04 02 18 08 00 ff 51 03 06 1a 80 00 ff 2f 00 4d 54 72 6b 00 00 00');
      final data = parseHexString(
        '4d 54 72 6b 00 00 00 13 00 ff 58 04 04 02 18 08 00 ff 51 03 06 1a 80 00 ff 2f 00',
      );
      final midiParser = MidiParser(data);
      final parser = TrackParser(midiParser);
      parser.parseTrack();
      expect(parser.track!.events[0].midiEvent is TimeSigEvent, isTrue);
      expect(parser.track!.events[1].midiEvent is TempoEvent, isTrue);
      expect(parser.track!.events[2].midiEvent is EndOfTrackEvent, isTrue);
      //      parser.track.events.forEach((MidiEvent e) {
      //        print(e);
      //      });
    });
  });
}

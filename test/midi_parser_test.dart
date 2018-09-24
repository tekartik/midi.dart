library midi_parser_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi_parser.dart';

main() {
  group('midi parser', () {
    test('variable length data', () {
      MidiParser parser = MidiParser([0]);
      expect(parser.readVariableLengthData(), equals(0));

      expect(MidiParser([0x40]).readVariableLengthData(), equals(0x40));
      expect(MidiParser([0x7F]).readVariableLengthData(), equals(0x7F));

      expect(MidiParser([0x81, 0]).readVariableLengthData(), equals(0x80));

      expect(MidiParser([0xC0, 0]).readVariableLengthData(), equals(0x2000));
      expect(MidiParser([0xFF, 0x7F]).readVariableLengthData(), equals(0x3FFF));

      expect(MidiParser([0xFF, 0xFF, 0x7F]).readVariableLengthData(),
          equals(0x1FFFFF));

      expect(MidiParser([0xC0, 0x80, 0x80, 0]).readVariableLengthData(),
          equals(0x8000000));

      expect(MidiParser([0xFF, 0xFF, 0xFF, 0x7F]).readVariableLengthData(),
          equals(0xFFFFFFF));
    });
  });
}

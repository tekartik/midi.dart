library midi_writer_test;

import 'package:test/test.dart';

import 'package:tekartik_midi/midi_writer.dart';

main() {
  group('midi writer', () {
    test('write variable length data', () {
      MidiWriter writer = new MidiWriter();

      writer.writeVariableLengthData(0);
      expect(writer.data, equals([0]));

      writer = new MidiWriter()..writeVariableLengthData(0x40);
      expect(writer.data, equals([0x40]));

      writer = new MidiWriter()..writeVariableLengthData(0x7f);
      expect(writer.data, equals([0x7f]));

      writer = new MidiWriter()..writeVariableLengthData(0x80);
      expect(writer.data, equals([0x81, 0]));

      writer = new MidiWriter()..writeVariableLengthData(0x2000);
      expect(writer.data, equals([0xc0, 0]));

      writer = new MidiWriter()..writeVariableLengthData(0x3fff);
      expect(writer.data, equals([0xff, 0x7f]));

      writer = new MidiWriter()..writeVariableLengthData(0x1fffff);
      expect(writer.data, equals([0xff, 0xff, 0x7f]));

      writer = new MidiWriter()..writeVariableLengthData(0x8000000);
      expect(writer.data, equals([0xc0, 0x80, 0x80, 0]));

      writer = new MidiWriter()..writeVariableLengthData(0xfffffff);
      expect(writer.data, equals([0xff, 0xff, 0xff, 0x7f]));
    });
  });
}

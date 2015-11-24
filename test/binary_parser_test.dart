library binary_parser_test;

import 'package:test/test.dart';

import 'package:tekartik_midi/midi_parser.dart';

main() {
  group('binary parser', () {
    test('read be integer', () {
      List<int> data = [0, 1, 0xCD, 0xEF, 2, 3, 4, 5];
      BinaryBEParser parser = new BinaryBEParser(data);
      expect(parser.readUint16(), equals(1));
      expect(parser.readUint16(), equals(0xCDEF));
      expect(parser.readUint32(), equals(0x02030405));
    });
  });
}

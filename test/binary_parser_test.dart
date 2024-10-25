library;

import 'package:tekartik_midi/midi_parser.dart';

import 'test_common.dart';

void main() {
  group('binary parser', () {
    test('read be integer', () {
      final data = <int>[0, 1, 0xCD, 0xEF, 2, 3, 4, 5];
      final parser = BinaryBEParser(data);
      expect(parser.readUint16(), equals(1));
      expect(parser.readUint16(), equals(0xCDEF));
      expect(parser.readUint32(), equals(0x02030405));
    });
    test('signedValue', () {
      expect(signedValueToByte(-1), 0xFF);
      expect(signedValueToByte(-2), 0xFE);
      expect(signedValueToByte(2), 0x02);
      expect(byteToSignedValue(0xFF), -1);
      expect(byteToSignedValue(0xFE), -2);
      expect(byteToSignedValue(2), 2);
    });
  });
}

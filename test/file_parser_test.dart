@TestOn("vm")
library file_parser_test;

import 'dart:io';

import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';

import 'io_test_common.dart';

void main() {
  group('file parser', () {
    test('bad header', () {
      String data = "Dummy";
      MidiParser midiParser = MidiParser(data.codeUnits);
      FileParser parser = FileParser(midiParser);
      try {
        parser.parseHeader();
        fail("dummy header");
      } on FormatException catch (_) {}
    });

    test('good header', () {
      List<int> data = [
        'M'.codeUnitAt(0),
        'T'.codeUnitAt(0),
        'h'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0,
        0,
        0,
        6,
        0,
        1,
        0,
        2,
        0,
        3
      ];
      MidiParser midiParser = MidiParser(data);
      FileParser parser = FileParser(midiParser);
      parser.parseHeader();
      expect(parser.file.fileFormat, equals(1));
      expect(parser.file.trackCount, equals(2));
      expect(parser.file.timeDivision, equals(3));
    });

    test('parse header SMPTE frames per seconds', () {
      MidiFile file = FileParser.dataFile(
          parseHexString("4D 54 68 64  00 00 00 06  00 01 00 00  E7 28"));
      expect(file.frameCountPerSecond, 25);
      expect(file.divisionCountPerFrame, 40);
    });

    test('parse file', () {
      List<int> data = parseHexString(
          "4d 54 68 64 00 00 00 06 00 01 00 02 01 e0 4d 54 72 6b 00 00 00 13 00 ff 58 04 04 02 18 08 00 ff 51 03 06 1a 80 00 ff 2f 00 4d 54 72 6b 00 00 00 00");
      MidiParser midiParser = MidiParser(data);
      FileParser parser = FileParser(midiParser);
      parser.parseFile();
    });

    test('parse demo file', () {
      return File(inDataFilenamePath("simple_in.mid"))
          .readAsBytes()
          .then((data) {
        MidiFile file = FileParser.dataFile(data);
        file.dump();
      });
    }, skip: true);

    test('parse note on off file', () {
      return File(inDataFilenamePath("note_on_off.mid"))
          .readAsBytes()
          .then((data) {
        FileParser.dataFile(data);
        //file.dump();
      });
    });

    // to skip
    test('parse take 5', () {
      return File(inDataFilenamePath("tmp/take_5.mid"))
          .readAsBytes()
          .then((data) {
        MidiFile file = FileParser.dataFile(data);
        expect(file.trackCount, 30);
        //file.dump();
      });
    }, skip: true);
  });
}

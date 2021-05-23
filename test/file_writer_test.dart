@TestOn('vm')
library file_writer_test;

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

import 'io_test_common.dart';

void main() {
  group('file writer', () {
    test('write header', () {
      final midiWriter = MidiWriter();
      final writer = FileWriter(midiWriter);

      final file = MidiFile();
      file.fileFormat = 1;
      file.trackCount = 2;
      file.timeDivision = 3;
      writer.file = file;

      writer.writeHeader();
      expect(
          writer.data,
          equals([
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
          ]));
    });

    void writeReadAndCheck(MidiFile file) {
      final data = FileWriter.fileData(file);

      //print(data);
      expect(FileParser.dataFile(data), file);
    }

    Future writeOnFileReadAndCheck(String filename, MidiFile file) async {
      final data = FileWriter.fileData(file);
      var ioFile = File(outDataFilenamePath(filename));
      await ioFile.parent.create(recursive: true);
      await ioFile.writeAsBytes(data);

      //print(data);
      expect(FileParser.dataFile(data), file);
    }

    test('round check', () async {
      final file = MidiFile();
      file.timeDivision = 3;
      writeReadAndCheck(file);

      final track = MidiTrack();
      file.addTrack(track);
      writeReadAndCheck(file);

      track.addEvent(1, NoteOnEvent(2, 42, 60));
      writeReadAndCheck(file);

      file.addTrack(MidiTrack());
    });

    test('note on note off', () async {
      final file = MidiFile();
      file.timeDivision = 3;
      final track = MidiTrack();
      file.addTrack(track);
      track.addEvent(1, NoteOnEvent(2, 42, 60));
      track.addEvent(1, NoteOffEvent(2, 42, 60));
      track.addEvent(1, EndOfTrackEvent());
      await writeOnFileReadAndCheck('note_on_off.mid', file);
    });
  });
}

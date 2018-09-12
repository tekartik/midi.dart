@TestOn("vm")
library file_writer_test;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'io_test_common.dart';

main() {
  group('file writer', () {
    test('write header', () {
      MidiWriter midiWriter = new MidiWriter();
      FileWriter writer = new FileWriter(midiWriter);

      MidiFile file = new MidiFile();
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

    writeReadAndCheck(MidiFile file) {
      List<int> data = FileWriter.fileData(file);

      //print(data);
      expect(FileParser.dataFile(data), file);
    }

    Future writeOnFileReadAndCheck(String filename, MidiFile file) async {
      List<int> data = FileWriter.fileData(file);
      var ioFile = new File(outDataFilenamePath(filename));
      await ioFile.parent.create(recursive: true);
      await ioFile.writeAsBytes(data);

      //print(data);
      expect(FileParser.dataFile(data), file);
    }

    test('round check', () async {
      MidiFile file = new MidiFile();
      file.timeDivision = 3;
      await writeReadAndCheck(file);

      MidiTrack track = new MidiTrack();
      file.addTrack(track);
      await writeReadAndCheck(file);

      track.addEvent(1, new NoteOnEvent(2, 42, 60));
      await writeReadAndCheck(file);

      file.addTrack(new MidiTrack());
    });

    test('note on note off', () async {
      MidiFile file = new MidiFile();
      file.timeDivision = 3;
      MidiTrack track = new MidiTrack();
      file.addTrack(track);
      track.addEvent(1, new NoteOnEvent(2, 42, 60));
      track.addEvent(1, new NoteOffEvent(2, 42, 60));
      track.addEvent(1, new EndOfTrackEvent());
      await writeOnFileReadAndCheck('note_on_off.mid', file);
    });
  });
}

@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

import 'io_test_common.dart';

void main() {
  group('data file', () {
    void readWriteAndCheck(String filename, {String? parentPath}) {
      File file;
      if (parentPath == null) {
        file = File(inDataFilenamePath(filename));
      } else {
        file = File(join(parentPath, filename));
      }
      List<int> data = file.readAsBytesSync();
      //final parser = FileParser(MidiParser(data));
      //parser.parseFile();
      //parser.file.dump();

      final fileRead = FileParser.dataFile(data);
      //fileRead.dump();
      final newData = FileWriter.fileData(fileRead);

      final newFileRead = FileParser.dataFile(newData);
      //newFileRead.dump();

      expect(fileRead, newFileRead);
      Directory(outDataPath).createSync(recursive: true);
      File(outDataFilenamePath(filename)).writeAsBytesSync(newData);

      //MidiWriter midiWriter = new MidiWriter();
      //new FileWriter(midiWriter).
    }

    test('file equals simple', () {
      Directory(outDataPath).createSync(recursive: true);
      readWriteAndCheck('simple_in.mid');
      readWriteAndCheck('sample.mid');
      //readWriteAndCheck('song.mid');
    });

    /*
    test('file equals green day', () {
      new Directory(outDataPath).createSync(recursive: true);

      readWriteAndCheck('Green Day - Welcome to Paradise.mid', parentPath: join(hgTopPath, 'assets/audio/midi'));
      //readWriteAndCheck('song.mid');
     
    });
    
    test('file equals jethro tull', () {
      new Directory(outDataPath).createSync(recursive: true);

      readWriteAndCheck('Jethro Tull - Bouree.mid', parentPath: join(hgTopPath, 'assets/audio/midi'));
      //readWriteAndCheck('song.mid');
     
    });
    */

    /*
    test('file equals take 5', () {
      new Directory(outDataPath).createSync(recursive: true);

      readWriteAndCheck('Take 5.mid', parentPath: join(hgTopPath, 'assets/audio/midi'));
      //readWriteAndCheck('song.mid');
     
    }, skip: true);
    */

    test('c d e out demo file', () async {
      final file = MidiFile();
      file.fileFormat = MidiFile.formatMultiTrack;
      file.ppq = 240;

      var track = MidiTrack();
      track.addEvent(0, TimeSigEvent(4, 4));
      track.addEvent(0, TempoEvent.bpm(120));
      track.addEvent(0, EndOfTrackEvent());
      file.addTrack(track);

      track = MidiTrack();
      track.addEvent(0, ProgramChangeEvent(1, 25));
      track.addEvent(0, NoteOnEvent(1, 42, 127));
      track.addEvent(240, NoteOnEvent(1, 44, 127));
      track.addEvent(240, NoteOnEvent(1, 46, 127));
      track.addEvent(240, NoteOffEvent(1, 42, 127));
      track.addEvent(0, NoteOffEvent(1, 44, 127));
      track.addEvent(480, NoteOffEvent(1, 46, 127));
      // track.add(new Event.NoteOn(0, 1, 42, 127));
      // track.add(new Event.NoteOff(480, 1, 42, 127));
      // // track.add(new Event.NoteOn(0, 1, 42, 127));
      // track.add(new Event.NoteOff(120, 1, 42, 127));
      track.addEvent(0, EndOfTrackEvent());

      file.addTrack(track);

      await Directory(outDataPath).create(recursive: true);
      File(outDataFilenamePath('c-d-e.midi'))
          .writeAsBytesSync(FileWriter.fileData(file));
    });
  });
}

@TestOn("vm")
library file_test;

import 'package:path/path.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'io_test_common.dart';

main() {
  group('data file', () {
    readWriteAndCheck(String filename, {String parentPath}) {
      File file;
      if (parentPath == null) {
        file = new File(outDataFilenamePath(filename));
      } else {
        file = new File(join(parentPath, filename));
      }
      List<int> data = file.readAsBytesSync();
      FileParser parser = new FileParser(new MidiParser(data));
      parser.parseFile();
      //parser.file.dump();

      MidiFile fileRead = FileParser.dataFile(data);
      //fileRead.dump();
      List<int> newData = FileWriter.fileData(fileRead);

      MidiFile newFileRead = FileParser.dataFile(newData);
      //newFileRead.dump();

      expect(fileRead, newFileRead);
      new File(outDataFilenamePath(filename)).writeAsBytesSync(newData);

      //MidiWriter midiWriter = new MidiWriter();
      //new FileWriter(midiWriter).
    }
    ;

    test('file equals simple', () {
      new Directory(outDataPath).createSync(recursive: true);
      readWriteAndCheck('simple_in.mid');
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

    test('c d e out demo file', () {
      MidiFile file = new MidiFile();
      file.fileFormat = MidiFile.FORMAT_MULTI_TRACK;
      file.ppq = 240;

      MidiTrack track = new MidiTrack();
      track.addEvent(0, new TimeSigEvent(4, 4));
      track.addEvent(0, new TempoEvent.bpm(120));
      track.addEvent(0, new EndOfTrackEvent());
      file.addTrack(track);

      track = new MidiTrack();
      track.addEvent(0, new ProgramChangeEvent(1, 25));
      track.addEvent(0, new NoteOnEvent(1, 42, 127));
      track.addEvent(240, new NoteOnEvent(1, 44, 127));
      track.addEvent(240, new NoteOnEvent(1, 46, 127));
      track.addEvent(240, new NoteOffEvent(1, 42, 127));
      track.addEvent(0, new NoteOffEvent(1, 44, 127));
      track.addEvent(480, new NoteOffEvent(1, 46, 127));
      // track.add(new Event.NoteOn(0, 1, 42, 127));
      // track.add(new Event.NoteOff(480, 1, 42, 127));
      // // track.add(new Event.NoteOn(0, 1, 42, 127));
      // track.add(new Event.NoteOff(120, 1, 42, 127));
      track.addEvent(0, new EndOfTrackEvent());

      file.addTrack(track);

      new File(outDataFilenamePath('c-d-e.midi'))
          .writeAsBytesSync(FileWriter.fileData(file));
    });
  });
}

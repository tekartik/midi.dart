library;

import 'package:tekartik_midi/midi.dart';

import 'test_common.dart';

void main() {
  group('midi file', () {
    test('time divisions ppq', () {
      final file = MidiFile();
      expect(file.ppq, 120);
      file.timeDivision = 3;

      expect(file.ppq, file.timeDivision);

      file.ppq = 4;
      expect(file.ppq, file.timeDivision);

      expect(file.divisionCountPerFrame, isNull);
      expect(file.frameCountPerSecond, isNull);
    });

    test('time divisions frame', () {
      final file = MidiFile();
      file.timeDivision = 59176;

      expect(file.ppq, null);
      expect(file.frameCountPerSecond, 25);
      expect(file.divisionCountPerFrame, 40);

      file.setFrameDivision(29, 41);
      expect(file.ppq, null);
      expect(file.frameCountPerSecond, 29.97);
      expect(file.divisionCountPerFrame, 41);
    });

    test('file equals', () {
      final file = MidiFile();
      expect(file, file);

      final file2 = MidiFile();
      expect(file, file2);

      file2.timeDivision = 1;
      expect(file, isNot(file2));
      file.timeDivision = 1;
      file.fileFormat = 1;
      file2.fileFormat = 0;
      expect(file, isNot(file2));
      file.fileFormat = 0;
      expect(file, file2);

      final track = MidiTrack();
      file.addTrack(track);

      expect(file, isNot(file2));
      final track2 = MidiTrack();
      expect(track, track2);
//
//      track.events.add(new TempoEvent(0, 120));
//      expect(track, isNot(track2));
//      track2.events.add(new TempoEvent(0, 120));
//      expect(track, track2);
    });
  });
}

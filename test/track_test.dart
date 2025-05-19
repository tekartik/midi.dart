library;

import 'package:tekartik_common_utils/foundation/constants.dart';
import 'package:tekartik_midi/midi.dart';

import 'test_common.dart';

void main() {
  group('midi track', () {
    test('track equals', () {
      final track = MidiTrack();
      expect(track, track);

      final track2 = MidiTrack();
      expect(track, track2);

      track.addEvent(0, TempoEvent(120));
      expect(track, isNot(track2));
      track2.addEvent(0, TempoEvent(120));
      expect(track, track2);
    });
    test('add twice', () {
      var track = MidiTrack();
      var track2 = MidiTrack();
      var file = MidiFile();
      file.addTrack(track);
      file.addTrack(track2);
      if (kDebugMode) {
        expect(() => file.addTrack(track2), throwsStateError);
      }
    });
    test('addAbsoluteEvent', () {
      MidiTrack track;
      // Add on empty
      track = MidiTrack();
      track.addAbsolutionEvent(0, TempoEvent(0));
      expect(track.events.first, isNotNull);
      expect(track.events.length, 1);

      // Add first
      track = MidiTrack();
      track.addEvent(10, TempoEvent(1));
      track.addAbsolutionEvent(5, TempoEvent(2));
      expect((track.events.first.midiEvent as TempoEvent).tempo, 2);
      expect(track.events.length, 2);

      // add middle
      track = MidiTrack();
      track.addEvent(5, TempoEvent(1));
      track.addEvent(10, TempoEvent(2));
      track.addAbsolutionEvent(5, TempoEvent(3));
      expect((track.events[1].midiEvent as TempoEvent).tempo, 3);
      expect(track.events.length, 3);

      // add last
      track = MidiTrack();
      track.addEvent(5, TempoEvent(1));
      track.addAbsolutionEvent(5, TempoEvent(2));
      expect((track.events[1].midiEvent as TempoEvent).tempo, 2);
      expect(track.events.length, 2);
    });

    test('absoluteTime', () {
      final track = MidiTrack();
      track.addEvent(10, TempoEvent(1));
      track.addEvent(25, TempoEvent(2));
      track.addEvent(30, TempoEvent(3));
      expect(track.absoluteTimeAt(0), 10);
      expect(track.absoluteTimeAt(2), 65);
      expect(track.absoluteTimeDiff(0, 1), -25);
      expect(track.absoluteTimeDiff(0, 2), -55);
      expect(track.absoluteTimeDiff(1, 2), -30);
      expect(track.absoluteTimeDiff(2, 1), 30);
    });
  });
}

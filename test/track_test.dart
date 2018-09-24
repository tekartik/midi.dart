library track_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';

main() {
  group('midi track', () {
    test('track equals', () {
      MidiTrack track = MidiTrack();
      expect(track, track);

      MidiTrack track2 = MidiTrack();
      expect(track, track2);

      track.addEvent(0, TempoEvent(120));
      expect(track, isNot(track2));
      track2.addEvent(0, TempoEvent(120));
      expect(track, track2);
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
  });
}

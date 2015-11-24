library track_test;

import 'package:test/test.dart';

import 'package:tekartik_midi/midi.dart';

main() {
  group('midi track', () {
    test('track equals', () {
      MidiTrack track = new MidiTrack();
      expect(track, track);

      MidiTrack track2 = new MidiTrack();
      expect(track, track2);

      track.addEvent(0, new TempoEvent(120));
      expect(track, isNot(track2));
      track2.addEvent(0, new TempoEvent(120));
      expect(track, track2);
    });
  });
}

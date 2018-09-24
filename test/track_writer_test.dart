library track_writer_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:tekartik_midi/midi_parser.dart';

main() {
  group('track writer', () {
    test('write track', () {
      MidiWriter midiWriter = MidiWriter();
      TrackWriter writer = TrackWriter(midiWriter);

      MidiTrack track = MidiTrack();
      writer.track = track;

      MetaEvent event = MetaEvent(0x2F);

      track.addEvent(0, event);
      track.addEvent(0, event);

      writer.writeTrack();
      expect(
          writer.data,
          equals([
            'M'.codeUnitAt(0),
            'T'.codeUnitAt(0),
            'r'.codeUnitAt(0),
            'k'.codeUnitAt(0),
            0,
            0,
            0,
            8,
            0,
            0xff,
            0x2f,
            0,
            0,
            0xff,
            0x2f,
            0
          ]));
    });

    writeReadAndCheck(MidiTrack track) {
      MidiWriter midiWriter = MidiWriter();
      TrackWriter writer = TrackWriter(midiWriter);
      writer.writeTrack(track);

      MidiParser midiParser = MidiParser(writer.data);
      TrackParser parser = TrackParser(midiParser);
      expect(parser.parseTrack(), track);
    }

    test('round check', () {
      MidiTrack track = MidiTrack();
      writeReadAndCheck(track);

      track.addEvent(0, NoteOnEvent(2, 42, 60));
      writeReadAndCheck(track);

      track.addEvent(1, TempoEvent(120));
      writeReadAndCheck(track);

      track.addEvent(2, ProgramChangeEvent(1, 2));
      writeReadAndCheck(track);

      track.addEvent(3, TimeSigEvent.topBottom(4, 4));
      writeReadAndCheck(track);

      track.addEvent(4, EndOfTrackEvent());
      writeReadAndCheck(track);
    });
  });
}

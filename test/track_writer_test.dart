library track_writer_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:tekartik_midi/midi_parser.dart';

main() {
  group('track writer', () {
    test('write track', () {
      MidiWriter midiWriter = new MidiWriter();
      TrackWriter writer = new TrackWriter(midiWriter);

      MidiTrack track = new MidiTrack();
      writer.track = track;

      MetaEvent event = new MetaEvent(0x2F);

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
      MidiWriter midiWriter = new MidiWriter();
      TrackWriter writer = new TrackWriter(midiWriter);
      writer.writeTrack(track);

      MidiParser midiParser = new MidiParser(writer.data);
      TrackParser parser = new TrackParser(midiParser);
      expect(parser.parseTrack(), track);
    }

    test('round check', () {
      MidiTrack track = new MidiTrack();
      writeReadAndCheck(track);

      track.addEvent(0, new NoteOnEvent(2, 42, 60));
      writeReadAndCheck(track);

      track.addEvent(1, new TempoEvent(120));
      writeReadAndCheck(track);

      track.addEvent(2, new ProgramChangeEvent(1, 2));
      writeReadAndCheck(track);

      track.addEvent(3, new TimeSigEvent.topBottom(4, 4));
      writeReadAndCheck(track);

      track.addEvent(4, new EndOfTrackEvent());
      writeReadAndCheck(track);
    });
  });
}

library;

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

import 'test_common.dart';

void main() {
  group('track writer', () {
    test('write track', () {
      final midiWriter = MidiWriter();
      final writer = TrackWriter(midiWriter);

      final track = MidiTrack();
      writer.track = track;

      final event = MetaEvent(0x2F);

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

    void writeReadAndCheck(MidiTrack track) {
      final midiWriter = MidiWriter();
      final writer = TrackWriter(midiWriter);
      writer.writeTrack(track);

      final midiParser = MidiParser(writer.data);
      final parser = TrackParser(midiParser);
      expect(parser.parseTrack(), track);
    }

    test('round check', () {
      final track = MidiTrack();
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

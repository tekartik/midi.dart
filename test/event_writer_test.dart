library event_writer_test;

import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

import 'test_common.dart';

void main() {
  group('event writer', () {
    test('write meta', () {
      final midiWriter = MidiWriter();
      final writer = EventWriter(midiWriter);

      final event = MetaEvent(0x2F);
      writer.event = TrackEvent(0, event);

      writer.writeEvent();
      expect(writer.data, equals([0, 0xff, 0x2f, 0]));
    });

    test('write note on', () {
      final midiWriter = MidiWriter();
      final writer = EventWriter(midiWriter);

      writer.event = TrackEvent(1, NoteOnEvent(2, 64, 96));

      writer.writeEvent();
      expect(writer.data, parseHexString('01 92 40 60'));
    });

    test('write note off', () {
      final midiWriter = MidiWriter();
      final writer = EventWriter(midiWriter);

      writer.event = TrackEvent(1, NoteOnEvent(2, 64, 96));

      writer.writeEvent();
      expect(writer.data, parseHexString('01 92 40 60'));
    });

    void writeReadAndCheck(TrackEvent event) {
      final midiWriter = MidiWriter();
      final writer = EventWriter(midiWriter);
      writer.event = event;
      writer.writeEvent();

      final midiParser = MidiParser(writer.data);
      final parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.trackEvent, event);
    }

    void writeReadAndCheckMidiEvent(MidiEvent midiEvent) {
      writeReadAndCheck(TrackEvent(0, midiEvent));
    }

    test('eot', () {
      writeReadAndCheckMidiEvent(EndOfTrackEvent());
    });

    test('sysex', () {
      writeReadAndCheckMidiEvent(SysExEvent.withParam(0xF0, [12, 0xF7]));
    });

    test('round check', () {
      writeReadAndCheck(TrackEvent(1, NoteOffEvent(2, 3, 4)));
      writeReadAndCheck(TrackEvent(1, NoteOnEvent(2, 3, 4)));
    });
  });
}

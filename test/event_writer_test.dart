library event_writer_test;

import 'package:test/test.dart';

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_utils/hex_utils.dart';

main() {
  group('event writer', () {
    test('write meta', () {
      MidiWriter midiWriter = new MidiWriter();
      EventWriter writer = new EventWriter(midiWriter);

      MetaEvent event = new MetaEvent(0x2F, null);
      writer.event = new TrackEvent(0, event);

      writer.writeEvent();
      expect(writer.data, equals([0, 0xff, 0x2f, 0]));
    });

    test('write note on', () {
      MidiWriter midiWriter = new MidiWriter();
      EventWriter writer = new EventWriter(midiWriter);

      writer.event = new TrackEvent(1, new NoteOnEvent(2, 64, 96));

      writer.writeEvent();
      expect(writer.data, parseHexString("01 92 40 60"));
    });

    test('write note off', () {
      MidiWriter midiWriter = new MidiWriter();
      EventWriter writer = new EventWriter(midiWriter);

      writer.event = new TrackEvent(1, new NoteOnEvent(2, 64, 96));

      writer.writeEvent();
      expect(writer.data, parseHexString("01 92 40 60"));
    });

    writeReadAndCheck(TrackEvent event) {
      MidiWriter midiWriter = new MidiWriter();
      EventWriter writer = new EventWriter(midiWriter);
      writer.event = event;
      writer.writeEvent();

      MidiParser midiParser = new MidiParser(writer.data);
      EventParser parser = new EventParser(midiParser);
      parser.parseEvent();
      expect(parser.trackEvent, event);
    }

    writeReadAndCheckMidiEvent(MidiEvent midiEvent) {
      writeReadAndCheck(new TrackEvent(0, midiEvent));
    }

    test('eot', () {
      writeReadAndCheckMidiEvent(new EndOfTrackEvent());
    });

    test('sysex', () {
      writeReadAndCheckMidiEvent(new SysExEvent.withParam(0xF0, [12, 0xF7]));
    });

    test('round check', () {
      writeReadAndCheck(new TrackEvent(1, new NoteOffEvent(2, 3, 4)));
      writeReadAndCheck(new TrackEvent(1, new NoteOnEvent(2, 3, 4)));
    });
  });
}

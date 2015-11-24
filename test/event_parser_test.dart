library event_parser_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';

import 'package:tekartik_utils/hex_utils.dart';

main() {
  group('midi event parser', () {
    test('parse event', () {
      List<int> data = [0, 0xff, 0x2f, 0];
      MidiParser midiParser = new MidiParser(data);
      EventParser parser = new EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is EndOfTrackEvent, isTrue);
    });

    test('parse sysex event', () {
      List<int> data = parseHexString("00 F0  05 7E 7F 09  01 F7");
      MidiParser midiParser = new MidiParser(data);
      EventParser parser = new EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is SysExEvent, isTrue);
      SysExEvent sysExEvent = parser.event as SysExEvent;
      expect(sysExEvent.data, parseHexString("7E 7F 09  01 F7"));
    });

    test('parse other event', () {
      List<int> data = parseHexString("00 FF 51 03 06 1a 80");
      MidiParser midiParser = new MidiParser(data);
      EventParser parser = new EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is TempoEvent, isTrue);
      TempoEvent tempoEvent = parser.event as TempoEvent;
      expect(tempoEvent.tempoBpm, 150);

      data = parseHexString("01 83 3d 79");
      midiParser = new MidiParser(data);
      parser = new EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is NoteOffEvent, isTrue);

      data = parseHexString("00 b0 01 02");
      midiParser = new MidiParser(data);
      parser = new EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is ControlChangeEvent, isTrue);
    });

    test('parse all notes / all sounds off event', () {
      // All sounds
      List<int> data = parseHexString("00 B0 7B 00");
      MidiParser midiParser = new MidiParser(data);
      EventParser parser = new EventParser(midiParser);

      parser.parseEvent();
      expect(parser.event is ControlChangeEvent, isTrue);
      ControlChangeEvent cce = parser.event;
      expect(cce.controller, ControlChangeEvent.ALL_NOTES_OFF);
      expect(cce, ControlChangeEvent.newAllNotesOffEvent(0));

      cce = EventParser.dataParseEvent(parseHexString("00 B0 78 00"));
      expect(cce.controller, ControlChangeEvent.ALL_SOUND_OFF);
      expect(cce, ControlChangeEvent.newAllSoundOffEvent(0));
    });

    test('parse event omitted command', () {
      List<int> data = parseHexString("00 84 40 7f 00 30 7f");
      MidiParser midiParser = new MidiParser(data);
      EventParser parser = new EventParser(midiParser);
      parser.parseEvent();
      NoteOffEvent noteOffEvent = parser.event as NoteOffEvent;
      //print(noteOffEvent);
      parser.parseEvent();
      noteOffEvent = parser.event as NoteOffEvent;
      //print(noteOffEvent);
    });
  });
}

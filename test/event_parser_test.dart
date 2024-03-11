library event_parser_test;

import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';

import 'test_common.dart';

void main() {
  group('midi event parser', () {
    test('parse event', () {
      final data = <int>[0, 0xff, 0x2f, 0];
      final midiParser = MidiParser(data);
      final parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is EndOfTrackEvent, isTrue);
    });

    test('parse sysex event', () {
      final data = parseHexString('00 F0  05 7E 7F 09  01 F7');
      final midiParser = MidiParser(data);
      final parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is SysExEvent, isTrue);
      final sysExEvent = parser.event as SysExEvent;
      expect(sysExEvent.data, parseHexString('7E 7F 09  01 F7'));
    });

    test('parse trackname event', () {
      final data = parseHexString('00 ff 03 07 54 72 61 63 6b 20 32');
      final midiParser = MidiParser(data);
      final parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is TrackNameEvent, isTrue);
      final trackNameEvent = parser.event as TrackNameEvent;
      expect(trackNameEvent.trackName, 'Track 2');
    });

    test('parse other event', () {
      var data = parseHexString('00 FF 51 03 06 1a 80');
      var midiParser = MidiParser(data);
      var parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is TempoEvent, isTrue);
      final tempoEvent = parser.event as TempoEvent;
      expect(tempoEvent.tempoBpm, 150);

      data = parseHexString('01 83 3d 79');
      midiParser = MidiParser(data);
      parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is NoteOffEvent, isTrue);

      data = parseHexString('00 b0 01 02');
      midiParser = MidiParser(data);
      parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event is ControlChangeEvent, isTrue);
    });

    test('parse all notes / all sounds off event', () {
      // All sounds
      final data = parseHexString('00 B0 7B 00');
      final midiParser = MidiParser(data);
      final parser = EventParser(midiParser);

      parser.parseEvent();
      expect(parser.event is ControlChangeEvent, isTrue);
      var cce = parser.event as ControlChangeEvent;
      expect(cce.controller, ControlChangeEvent.allNotesOff);
      expect(cce, ControlChangeEvent.newAllNotesOffEvent(0));

      cce = EventParser.dataParseEvent(parseHexString('00 B0 78 00'))
          as ControlChangeEvent;
      expect(cce.controller, ControlChangeEvent.allSoundOff);
      expect(cce, ControlChangeEvent.newAllSoundOffEvent(0));
    });

    test('parse event omitted command', () {
      final data = parseHexString('00 84 40 7f 00 30 7f');
      final midiParser = MidiParser(data);
      final parser = EventParser(midiParser);
      parser.parseEvent();
      expect(parser.event, const TypeMatcher<NoteOffEvent>());
      //print(noteOffEvent);
      parser.parseEvent();
      expect(parser.event, const TypeMatcher<NoteOffEvent>());
    });
  });
}

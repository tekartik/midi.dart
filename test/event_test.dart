import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi.dart';

import 'test_common.dart';

void main() {
  group('midi event', () {
    NoteOnEvent getNoteOn() {
      return NoteOnEvent(2, 3, 4);
    }

    test('track event equals', () {
      final noteOn = getNoteOn();
      expect(TrackEvent(0, noteOn), TrackEvent(0, noteOn));

      expect(TrackEvent(0, noteOn), isNot(TrackEvent(1, noteOn)));
    });

    test('note on equals', () {
      final noteOn = getNoteOn();
      expect(noteOn, noteOn);

      final noteOn2 = getNoteOn();
      expect(noteOn, noteOn2);

      final noteOn3 = NoteOnEvent(2, 3, 4);
      expect(noteOn, equals(noteOn3));

      final noteOn4 = NoteOnEvent(0, 3, 4);
      expect(noteOn, isNot(equals(noteOn4)));

      final noteOn5 = NoteOnEvent(2, 0, 4);
      expect(noteOn, isNot(equals(noteOn5)));

      final noteOn6 = NoteOnEvent(2, 3, 0);
      expect(noteOn, isNot(equals(noteOn6)));

      final noteOff = NoteOffEvent(2, 3, 4);
      expect(noteOn, isNot(equals(noteOff)));

      expect(NoteOnEvent(1, 2, 3).toString(), '91 p1 2 p2 3 note on');
    });

    test('program change', () {
      final event = ProgramChangeEvent(1, 12);
      expect(event, event);
      expect(event, ProgramChangeEvent(1, 12));
      expect(event.toString(), 'C1 p1 12 program change');
      expect(event, isNot(ProgramChangeEvent(1, 13)));
      expect(event, isNot(ProgramChangeEvent(0, 13)));
    });

    test('meta', () {
      final event = MetaEvent(0xF1);
      expect(event, event);
      expect(event, MetaEvent(0xF1));
      expect(event, MetaEvent(0xF1, []));
      expect(event, isNot(MetaEvent(0xF1, [1])));
      expect(event, isNot(MetaEvent(0xF2)));
      expect(MetaEvent(0xF2, [1]), MetaEvent(0xF2, [1]));
      expect(MetaEvent(0xF2, [1]), isNot(MetaEvent(0xF2, [2])));
      expect(MetaEvent(0xF1).toString(), 'FF meta F1');
      expect(MetaEvent(0xF2, [1]).toString(), 'FF meta F2 data 01');
    });

    test('tempo', () {
      var event = TempoEvent.bpm(150);
      expect(event.tempoBpm, 150);
      expect(event.tempo, 400000);
      expect(event.beatPerMillis, 0.0025);
      expect(event, TempoEvent.bpm(150));
      expect(event, isNot(TempoEvent.bpm(120)));
      event = TempoEvent.bpm(120);
      expect(event.tempoBpm, 120);
      expect(event.beatPerMillis, 0.002);
      expect(
        event.tempoBpm,
        TempoEvent.millisecondsPerMinute * event.beatPerMillis,
      );
      expect(event.tempo, 500000);
    });

    test('eot', () {
      final event = EndOfTrackEvent();
      expect(event, MetaEvent(47));
    });

    test('time sig', () {
      var event = TimeSigEvent.topBottom(4, 4);
      expect(event.top, 4);
      expect(event.bottom, 4);
      event = TimeSigEvent.topBottom(4, 16);
      expect(event.bottom, 16);

      try {
        TimeSigEvent.topBottom(4, 9);
        fail('not supported');
      } on FormatException catch (_) {}

      try {
        TimeSigEvent.topBottom(4, 0);
        fail('not supported');
      } on FormatException catch (_) {}
    });

    test('trackname', () {
      var event = TrackNameEvent(
        data: [0x54, 0x72, 0x61, 0x63, 0x6b, 0x20, 0x32],
      );
      expect(event.trackName, 'Track 2');
      expect(
        event.toString(),
        'FF meta 03 data 54 72 61 63  6B 20 32 track name: Track 2',
      );
    });

    test('metatext', () {
      var event = MetaTextEvent(
        data: [0x54, 0x72, 0x61, 0x63, 0x6b, 0x20, 0x32],
      );
      expect(event.metaCommand, 1);
      expect(event.text, 'Track 2');
      expect(toHexString(event.data), '547261636B2032');
      expect(
        event.toString(),
        'FF meta 01 data 54 72 61 63  6B 20 32 text: Track 2',
      );

      event = MetaTextEvent.text('élève');
      expect(event.metaCommand, 1);
      expect(event.text, 'élève');
      expect(toHexString(event.data), 'C3A96CC3A87665');
    });

    test('key signature', () {
      var event = KeySigEvent(1, 1);
      expect(event.alterations, 1);
      expect(event.scale, 1);
      expect(event, KeySigEvent(1, 1));
      expect(event, isNot(KeySigEvent(1, 0)));
      expect(event, isNot(KeySigEvent(0, 1)));
      event = KeySigEvent(-1, 0);
      expect(event.alterations, -1);
      expect(event.scale, 0);
    });
    test('various events', () {
      expect(
        ControlChangeEvent.newAllResetEvent(0).controller,
        ControlChangeEvent.allReset,
      );
    });
  });
}

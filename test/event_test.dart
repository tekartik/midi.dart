library event_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';

main() {
  group('midi event', () {
    NoteOnEvent getNoteOn() {
      return NoteOnEvent(2, 3, 4);
    }

    test('track event equals', () {
      NoteOnEvent noteOn = getNoteOn();
      expect(TrackEvent(0, noteOn), TrackEvent(0, noteOn));

      expect(TrackEvent(0, noteOn), isNot(TrackEvent(1, noteOn)));
    });

    test('note on equals', () {
      NoteOnEvent noteOn = getNoteOn();
      expect(noteOn, noteOn);

      NoteOnEvent noteOn2 = getNoteOn();
      expect(noteOn, noteOn2);

      NoteOnEvent noteOn3 = NoteOnEvent(2, 3, 4);
      expect(noteOn, equals(noteOn3));

      NoteOnEvent noteOn4 = NoteOnEvent(0, 3, 4);
      expect(noteOn, isNot(equals(noteOn4)));

      NoteOnEvent noteOn5 = NoteOnEvent(2, 0, 4);
      expect(noteOn, isNot(equals(noteOn5)));

      NoteOnEvent noteOn6 = NoteOnEvent(2, 3, 0);
      expect(noteOn, isNot(equals(noteOn6)));

      NoteOffEvent noteOff = NoteOffEvent(2, 3, 4);
      expect(noteOn, isNot(equals(noteOff)));
    });

    test('program change', () {
      ProgramChangeEvent event = ProgramChangeEvent(1, 12);
      expect(event, event);
      expect(event, isNot(ProgramChangeEvent(1, 13)));
      expect(event, isNot(ProgramChangeEvent(0, 13)));
    });

    test('meta', () {
      MetaEvent event = MetaEvent(0xF1, null);
      expect(event, event);
      expect(event, MetaEvent(0xF1, null));
      expect(event, isNot(MetaEvent(0xF1, [])));
      expect(event, isNot(MetaEvent(0xF2, null)));
      expect(MetaEvent(0xF2, [1]), MetaEvent(0xF2, [1]));
      expect(MetaEvent(0xF2, [1]), isNot(MetaEvent(0xF2, [2])));
    });

    test('tempo', () {
      TempoEvent event = TempoEvent.bpm(150);
      expect(event.tempoBpm, 150);
      expect(event, TempoEvent.bpm(150));
      expect(event, isNot(TempoEvent.bpm(120)));
    });

    test('eot', () {
      EndOfTrackEvent event = EndOfTrackEvent();
      expect(event, MetaEvent(47, null));
    });

    test('time sig', () {
      TimeSigEvent event = TimeSigEvent.topBottom(4, 4);
      expect(event.top, 4);
      expect(event.bottom, 4);
      event = TimeSigEvent.topBottom(4, 16);
      expect(event.bottom, 16);

      try {
        TimeSigEvent.topBottom(4, 9);
        fail("not supported");
      } on FormatException catch (_) {}

      try {
        TimeSigEvent.topBottom(4, 0);
        fail("not supported");
      } on FormatException catch (_) {}
    });

    test('various events', () {
      expect(ControlChangeEvent.newAllResetEvent(0).controller,
          ControlChangeEvent.allReset);
    });
  });
}

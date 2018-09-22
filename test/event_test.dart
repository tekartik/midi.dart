library event_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';

main() {
  group('midi event', () {
    NoteOnEvent getNoteOn() {
      return new NoteOnEvent(2, 3, 4);
    }

    test('track event equals', () {
      NoteOnEvent noteOn = getNoteOn();
      expect(new TrackEvent(0, noteOn), new TrackEvent(0, noteOn));

      expect(new TrackEvent(0, noteOn), isNot(new TrackEvent(1, noteOn)));
    });

    test('note on equals', () {
      NoteOnEvent noteOn = getNoteOn();
      expect(noteOn, noteOn);

      NoteOnEvent noteOn2 = getNoteOn();
      expect(noteOn, noteOn2);

      NoteOnEvent noteOn3 = new NoteOnEvent(2, 3, 4);
      expect(noteOn, equals(noteOn3));

      NoteOnEvent noteOn4 = new NoteOnEvent(0, 3, 4);
      expect(noteOn, isNot(equals(noteOn4)));

      NoteOnEvent noteOn5 = new NoteOnEvent(2, 0, 4);
      expect(noteOn, isNot(equals(noteOn5)));

      NoteOnEvent noteOn6 = new NoteOnEvent(2, 3, 0);
      expect(noteOn, isNot(equals(noteOn6)));

      NoteOffEvent noteOff = new NoteOffEvent(2, 3, 4);
      expect(noteOn, isNot(equals(noteOff)));
    });

    test('program change', () {
      ProgramChangeEvent event = new ProgramChangeEvent(1, 12);
      expect(event, event);
      expect(event, isNot(new ProgramChangeEvent(1, 13)));
      expect(event, isNot(new ProgramChangeEvent(0, 13)));
    });

    test('meta', () {
      MetaEvent event = new MetaEvent(0xF1, null);
      expect(event, event);
      expect(event, new MetaEvent(0xF1, null));
      expect(event, isNot(new MetaEvent(0xF1, [])));
      expect(event, isNot(new MetaEvent(0xF2, null)));
      expect(new MetaEvent(0xF2, [1]), new MetaEvent(0xF2, [1]));
      expect(new MetaEvent(0xF2, [1]), isNot(new MetaEvent(0xF2, [2])));
    });

    test('tempo', () {
      TempoEvent event = new TempoEvent.bpm(150);
      expect(event.tempoBpm, 150);
      expect(event, new TempoEvent.bpm(150));
      expect(event, isNot(new TempoEvent.bpm(120)));
    });

    test('eot', () {
      EndOfTrackEvent event = new EndOfTrackEvent();
      expect(event, new MetaEvent(47, null));
    });

    test('time sig', () {
      TimeSigEvent event = new TimeSigEvent.topBottom(4, 4);
      expect(event.top, 4);
      expect(event.bottom, 4);
      event = new TimeSigEvent.topBottom(4, 16);
      expect(event.bottom, 16);

      try {
        new TimeSigEvent.topBottom(4, 9);
        fail("not supported");
      } on FormatException catch (_) {}

      try {
        new TimeSigEvent.topBottom(4, 0);
        fail("not supported");
      } on FormatException catch (_) {}
    });

    test('various events', () {
      expect(ControlChangeEvent.newAllResetEvent(0).controller,
          ControlChangeEvent.allReset);
    });
  });
}

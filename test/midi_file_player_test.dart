library;

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';

import 'demo_file.dart';
import 'test_common.dart';

void main() {
  group('midi_file_player', () {
    test('ppq delta time to millis', () {
      final file = MidiFile();
      file.ppq = 240;
      final player = MidiFilePlayer(file);

      expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));
    });

    test('timestamp to absolute ms', () {
      final file = MidiFile();
      final player = MidiFilePlayer(file);
      player.start(0);
      expect(player.absoluteMsToTimestamp(10), 10);

      player.start(1);
      expect(player.absoluteMsToTimestamp(10), 11);

      player.setSpeedRatio(2);
      expect(player.absoluteMsToTimestamp(10), 6);
      expect(player.timestampToAbsoluteMs(6), 10);

      expect(player.timestampToAbsoluteMs(5), 8);
      player.setSpeedRatio(1, 5);
      expect(player.timestampToAbsoluteMs(5), 8);
      expect(player.absoluteMsToTimestamp(8), 5);
      expect(player.absoluteMsToTimestamp(10), 7);

      player.setSpeedRatio(2, 6);
      expect(player.absoluteMsToTimestamp(10), closeTo(6.5, 0.01));

      //expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));
    });

    test('speed ratio', () {
      final file = MidiFile();
      final player = MidiFilePlayer(file);
      file.ppq = 240;
      expect(player.tempoBpm, closeTo(120, 0.001));
      expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));

      player.setSpeedRatio(0.5);
      expect(player.tempoBpm, closeTo(120, 0.001));
      expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));
    });

    test('smtp delta time to millis', () {
      final file = MidiFile();
      file.setFrameDivision(25, 40);
      final player = MidiFilePlayer(file);

      expect(player.currentDeltaTimeUnitInMillis, closeTo(.5, 0.0001));

      player.setSpeedRatio(0.5);
      expect(player.tempoBpm, closeTo(120, 0.001));
      expect(player.currentDeltaTimeUnitInMillis, closeTo(.5, 0.0001));
    });

    test('get next event simple', () {
      final file = MidiFile();
      final player = MidiFilePlayer(file);
      file.ppq = 240;

      player.start(0);
      expect(player.next, isNull);

      final track = MidiTrack();
      file.addTrack(track);

      player.start(0);
      expect(player.next, isNull);

      MidiEvent event = NoteOnEvent(1, 42, 127);
      track.addEvent(0, event);

      player.start(0);
      var readEvent = player.next!;
      expect(readEvent.midiEvent, event);
      expect(readEvent.timestamp, 0);
      expect(player.next, isNull);

      MidiEvent event2 = NoteOffEvent(1, 42, 127);
      track.addEvent(240, event2);

      player.start(0);
      readEvent = player.next!;
      expect(readEvent.midiEvent, event);
      expect(readEvent.timestamp, 0);
      readEvent = player.next!;
      expect(readEvent.midiEvent, event2);
      expect(readEvent.timestamp, closeTo(500, 0.001));
      expect(player.next, isNull);
    });

    test('get next event 2 tracks', () {
      final file = MidiFile();
      final player = MidiFilePlayer(file);
      file.ppq = 240;

      final track1 = MidiTrack();
      file.addTrack(track1);
      final track2 = MidiTrack();
      file.addTrack(track2);

      player.start(0);
      expect(player.next, isNull);

      MidiEvent event1 = NoteOnEvent(1, 42, 127);
      track1.addEvent(0, event1);

      MidiEvent event2 = NoteOnEvent(1, 43, 127);
      track2.addEvent(120, event2);

      MidiEvent event3 = NoteOnEvent(1, 44, 127);
      track1.addEvent(240, event3);

      player.start(0);
      var readEvent = player.next!;
      expect(readEvent.midiEvent, event1);
      expect(readEvent.timestamp, 0);
      readEvent = player.next!;
      expect(readEvent.midiEvent, event2);
      expect(readEvent.timestamp, closeTo(250, 0.001));
      readEvent = player.next!;
      expect(readEvent.midiEvent, event3);
      expect(readEvent.timestamp, closeTo(500, 0.001));
      expect(player.next, isNull);
    });

    test('get next change tempo', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);

      final player = MidiFilePlayer(file);
      file.ppq = 240;

      MidiEvent event = NoteOnEvent(1, 42, 127);
      track.addEvent(240, event);

      player.start(0);
      player.setSpeedRatio(.5, 250);
      final readEvent = player.next!;
      expect(readEvent.midiEvent, event);
      expect(readEvent.timestamp, closeTo(750, 0.001));
      expect(player.next, isNull);
    });

    test('pause/resume', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);
      MidiEvent event = NoteOnEvent(1, 42, 127);
      track.addEvent(0, event);

      final player = MidiFilePlayer(file);
      file.ppq = 240;

      player.start(0);

      player.pause(1);
      expect(player.next, isNull);

      player.resume(2);
      final readEvent = player.next;
      final noteOnEvents = player.currentNoteOnEvents.toList();

      expect(noteOnEvents.length, 1);
      expect(noteOnEvents[0], readEvent);
    });

    test('load', () {
      final file = getDemoFileCDE();
      final player = MidiFilePlayer(file);
      player.start(1);
      //player.pause();
    });

    test('get duration', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);
      MidiEvent event = NoteOnEvent(1, 42, 127);
      // add twice
      track.addEvent(240, event);
      file.ppq = 240;

      expect(getMidiFileDuration(file), const Duration(milliseconds: 501));
      expect(MidiFilePlayer(file).totalDurationMs,
          closeTo(getMidiFileDuration(file).inMilliseconds, 1));

      track.addEvent(240, event);
      expect(getMidiFileDuration(file), const Duration(milliseconds: 1001));
      expect(MidiFilePlayer(file).totalDurationMs,
          closeTo(getMidiFileDuration(file).inMilliseconds, 1));
    });

    test('one_located_events', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);

      final player = MidiFilePlayer(file);

      MidiEvent event = NoteOnEvent(1, 42, 127);
      track.addEvent(240, event);

      //devPrint(player.locatedEvents);
      expect(player.locatedEvents!.length, 1);
      expect(player.locatedEvents!.first.midiEvent, event);
      expect(player.locatedEvents!.first.absoluteMs, closeTo(1000, 0.01));
    });

    test('two_located_events', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);

      final player = MidiFilePlayer(file);

      MidiEvent event = NoteOnEvent(1, 42, 127);
      track.addEvent(240, event);
      MidiEvent event2 = NoteOnEvent(1, 43, 127);
      track.addEvent(120, event2);
      file.ppq = 240;

      //devPrint(player.locatedEvents);
      expect(player.locatedEvents!.length, 2);
      expect(player.locatedEvents!.first.midiEvent, event);
      expect(player.locatedEvents!.first.absoluteMs, closeTo(500, 0.01));
      expect(player.locatedEvents![1].midiEvent, event2);
      expect(player.locatedEvents![1].absoluteMs, closeTo(750, 0.01));
    });

    test('two_located_events_with_tempo_no_change', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);

      final player = MidiFilePlayer(file);

      MidiEvent event = TempoEvent.bpm(120);
      track.addEvent(240, event);
      MidiEvent event2 = NoteOnEvent(1, 43, 127);
      track.addEvent(120, event2);
      file.ppq = 240;

      expect(player.locatedEvents!.length, 2);
      expect(player.locatedEvents!.first.midiEvent, event);
      expect(player.locatedEvents!.first.absoluteMs, closeTo(500, 0.01));
      expect(player.locatedEvents![1].midiEvent, event2);
      expect(player.locatedEvents![1].absoluteMs, closeTo(750, 0.01));
    });

    test('two_located_events_with_tempo_change', () {
      final file = MidiFile();
      final track = MidiTrack();
      file.addTrack(track);

      final player = MidiFilePlayer(file);
      MidiEvent event1 = TempoEvent.bpm(120);
      track.addEvent(0, event1);

      // twice the speed
      var event2 = TempoEvent.bpm(240);
      track.addEvent(240, event2);
      MidiEvent event3 = NoteOnEvent(1, 43, 127);
      track.addEvent(240, event3);
      //file.ppq = 240;

      expect(player.locatedEvents!.length, 3);
      expect(player.locatedEvents![0].midiEvent, event1);
      expect(player.locatedEvents![0].absoluteMs, closeTo(0, 0.01));
      expect(player.locatedEvents![1].midiEvent, event2);
      expect(player.locatedEvents![1].absoluteMs, closeTo(1000, 0.01));
      expect(player.locatedEvents![2].midiEvent, event3);
      expect(player.locatedEvents![2].absoluteMs, closeTo(1500, 0.01));
    });

    test('2 tracks located event', () {
      final file = MidiFile();
      final player = MidiFilePlayer(file);

      final track1 = MidiTrack();
      file.addTrack(track1);
      final track2 = MidiTrack();
      file.addTrack(track2);

      MidiEvent event1 = NoteOnEvent(1, 42, 127);
      track1.addEvent(0, event1);

      MidiEvent event2 = NoteOnEvent(2, 43, 127);
      track2.addEvent(120, event2);

      MidiEvent event3 = NoteOnEvent(1, 44, 127);
      track1.addEvent(240, event3);

      expect(player.locatedEvents!.length, 3);
      expect(player.locatedEvents!.first.midiEvent, event1);
      expect(player.locatedEvents!.first.absoluteMs, 0);
      expect(player.locatedEvents![1].midiEvent, event2);
      expect(player.locatedEvents![1].absoluteMs, closeTo(500, 0.01));
      expect(player.locatedEvents![2].midiEvent, event3);
      expect(player.locatedEvents![2].absoluteMs, closeTo(1000, 0.01));
    });

    test('two_tracks_bmp_change', () {
      final file = MidiFile();
      final track1 = MidiTrack();
      final track2 = MidiTrack();
      file.addTrack(track1);
      file.addTrack(track2);

      final player = MidiFilePlayer(file);
      //player.tempoBpm = 120;
      // 1 quarter note is 500 ms
      MidiEvent event1 = TempoEvent.bpm(120);
      track1.addEvent(0, event1);
      MidiEvent event2 = NoteOnEvent(1, 43, 127);
      track1.addEvent(120, event2);
      MidiEvent event3 = NoteOnEvent(1, 44, 127);
      track1.addEvent(240, event3);
      // twice the speed
      var event4 = TempoEvent.bpm(240);
      track2.addEvent(240, event4);
      MidiEvent event5 = NoteOnEvent(2, 45, 127);
      track2.addEvent(480, event5);
      //file.ppq = 240;

      expect(player.locatedEvents!.length, 5);
      expect(player.locatedEvents![0].midiEvent, event1);
      expect(player.locatedEvents![0].absoluteMs, closeTo(0, 0.01));
      expect(player.locatedEvents![1].midiEvent, event2);
      expect(player.locatedEvents![1].absoluteMs, closeTo(500, 0.01));
      expect(player.locatedEvents![2].midiEvent, event4);
      expect(player.locatedEvents![2].absoluteMs, closeTo(1000, 0.01));
      expect(player.locatedEvents![3].midiEvent, event3);
      expect(player.locatedEvents![3].absoluteMs, closeTo(1250, 0.01));
      expect(player.locatedEvents![4].midiEvent, event5);
      expect(player.locatedEvents![4].absoluteMs, closeTo(2000, 0.01));
    });
  });
}

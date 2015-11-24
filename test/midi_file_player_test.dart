library midi_player_test;

import 'test_common.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/demo_file.dart';
import 'package:tekartik_midi/midi_file_player.dart';

main() {
  group('midi_file_player', () {
    test('ppq delta time to millis', () {
      MidiFile file = new MidiFile();
      file.ppq = 240;
      MidiFilePlayer player = new MidiFilePlayer(file);

      expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));
    });

    test('timestamp to absolute ms', () {
      MidiFile file = new MidiFile();
      MidiFilePlayer player = new MidiFilePlayer(file);
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
      MidiFile file = new MidiFile();
      MidiFilePlayer player = new MidiFilePlayer(file);
      file.ppq = 240;
      expect(player.tempoBpm, closeTo(120, 0.001));
      expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));

      player.setSpeedRatio(0.5);
      expect(player.tempoBpm, closeTo(120, 0.001));
      expect(player.currentDeltaTimeUnitInMillis, closeTo(1000 / 480, 0.0001));
    });

    test('smtp delta time to millis', () {
      MidiFile file = new MidiFile();
      file.setFrameDivision(25, 40);
      MidiFilePlayer player = new MidiFilePlayer(file);

      expect(player.currentDeltaTimeUnitInMillis, closeTo(.5, 0.0001));

      player.setSpeedRatio(0.5);
      expect(player.tempoBpm, closeTo(120, 0.001));
      expect(player.currentDeltaTimeUnitInMillis, closeTo(.5, 0.0001));
    });

    test('get next event simple', () {
      MidiFile file = new MidiFile();
      MidiFilePlayer player = new MidiFilePlayer(file);
      file.ppq = 240;

      player.start(0);
      expect(player.next, isNull);

      MidiTrack track = new MidiTrack();
      file.addTrack(track);

      player.start(0);
      expect(player.next, isNull);

      MidiEvent event = new NoteOnEvent(1, 42, 127);
      track.addEvent(0, event);

      player.start(0);
      PlayableEvent readEvent = player.next;
      expect(readEvent.midiEvent, event);
      expect(readEvent.timestamp, 0);
      expect(player.next, isNull);

      MidiEvent event2 = new NoteOffEvent(1, 42, 127);
      track.addEvent(240, event2);

      player.start(0);
      readEvent = player.next;
      expect(readEvent.midiEvent, event);
      expect(readEvent.timestamp, 0);
      readEvent = player.next;
      expect(readEvent.midiEvent, event2);
      expect(readEvent.timestamp, closeTo(500, 0.001));
      expect(player.next, isNull);
    });

    test('get next event 2 tracks', () {
      MidiFile file = new MidiFile();
      MidiFilePlayer player = new MidiFilePlayer(file);
      file.ppq = 240;

      MidiTrack track1 = new MidiTrack();
      file.addTrack(track1);
      MidiTrack track2 = new MidiTrack();
      file.addTrack(track2);

      player.start(0);
      expect(player.next, isNull);

      MidiEvent event1 = new NoteOnEvent(1, 42, 127);
      track1.addEvent(0, event1);

      MidiEvent event2 = new NoteOnEvent(1, 43, 127);
      track2.addEvent(120, event2);

      MidiEvent event3 = new NoteOnEvent(1, 44, 127);
      track1.addEvent(240, event3);

      player.start(0);
      PlayableEvent readEvent = player.next;
      expect(readEvent.midiEvent, event1);
      expect(readEvent.timestamp, 0);
      readEvent = player.next;
      expect(readEvent.midiEvent, event2);
      expect(readEvent.timestamp, closeTo(250, 0.001));
      readEvent = player.next;
      expect(readEvent.midiEvent, event3);
      expect(readEvent.timestamp, closeTo(500, 0.001));
      expect(player.next, isNull);
    });

    test('get next change tempo', () {
      MidiFile file = new MidiFile();
      MidiTrack track = new MidiTrack();
      file.addTrack(track);

      MidiFilePlayer player = new MidiFilePlayer(file);
      file.ppq = 240;

      MidiEvent event = new NoteOnEvent(1, 42, 127);
      track.addEvent(240, event);

      player.start(0);
      player.setSpeedRatio(.5, 250);
      PlayableEvent readEvent = player.next;
      expect(readEvent.midiEvent, event);
      expect(readEvent.timestamp, closeTo(750, 0.001));
      expect(player.next, isNull);
    });

    test('pause/resume', () {
      MidiFile file = new MidiFile();
      MidiTrack track = new MidiTrack();
      file.addTrack(track);
      MidiEvent event = new NoteOnEvent(1, 42, 127);
      track.addEvent(0, event);

      MidiFilePlayer player = new MidiFilePlayer(file);
      file.ppq = 240;

      player.start(0);

      player.pause(1);
      expect(player.next, isNull);

      player.resume(2);
      PlayableEvent readEvent = player.next;
      List<PlayableEvent> noteOnEvents = player.currentNoteOnEvents.toList();

      expect(noteOnEvents.length, 1);
      expect(noteOnEvents[0], readEvent);
    });

    test('load', () {
      MidiFile file = getDemoFileCDE();
      MidiFilePlayer player = new MidiFilePlayer(file);
      player.start(1);
      //player.pause();
    });

    test('get duration', () {
      MidiFile file = new MidiFile();
      MidiTrack track = new MidiTrack();
      file.addTrack(track);
      MidiEvent event = new NoteOnEvent(1, 42, 127);
      // add twice
      track.addEvent(240, event);
      file.ppq = 240;

      expect(getMidiFileDuration(file), new Duration(milliseconds: 501));
      expect(new MidiFilePlayer(file).totalDurationMs,
          closeTo(getMidiFileDuration(file).inMilliseconds, 1));

      track.addEvent(240, event);
      expect(getMidiFileDuration(file), new Duration(milliseconds: 1001));
      expect(new MidiFilePlayer(file).totalDurationMs,
          closeTo(getMidiFileDuration(file).inMilliseconds, 1));
    });

    test('one_located_events', () {
      MidiFile file = new MidiFile();
      MidiTrack track = new MidiTrack();
      file.addTrack(track);

      MidiFilePlayer player = new MidiFilePlayer(file);

      MidiEvent event = new NoteOnEvent(1, 42, 127);
      track.addEvent(240, event);

      //devPrint(player.locatedEvents);
      expect(player.locatedEvents.length, 1);
      expect(player.locatedEvents.first.midiEvent, event);
      expect(player.locatedEvents.first.absoluteMs, closeTo(1000, 0.01));
    });

    test('two_located_events', () {
      MidiFile file = new MidiFile();
      MidiTrack track = new MidiTrack();
      file.addTrack(track);

      MidiFilePlayer player = new MidiFilePlayer(file);

      MidiEvent event = new NoteOnEvent(1, 42, 127);
      track.addEvent(240, event);
      MidiEvent event2 = new NoteOnEvent(1, 43, 127);
      track.addEvent(120, event2);
      file.ppq = 240;

      //devPrint(player.locatedEvents);
      expect(player.locatedEvents.length, 2);
      expect(player.locatedEvents.first.midiEvent, event);
      expect(player.locatedEvents.first.absoluteMs, closeTo(500, 0.01));
      expect(player.locatedEvents[1].midiEvent, event2);
      expect(player.locatedEvents[1].absoluteMs, closeTo(750, 0.01));
    });

    test('2 tracks located event', () {
      MidiFile file = new MidiFile();
      MidiFilePlayer player = new MidiFilePlayer(file);

      MidiTrack track1 = new MidiTrack();
      file.addTrack(track1);
      MidiTrack track2 = new MidiTrack();
      file.addTrack(track2);

      MidiEvent event1 = new NoteOnEvent(1, 42, 127);
      track1.addEvent(0, event1);

      MidiEvent event2 = new NoteOnEvent(2, 43, 127);
      track2.addEvent(120, event2);

      MidiEvent event3 = new NoteOnEvent(1, 44, 127);
      track1.addEvent(240, event3);

      expect(player.locatedEvents.length, 3);
      expect(player.locatedEvents.first.midiEvent, event1);
      expect(player.locatedEvents.first.absoluteMs, 0);
      expect(player.locatedEvents[1].midiEvent, event2);
      expect(player.locatedEvents[1].absoluteMs, closeTo(500, 0.01));
      expect(player.locatedEvents[2].midiEvent, event3);
      expect(player.locatedEvents[2].absoluteMs, closeTo(1000, 0.01));
    });
  });
}

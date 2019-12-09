library player_base_test;

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';
import 'package:tekartik_midi/midi_player_base.dart';

import 'demo_file.dart';
import 'test_common.dart';

class _TestMidiPlayer extends MidiPlayerBase {
  @override
  num nowToTimestamp([num now]) {
    now ??= this.now;

    return now;
  }

  @override
  void rawPlayEvent(PlayableEvent event) {
    //print(event);
  }

  @override
  num now;

  _TestMidiPlayer(this.now, num noteOnLastTimestamp)
      : super(noteOnLastTimestamp);
}

void main() {
  group('player_base', () {
    test('note_on_key', () {
      var key = NoteOnKey(0, 0);
      expect(key, key);
      expect(key, NoteOnKey(0, 0));
      expect(key, isNot(NoteOnKey(0, 1)));
      expect(key, isNot(NoteOnKey(1, 0)));
      key = NoteOnKey(1, 1);
      expect(key, NoteOnKey(1, 1));
      expect(key, isNot(NoteOnKey(2, 1)));
      expect(key, isNot(NoteOnKey(1, 2)));
    });
    test('play event keys', () {
      MidiPlayerBase player = _TestMidiPlayer(0, null);
      expect(player.noteOnKeys.isEmpty, isTrue);
      expect(player.noteOnLastTimestamp, null);
      player.playEvent(PlayableEvent(2, NoteOffEvent(1, 1, 1)));
      expect(player.noteOnKeys.isEmpty, isTrue);
      expect(player.noteOnLastTimestamp, null);
      player.playEvent(PlayableEvent(2, NoteOnEvent(1, 2, 1)));
      expect(player.noteOnKeys.length, 1);
      expect(player.noteOnKeys.first, NoteOnKey(1, 2));
      expect(player.noteOnLastTimestamp, 2);
      player.playEvent(PlayableEvent(3, NoteOnEvent(1, 2, 1)));
      expect(player.noteOnKeys.length, 1);
      expect(player.noteOnKeys.first, NoteOnKey(1, 2));
      expect(player.noteOnLastTimestamp, 3);
      player.playEvent(PlayableEvent(4, NoteOnEvent(1, 3, 1)));
      expect(player.noteOnKeys.length, 2);
      expect(player.noteOnKeys.first, NoteOnKey(1, 2));
      expect(player.noteOnKeys.last, NoteOnKey(1, 3));
      expect(player.noteOnLastTimestamp, 4);
      player.pause();
    });

    test('now', () {
      MidiPlayerBase player = _TestMidiPlayer(4, 1);
      expect(player.now, 4); // ?
    });

    test('noteOnLastTimestamp', () {
      MidiPlayerBase player = _TestMidiPlayer(10, null);
      expect(player.noteOnLastTimestamp, null);
//      return player.load(getDemoFileCDE()).then((_) {
//        //player.resume();
//      });
    });

    test('status_play', () {
      final player = _TestMidiPlayer(10, null);
      expect(player.noteOnLastTimestamp, null);
      expect(player.isPlaying, false);
      expect(player.isPaused, false);
      expect(player.isDone, false);
      expect(player.done, null);
      player.load(getDemoFileCDE());
      expect(player.isPlaying, false);
      expect(player.isPaused, false);
      expect(player.isDone, false);
      expect(player.done, isNot(null));
      player.resume();
      expect(player.isPlaying, true);
      expect(player.isPaused, false);
      expect(player.isDone, false);
// Forward enough
      player.now = 5000;
      return player.done.then((_) {
        expect(player.isPlaying, false);
        expect(player.isPaused, false);
        expect(player.isDone, true);
        //return new Future.delayed(new Duration(milliseconds: 1000));
      });
    });

    test('status_pause', () {
      final player = _TestMidiPlayer(10, null);
      expect(player.noteOnLastTimestamp, null);
      expect(player.isPlaying, false);
      expect(player.isPaused, false);
      expect(player.isDone, false);
      expect(player.done, null);
      player.load(getDemoFileCDE());
      expect(player.isPlaying, false);
      expect(player.isPaused, false);
      expect(player.isDone, false);
      expect(player.done, isNot(null));
      player.resume();
      expect(player.isPlaying, true);
      expect(player.isPaused, false);
      expect(player.isDone, false);
      player.pause();
      expect(player.isPlaying, false);
      expect(player.isPaused, true);
      expect(player.isDone, false);
      player.resume();
      // Forward enough
      player.now = 5000;
      return player.done.then((_) {
        expect(player.isPlaying, false);
        expect(player.isPaused, false);
        expect(player.isDone, true);
      });
    });
  });
}

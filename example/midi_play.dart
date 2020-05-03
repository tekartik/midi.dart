#!/usr/bin/env dart

library midi_dump;

import 'dart:io';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_player_base.dart';
import 'package:tekartik_midi/midi_file_player.dart';

// Display midi event timing

class _MidiPlayer extends MidiPlayerBase {
  @override
  void rawPlayEvent(PlayableEvent event) {
    print(event);
  }

  Stopwatch stopwatch;

  @override
  num get now {
    // make the first call 0
    if (stopwatch == null) {
      stopwatch = Stopwatch();
      stopwatch.start();
    }
    return stopwatch.elapsed.inMilliseconds;
  }

  _MidiPlayer([num noteOnLastTimestamp]) : super(noteOnLastTimestamp);
}

Future main(List<String> args) async {
  args.forEach((String arg) async {
    final file = File(arg);
    if (file.existsSync()) {
      // parse data
      List<int> data = file.readAsBytesSync();
      final parser = FileParser(MidiParser(data));
      parser.parseFile();

      final player = _MidiPlayer();
      player.load(parser.file);
      player.resume();

      await player.done;
    }
  });
}

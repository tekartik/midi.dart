#!/usr/bin/env dart

library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_midi/midi_file_player.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_player_base.dart';

// Display midi event timing

class StdoutMidiPlayer extends MidiPlayerBase {
  @override
  void rawPlayEvent(PlayableEvent event) {
    // ignore: avoid_print
    print(event);
  }

  Stopwatch? stopwatch;

  @override
  num get now {
    // make the first call 0
    if (stopwatch == null) {
      stopwatch = Stopwatch();
      stopwatch!.start();
    }
    return stopwatch!.elapsed.inMilliseconds;
  }

  StdoutMidiPlayer() : super(null);
}

Future main(List<String> args) async {
  if (args.isEmpty) {
    args = [join('example', 'sample.mid')];
  }
  for (var arg in args) {
    final file = File(arg);
    if (file.existsSync()) {
      // parse data
      List<int> data = file.readAsBytesSync();
      final parser = FileParser(MidiParser(data));
      parser.parseFile();

      final player = StdoutMidiPlayer();
      player.load(parser.file!);
      player.resume();

      await player.done;
    }
  }
}

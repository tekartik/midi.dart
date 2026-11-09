// ignore_for_file: avoid_print

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';

/// Create a midi file, write it to bytes, parse it back, print its notes and
/// its duration. Pure Dart: runs on the VM, Flutter and the web.
void main() {
  // A file: 240 ticks per quarter note, one track.
  var file = MidiFile()..ppq = 240;
  var track = MidiTrack()
    ..addEvent(0, TrackNameEvent(data: 'demo'.codeUnits))
    ..addEvent(0, TimeSigEvent.topBottom(4, 4))
    ..addEvent(0, TempoEvent.bpm(120))
    ..addEvent(0, ProgramChangeEvent(0, 0)) // channel 0, piano
    ..addEvent(0, NoteOnEvent(0, 60, 100)) // middle C
    ..addEvent(240, NoteOffEvent(0, 60, 0)) // a quarter note later
    ..addEvent(0, NoteOnEvent(0, 64, 100))
    ..addEvent(240, NoteOffEvent(0, 64, 0))
    ..addEvent(0, NoteOnEvent(0, 67, 100))
    ..addEvent(480, NoteOffEvent(0, 67, 0)) // a half note
    ..addEvent(0, EndOfTrackEvent());
  file.addTrack(track);

  // To bytes (what a .mid file holds) and back.
  var bytes = FileWriter.fileData(file);
  print('${bytes.length} bytes');
  MidiFile parsed;
  try {
    parsed = FileParser.dataFile(bytes)!;
  } on FormatException catch (e) {
    print('not a midi file: $e');
    return;
  }

  for (var track in parsed.tracks) {
    var ticks = 0;
    for (var trackEvent in track.events) {
      ticks += trackEvent.deltaTime;
      var event = trackEvent.midiEvent;
      if (event is NoteOnEvent && event.velocity > 0) {
        print('tick $ticks: note on ${event.note}');
      }
    }
  }
  // 4 quarter notes at 120 bpm: 2 seconds (rounded up to the ms).
  print('duration ${getMidiFileDuration(parsed)}');
}

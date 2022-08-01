import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

Future<void> main() async {
  // Create the midi file
  var midiFile = getDemoFileCDE();
  // Get the data
  final data = FileWriter.fileData(midiFile);
  // Write the fie
  var outIoFile = join('.local', 'cde.mid');
  await Directory(dirname(outIoFile)).create(recursive: true);
  await File(outIoFile).writeAsBytes(data);
}

MidiFile getDemoFileCDE() {
  final file = MidiFile();
  file.fileFormat = MidiFile.formatMultiTrack;
  file.ppq = 240;

  var track = MidiTrack();
  track.addEvent(0, TimeSigEvent(4, 4));
  track.addEvent(0, TempoEvent.bpm(120));
  track.addEvent(0, EndOfTrackEvent());
  file.addTrack(track);

  track = MidiTrack();
  track.addEvent(0, ProgramChangeEvent(1, 25));
  track.addEvent(0, NoteOnEvent(1, 42, 127));
  track.addEvent(240, NoteOffEvent(1, 42, 127));
  track.addEvent(240, NoteOnEvent(1, 44, 127));
  track.addEvent(240, NoteOnEvent(1, 46, 127));

  track.addEvent(0, NoteOffEvent(1, 44, 127));
  track.addEvent(480, NoteOffEvent(1, 46, 127));
  track.addEvent(0, EndOfTrackEvent());

  file.addTrack(track);

  return file;
}

import 'dart:io';

import 'package:tekartik_midi/midi_writer.dart';

import 'midi.dart';
import 'midi_parser.dart';

/// Read a midi file
Future<MidiFile> ioReadMidiFile(String path) async {
  var data = await File(path).readAsBytes();
  final fileRead = FileParser.dataFile(data)!;
  return fileRead;
}

/// Write a midi file
Future<void> ioWriteMidiFile(String path, MidiFile midiFile) async {
  var data = FileWriter.fileData(midiFile);
  await File(path).writeAsBytes(data);
}

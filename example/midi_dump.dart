#!/usr/bin/env dart

library;

import 'dart:io';

import 'package:tekartik_midi/midi_parser.dart';

// Dump midi files info and events
void main(List<String> args) {
  for (var arg in args) {
    final file = File(arg);
    if (file.existsSync()) {
      List<int> data = file.readAsBytesSync();
      final parser = FileParser(MidiParser(data));
      parser.parseFile();
      parser.file!.dump();
    }
  }
}

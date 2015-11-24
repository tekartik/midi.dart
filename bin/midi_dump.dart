#!/usr/bin/env dart
library midi_dump;

import 'dart:io';
import 'package:tekartik_midi/midi_parser.dart';

void main(List<String> args) {
  args.forEach((String arg) {
    File file = new File(arg);
    if (file.existsSync()) {
      List<int> data = file.readAsBytesSync();
      FileParser parser = new FileParser(new MidiParser(data));
      parser.parseFile();
      parser.file.dump();
    }
  });
}

library midi_demo_file;

import 'package:tekartik_midi/midi.dart';

MidiFile getDemoFileCDE() {
  MidiFile file = MidiFile();
  file.fileFormat = MidiFile.formatMultiTrack;
  file.ppq = 240;

  MidiTrack track = MidiTrack();
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
  // track.add(new Event.NoteOn(0, 1, 42, 127));
  // track.add(new Event.NoteOff(480, 1, 42, 127));
  // // track.add(new Event.NoteOn(0, 1, 42, 127));
  // track.add(new Event.NoteOff(120, 1, 42, 127));
  track.addEvent(0, EndOfTrackEvent());

  file.addTrack(track);

  return file;
}

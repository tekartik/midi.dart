library midi_demo_file;

import 'midi.dart';

MidiFile getDemoFileCDE() {
  MidiFile file = new MidiFile();
  file.fileFormat = MidiFile.FORMAT_MULTI_TRACK;
  file.ppq = 240;

  MidiTrack track = new MidiTrack();
  track.addEvent(0, new TimeSigEvent(4, 4));
  track.addEvent(0, new TempoEvent.bpm(120));
  track.addEvent(0, new EndOfTrackEvent());
  file.addTrack(track);

  track = new MidiTrack();
  track.addEvent(0, new ProgramChangeEvent(1, 25));
  track.addEvent(0, new NoteOnEvent(1, 42, 127));
  track.addEvent(240, new NoteOffEvent(1, 42, 127));
  track.addEvent(240, new NoteOnEvent(1, 44, 127));
  track.addEvent(240, new NoteOnEvent(1, 46, 127));

  track.addEvent(0, new NoteOffEvent(1, 44, 127));
  track.addEvent(480, new NoteOffEvent(1, 46, 127));
  // track.add(new Event.NoteOn(0, 1, 42, 127));
  // track.add(new Event.NoteOff(480, 1, 42, 127));
  // // track.add(new Event.NoteOn(0, 1, 42, 127));
  // track.add(new Event.NoteOff(120, 1, 42, 127));
  track.addEvent(0, new EndOfTrackEvent());

  file.addTrack(track);

  return file;
}

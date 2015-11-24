part of midi_writer;

class EventWriter extends ObjectWriter {
  EventWriter(MidiWriter midiWriter) : super(midiWriter);

  TrackEvent event;

  void writeEvent() {
    writeVariableLengthData(event.deltaTime);
    writeUint8(event.midiEvent.command);
    event.midiEvent.writeData(midiWriter);
  }

  void writeMidiEvent(MidiEvent midiEvent) {
    writeUint8(midiEvent.command);
    midiEvent.writeData(midiWriter);
  }
}

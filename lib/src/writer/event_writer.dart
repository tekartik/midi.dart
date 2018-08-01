import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

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

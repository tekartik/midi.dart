import 'dart:typed_data';

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

/// Event writer
class EventWriter extends ObjectWriter {
  /// Constructor
  EventWriter(super.midiWriter);

  /// The track event
  late TrackEvent event;

  /// Write the event
  void writeEvent() {
    writeVariableLengthData(event.deltaTime);
    writeUint8(event.midiEvent.command);
    event.midiEvent.writeData(midiWriter);
  }

  /// Write a midi event
  void writeMidiEvent(MidiEvent midiEvent) {
    writeUint8(midiEvent.command);
    midiEvent.writeData(midiWriter);
  }

  /// Events to bytes
  static Uint8List midiEventToBytes(MidiEvent midiEvent) {
    final writer = MidiWriter();
    final tmpEventWriter = EventWriter(writer);
    tmpEventWriter.writeMidiEvent(midiEvent);
    return Uint8List.fromList(writer.data);
  }
}

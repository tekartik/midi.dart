import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

class TrackWriter extends ObjectWriter {
  TrackWriter(MidiWriter midiWriter) : super(midiWriter);

  late MidiTrack track;

  static final List<int> trackHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'r'.codeUnitAt(0),
    'k'.codeUnitAt(0)
  ];

  void _writeHeader(int trackSize) {
    writeBuffer(trackHeader);
    writeUint32(trackSize);
  }

  void writeTrack([MidiTrack? midiTrack]) {
    if (midiTrack != null) {
      track = midiTrack;
    }

    var trackSize = 0;
    final eventWriter = EventWriter(midiWriter);

    // We'll update header later
    final headerStartPosition = data.length;
    _writeHeader(0);
    final eventsStartPosition = data.length;
    for (var event in track.events) {
      eventWriter.event = event;
      eventWriter.writeEvent();
    }

    trackSize = data.length - eventsStartPosition;
    final tmp = MidiWriter();
    tmp.writeUint32(trackSize);

    // copy size
    for (var i = 0; i < 4; i++) {
      data[headerStartPosition + 4 + i] = tmp.data[i];
    }
  }
}

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

class TrackWriter extends ObjectWriter {
  TrackWriter(MidiWriter midiWriter) : super(midiWriter);

  MidiTrack track;

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

  void writeTrack([MidiTrack _track]) {
    if (_track != null) {
      this.track = _track;
    }

    int trackSize = 0;
    EventWriter eventWriter = EventWriter(midiWriter);

    // We'll update header later
    int headerStartPosition = data.length;
    _writeHeader(0);
    int eventsStartPosition = data.length;
    track.events.forEach((TrackEvent event) {
      eventWriter.event = event;
      eventWriter.writeEvent();
    });

    trackSize = data.length - eventsStartPosition;
    MidiWriter tmp = MidiWriter();
    tmp.writeUint32(trackSize);

    // copy size
    for (int i = 0; i < 4; i++) {
      data[headerStartPosition + 4 + i] = tmp.data[i];
    }
  }
}

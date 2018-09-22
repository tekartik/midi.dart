import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/parser/event_parser.dart';
import 'package:tekartik_midi/src/parser/object_parser.dart';

class TrackParser extends ObjectParser {
  TrackParser(MidiParser parser) : super(parser);

  MidiTrack track;
  int trackSize;

  int endPosition;

  static final List<int> trackHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'r'.codeUnitAt(0),
    'k'.codeUnitAt(0)
  ];

  void parseHeader() {
    midiParser.readBuffer(4);
    if (!buffer.equalsList(trackHeader)) {
      throw FormatException("Bad track header");
    }
    track = MidiTrack();
    trackSize = midiParser.readUint32();

    endPosition = midiParser.inBuffer.position + trackSize;
  }

  void parseEvents() {
    EventParser eventParser = EventParser(midiParser);
    while (midiParser.inBuffer.position < endPosition) {
      eventParser.parseEvent();
      //print(eventParser.event);
//      if (eventParser.event is EndOfTrackEvent) {
//      print(eventParser.event);
//      }
      track.events.add(TrackEvent(eventParser.deltaTime, eventParser.event));
    }
    ;
  }

  MidiTrack parseTrack() {
    parseHeader();
    parseEvents();
    return track;
  }
}

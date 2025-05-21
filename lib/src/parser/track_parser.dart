import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/parser/object_parser.dart';

/// Parser for a track
class TrackParser extends ObjectParser {
  /// Constructor
  TrackParser(super.parser);

  /// The track being parsed
  MidiTrack? track;

  /// The size of the track
  int? trackSize;

  /// The end position
  late int endPosition;

  /// The track header
  static final List<int> trackHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'r'.codeUnitAt(0),
    'k'.codeUnitAt(0),
  ];

  /// Parse the header
  void parseHeader() {
    midiParser.readBuffer(4);
    if (!buffer.equalsList(trackHeader)) {
      throw const FormatException('Bad track header');
    }
    track = MidiTrack();
    trackSize = midiParser.readUint32();

    endPosition = midiParser.inBuffer!.position + trackSize!;
  }

  /// Parse the events
  void parseEvents() {
    final eventParser = EventParser(midiParser);
    while (midiParser.inBuffer!.position < endPosition) {
      eventParser.parseEvent();
      //print(eventParser.event);
      //      if (eventParser.event is EndOfTrackEvent) {
      //      print(eventParser.event);
      //      }
      track!.events.add(TrackEvent(eventParser.deltaTime, eventParser.event));
    }
  }

  /// Parse the track
  MidiTrack parseTrack() {
    parseHeader();
    parseEvents();
    return track!;
  }
}

part of midi_parser;

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
    _midiParser.readBuffer(4);
    if (!buffer.equalsList(trackHeader)) {
      throw new FormatException("Bad track header");
    }
    track = new MidiTrack();
    trackSize = _midiParser.readUint32();

    endPosition = _midiParser.inBuffer.position + trackSize;
  }

  void parseEvents() {
    EventParser eventParser = new EventParser(_midiParser);
    while (_midiParser.inBuffer.position < endPosition) {
      eventParser.parseEvent();
      //print(eventParser.event);
//      if (eventParser.event is EndOfTrackEvent) {
//      print(eventParser.event);
//      }
      track.events
          .add(new TrackEvent(eventParser.deltaTime, eventParser.event));
    }
    ;
  }

  MidiTrack parseTrack() {
    parseHeader();
    parseEvents();
    return track;
  }
}

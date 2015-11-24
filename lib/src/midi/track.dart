part of tekartik_midi;

class MidiTrack {
  List<TrackEvent> events = new List();

  @override
  int get hashCode {
    return events.length;
  }

  @override
  bool operator ==(var other) {
    if (other is MidiTrack) {
      return const ListEquality().equals(events, other.events);
    }
    return false;
  }

  void dump() {
    events.forEach((TrackEvent e) {
      print(e);
    });
  }

  @override
  String toString() {
    StringBuffer out = new StringBuffer();
    out.write('events ${events.length}');
    if (events.length > 0) {
      out.write(' ${events[0].toString()}');
    }
    return out.toString();
  }

  void addEvent(int deltaTime, MidiEvent midiEvent) {
    events.add(new TrackEvent(deltaTime, midiEvent));
  }
}

import 'package:collection/collection.dart';
import 'package:tekartik_midi/midi.dart';

class MidiTrack {
  List<TrackEvent> events = List();

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
    StringBuffer out = StringBuffer();
    out.write('events ${events.length}');
    if (events.length > 0) {
      out.write(' ${events[0].toString()}');
    }
    return out.toString();
  }

  void addEvent(int deltaTime, MidiEvent midiEvent) {
    events.add(TrackEvent(deltaTime, midiEvent));
  }

  void addAbsolutionEvent(int absoluteTime, MidiEvent midiEvent) {
    int time = 0;
    for (int i = 0; i < events.length; i++) {
      var event = events[i];
      int newTime = time + event.deltaTime;
      if (absoluteTime < newTime) {
        events.insert(i, TrackEvent(absoluteTime - time, midiEvent));
        return;
      }
      time = newTime;
    }
    events.add(TrackEvent(absoluteTime - time, midiEvent));
  }
}

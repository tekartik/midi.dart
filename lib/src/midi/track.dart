import 'package:collection/collection.dart';
import 'package:tekartik_midi/midi.dart';

class MidiTrack {
  List<TrackEvent> events = [];

  @override
  int get hashCode {
    return events.length;
  }

  @override
  bool operator ==(var other) {
    if (other is MidiTrack) {
      return const ListEquality<TrackEvent>().equals(events, other.events);
    }
    return false;
  }

  void dump({bool showDeltaTime = false}) {
    for (var e in events) {
      print(e);
    }
  }

  @override
  String toString() {
    final out = StringBuffer();
    out.write('events ${events.length}');
    if (events.isNotEmpty) {
      out.write(' ${events[0].toString()}');
    }
    return out.toString();
  }

  void addEvent(int deltaTime, MidiEvent midiEvent) {
    events.add(TrackEvent(deltaTime, midiEvent));
  }

  void addAbsolutionEvent(int absoluteTime, MidiEvent midiEvent) {
    var time = 0;
    for (var i = 0; i < events.length; i++) {
      var event = events[i];
      final newTime = time + event.deltaTime;
      if (absoluteTime < newTime) {
        events.insert(i, TrackEvent(absoluteTime - time, midiEvent));
        return;
      }
      time = newTime;
    }
    events.add(TrackEvent(absoluteTime - time, midiEvent));
  }
}

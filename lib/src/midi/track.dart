import 'package:collection/collection.dart';
import 'package:tekartik_midi/midi.dart';

/// A track event contains a list of events
class MidiTrack {
  /// List of events, do not modify directly
  List<TrackEvent> get events => _events;
  final _events = <TrackEvent>[];

  /// Get the time of an event at a given index
  /// It unfortunately requires to go through all events
  int absoluteTimeAt(int index) {
    var time = 0;
    for (var i = 0; i <= index; i++) {
      time += events[i].deltaTime;
    }
    return time;
  }

  /// Get the time difference between two events
  /// if (index1 <= index2) similarly to compare the result will be negative
  int absoluteTimeDiff(int index1, int index2) {
    if (index1 <= index2) {
      var time = 0;
      for (var i = index1 + 1; i <= index2; i++) {
        time -= events[i].deltaTime;
      }
      return time;
    }
    return -absoluteTimeDiff(index2, index1);
  }

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

  /// Debug dump events
  void dump() {
    for (var e in events) {
      // ignore: avoid_print
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

  /// Add an event
  void addEvent(int deltaTime, MidiEvent midiEvent) {
    events.add(TrackEvent(deltaTime, midiEvent));
  }

  /// Add an event at an absolute time
  /// return its index
  int addAbsolutionEvent(int absoluteTime, MidiEvent midiEvent) {
    var time = 0;
    for (var i = 0; i < events.length; i++) {
      var event = events[i];
      final newTime = time + event.deltaTime;
      if (absoluteTime < newTime) {
        events.insert(i, TrackEvent(absoluteTime - time, midiEvent));
        return i;
      }
      time = newTime;
    }
    events.add(TrackEvent(absoluteTime - time, midiEvent));
    return events.length - 1;
  }
}

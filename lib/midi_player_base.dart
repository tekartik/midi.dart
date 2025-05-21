library;

import 'dart:async';
import 'dart:math';

import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';

/// Base class for midi player
abstract class MidiPlayerBase {
  int? _fileIndex;

  /// True if the file matches the current file
  bool fileMatches(int fileIndex) {
    return _fileIndex == fileIndex;
  }

  MidiFilePlayer? _midiFilePlayer;

  //Stopwatch stopwatch;

  // True when play has started once already
  bool _isPaused = false;

  /// True when paused
  bool get isPaused => _isPaused;

  // True when play has started once already (true when paused)
  bool _isPlaying = false;

  /// True when playing
  bool get isPlaying => _isPlaying && !_isPaused;

  // True when done
  bool _isDone = false;

  /// True when done
  bool get isDone => _isDone;

  // null when not load yet
  Future? _done;

  /// Done future
  Future? get done => _done;

  // Created when playing
  // killed on pause
  Completer? _waitPlayNextCompleter;

  StreamController<PlayableEvent?>? _streamController;

  /// Send event when status change and every second
  StreamController<bool> playingController = StreamController();

  /// Stream of playing status
  Stream<bool>? playingStream;

  /// time to send the event before the real event occured
  final _preFillDuration = 200;
  final _timerResolution = 50;

  PlayableEvent? _currentEvent;

  // timestamp is relative to _startNow;
  //num _startNow;

  num? _nextRatio;

  num? _lastPauseTime;
  num _nowDelta = 0; // delta from now, pausing increases delta

  /// Current timestamp (milliseconds)
  num? get currentTimestamp =>
      isPlaying ? (isPaused ? _lastPauseTime : _nowTimestamp) : null;

  /// Current timestamp duration
  Duration? get currentTimestampDuration {
    final now = currentTimestamp;
    if (now != null) {
      return Duration(milliseconds: now.toInt());
    }
    return null;
  }

  /// estimation
  num nowToTimestamp([num? now]) {
    now ??= this.now;

    return now;
    //return now - startNow - _nowDelta; // - _preFillDuration - _preFillDuration;
  }

  /// Send sound off to all channel
  void allSoundOff() {
    for (var i = 0; i < MidiEvent.channelCount; i++) {
      final playableEvent = PlayableEvent(
        nowToTimestamp(),
        ControlChangeEvent.newAllSoundOffEvent(i),
      );
      playEvent(playableEvent);
    }
  }

  /// Send all notes off to all channel
  void allNotesOff() {
    for (var i = 0; i < MidiEvent.channelCount; i++) {
      final playableEvent = PlayableEvent(
        nowToTimestamp(),
        ControlChangeEvent.newAllSoundOffEvent(i),
      );
      playEvent(playableEvent);
    }
  }

  /// Send all reset to all channel
  void allReset() {
    for (var i = 0; i < MidiEvent.channelCount; i++) {
      final playableEvent = PlayableEvent(
        nowToTimestamp(),
        ControlChangeEvent.newAllResetEvent(i),
      );
      playEvent(playableEvent);
    }
  }

  /// Send panic to all channel
  void panic() {
    //allSoundOff();
    //allReset();

    for (var j = 0; j < MidiEvent.noteCount; j++) {
      for (var i = 0; i < MidiEvent.channelCount; i++) {
        final playableEvent = PlayableEvent(
          nowToTimestamp(),
          NoteOffEvent(i, j, 0),
        );
        playEvent(playableEvent);
      }
    }
  }

  // to override for MidiJs
  //void _prepareToPlay(MidiFile file) {}

  void _unload() {
    // unload the current file
    if (_streamController != null) {
      _streamController!.close();
    }
  }

  /// Pause playback
  void rawPause() {
    if (!isPaused) {
      _lastPauseTime = now;
      //stopwatch.stop();
      _isPaused = true;
      playingController.add(false);
    }

    //    if (_streamController != null) {
    //      _currentEvent = null;
    //      _streamController.close();
    //      _streamController = null;
    //      playingController.add(false);
    //    }
  }

  /// Resume playback
  void resume([num? time]) {
    final resumeTime = time ?? now;
    if (isPaused) {
      _nowDelta += resumeTime - _lastPauseTime!;
    }
    // TODO
    _midiFilePlayer!.resume(resumeTime);
    _isPlaying = true;
    _isPaused = false;
    //stopwatch.start();
    playingController.add(true);
    _currentEvent = _midiFilePlayer!.next;
    _playNext();
  }

  //  void _play(MidiFile file) {
  //    _load(file);
  //    //stopwatch = new Stopwatch()..start();
  //    _midiFilePlayer.start(0 - _preFillDuration);
  //
  //    if (_nextRatio != null) {
  //      _midiFilePlayer.setSpeedRatio(_nextRatio, now);
  //      _nextRatio = null;
  //    }
  //
  //    _startNow = now - _nowDelta;
  //    devPrint('Starting ${formatTimestampMs(_startNow)}');
  //    // Get first
  //    _currentEvent = _midiFilePlayer.next;
  //    _playNext();
  //  }

  /// Load a midi file
  void load(MidiFile file) {
    // Pause current
    pause();

    // unload existing
    _unload();

    //_prepareToPlay(file);
    //_nowDelta = 0;
    //isPaused = true;
    //_isPlaying = true;
    //playingController.add(true);
    //          Stream<PlayableEvent> stream = _play(file);
    //          stream..listen((PlayableEvent event) {
    //                playEvent(event);
    //              }, onDone: () {
    //                pause();
    //                print('onDone');
    //                player = null;
    //              });
    _load(file);

    //});
  }

  //  void play(MidiFile file) {
  //    load(file).then((_) {
  //      _play(file);
  //
  //    });
  //
  //  }

  //  num get startNow {
  //    if (_startNow == null) {
  //      _startNow = now;
  //    }
  //    return _startNow;
  //  }

  void _load(MidiFile file) {
    _isDone = false;
    _isPlaying = false;
    _isPaused = false;
    _midiFilePlayer = MidiFilePlayer(file);
    //_startNow = null;

    _streamController = StreamController<PlayableEvent?>(sync: true);

    _done = _streamController!.stream
        .listen(
          (PlayableEvent? event) {
            playEvent(event!);
          },
          onDone: () {
            //pause();
          },
        )
        .asFuture<void>()
        .then((_) {
          //devPrint('onDone');
          //_midiFilePlayer = null;
          _isDone = true;
          _isPlaying = false;
        });
  }

  //  void _play(MidiFile file) {
  //    _load(file);
  //    //stopwatch = new Stopwatch()..start();
  //    player.start(0 - _preFillDuration);
  //
  //    _startNow = now - _nowDelta;
  //    devPrint('Starting ${formatTimestampMs(_startNow)}');
  //    // Get first
  //    _currentEvent = player.next;
  //    _playNext();
  //  }

  /// Get the current speed ratio
  num? get currentSpeedRadio => _nextRatio; // ?

  /// Set the next speed ratio
  void setNextSpeedRadio(num ratio) {
    _nextRatio = ratio;
  }

  /// Set the speed ratio
  void setSpeedRadio(num ratio) {
    if (_midiFilePlayer == null) {
      _nextRatio = ratio;
    } else {
      _midiFilePlayer!.setSpeedRatio(ratio, now);
      //?
      _nextRatio = ratio;
    }
  }

  num get _nowTimestamp => nowToTimestamp();

  void _playNext() {
    if (_currentEvent == null || isPaused) {
      // Are we done
      if (!isPaused) {
        //TODO? Wait for all events to be played closing stream
        //int fileIndex = this._fileIndex;
        //new Future.
        _streamController!.close();
      } else {
        pause();
      }
    } else {
      final nowTimestamp = _nowTimestamp; //stopwatch.elapsedMilliseconds;

      if (_currentEvent!.timestamp < nowTimestamp) {
        //devPrint('## $now: $_currentEvent');
        _streamController!.add(_currentEvent);
        _currentEvent = _midiFilePlayer!.next;
        _playNext();
      } else {
        final nextCompleter = Completer<void>.sync();
        _waitPlayNextCompleter = nextCompleter;
        Future.delayed(
          Duration(
            milliseconds:
                (_currentEvent!.timestamp - nowTimestamp + _timerResolution)
                    .toInt(),
          ),
          () {
            if (!nextCompleter.isCompleted) {
              nextCompleter.complete();
            }
            _waitPlayNextCompleter = null;
          },
        );

        // This will be cancelled if _waitPlayNextCompleter has been complete with an error before
        nextCompleter.future.then(
          (_) {
            _playNext();
          },
          onError: (_) {
            //devPrint('was paused');
          },
        );
      }
    }
  }

  /// Convert an event timestamp to an output timestamp
  num eventTimestampToOutputTimestamp(PlayableEvent event) {
    //return event.timestamp + _startNow + _nowDelta + _preFillDuration + _preFillDuration;
    return event.timestamp + _nowDelta + _preFillDuration + _preFillDuration;
  }

  //  MidiFile _currentFile;
  //  MidiFile get currentFile => _currentFile;
  //  set currentFile(MidiFile currentFile_) {
  //    _currentFile = currentFile_;
  //    // to force duration recomputation
  //    _currentFileDuration = null;
  //    _currentFileDuration = null;
  //  }
  //  Duration _currentFileDuration;
  //  Duration get currentFileDuration {
  //    if (_currentFileDuration == null) {
  //      if (currentFile != null) {
  //        _currentFileDuration = getMidiFileDuration(currentFile);
  //      }
  //    }
  //    return _currentFileDuration;
  //  }

  /*

  num _currentFilePercent;

  // from 0 to 100
  num get currentFilePercent {

  }
  */

  /// In milliseconds
  num get now;

  /// Midi player base
  MidiPlayerBase(this.noteOnLastTimestamp);

  /// Note on keys
  final noteOnKeys = <NoteOnKey>{};

  /// Last note on timestamp
  num? noteOnLastTimestamp;

  /// to implement
  void rawPlayEvent(PlayableEvent midiEvent) {}

  /// must be overriden and called
  void playEvent(PlayableEvent event) {
    // first play it
    rawPlayEvent(event);

    final midiEvent = event.midiEvent;

    // And Note on event and remove note off event (and note on with velocity 0)
    if (midiEvent is NoteOnEvent) {
      final key = NoteOnKey(midiEvent.channel, midiEvent.note);

      // save last timestamp to queue note off afterwards on pause
      if (noteOnLastTimestamp == null ||
          event.timestamp > noteOnLastTimestamp!) {
        noteOnLastTimestamp = event.timestamp;
      }

      if (midiEvent.velocity! > 0) {
        noteOnKeys.add(key);
      } else {
        noteOnKeys.remove(key);
      }
    } else if (midiEvent is NoteOffEvent) {
      final key = NoteOnKey(midiEvent.channel, midiEvent.note);
      noteOnKeys.remove(key);
    }
  }

  /// Pause playback
  void pause() {
    if (isPlaying) {
      final nowTimestamp = nowToTimestamp();

      _midiFilePlayer!.pause(nowTimestamp);

      // Kill pending _playNext)
      if (_waitPlayNextCompleter != null) {
        _waitPlayNextCompleter!.completeError('paused');
        _waitPlayNextCompleter = null;
      }
      var timestamp = noteOnLastTimestamp;
      if (timestamp == null) {
        timestamp = nowTimestamp;
      } else {
        timestamp = max(nowToTimestamp(), timestamp);
      }
      //devPrint('###### $timestamp - ${nowToTimestamp()}/last: $noteOnLastTimestamp');
      // Clear the notes sent
      for (final key in noteOnKeys) {
        final event = PlayableEvent(
          timestamp,
          NoteOffEvent(key.channel, key.note, 0),
        );
        //devPrint(event);
        rawPlayEvent(event);
      }
      noteOnKeys.clear();

      // then pause
      rawPause();
    }
  }

  /// Get the total duration of the file
  num get totalDurationMs {
    return _midiFilePlayer!.totalDurationMs;
  }

  /// Get the current position in the file
  num get currentAbsoluteMs {
    if (!_isPlaying) {
      return 0;
    }
    return _midiFilePlayer!.timestampToAbsoluteMs(nowToTimestamp());
  }
}

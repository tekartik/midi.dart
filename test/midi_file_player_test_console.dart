library midi_player_test;

import 'package:test/test.dart';
import 'package:tekartik_midi/midi_file_player.dart';
import 'package:tekartik_midi/midi_parser.dart';

import 'io_test_common.dart';

void main() {
  // to skip
  group('midi_file_player_test_console', () {
    // to skip
    test('parse take 5', () {
      return File(inDataFilenamePath('tmp/take_5.mid'))
          .readAsBytes()
          .then((data) {
        final file = FileParser.dataFile(data)!;
        expect(file.trackCount, 30);

        expect(getMidiFileDuration(file),
            const Duration(minutes: 2, seconds: 26, milliseconds: 785));
        expect(
            Duration(
                milliseconds: MidiFilePlayer(file).totalDurationMs.round()),
            getMidiFileDuration(file));
      });
    });
  }, skip: true);
}

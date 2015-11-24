library tekartik_midi.io_test_common.dart;

import 'package:path/path.dart';

import 'dart:mirrors';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String inDataFilenamePath(String name) =>
    join(dirname(_TestUtils.scriptPath), "data", name);
String outDataFilenamePath(String name) =>
    join(dirname(_TestUtils.scriptPath), "data", "out", name);
String get outDataPath => join(dirname(_TestUtils.scriptPath), "data", "out");

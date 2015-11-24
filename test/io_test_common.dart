library tekartik_midi.io_test_common.dart;

import 'package:path/path.dart';
export 'test_common.dart';
import 'dart:mirrors';
export 'dart:io';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String inDataFilenamePath(String name) =>
    join(dirname(_TestUtils.scriptPath), "data", name);
String get outDataPath =>
    join(dirname(dirname(_TestUtils.scriptPath)), "test_out");
String outDataFilenamePath(String name) => join(outDataPath, name);

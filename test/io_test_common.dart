library tekartik_midi.io_test_common.dart;

import 'package:path/path.dart';
export 'test_common.dart';
export 'dart:io';

String inDataFilenamePath(String name) => join('test', "data", name);
String get outDataPath => join('.dart_tool', 'tekartik_midi', 'test');

String outDataFilenamePath(String name) => join(outDataPath, name);

import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Initializes sqlite3mc for sqflite FFI on desktop (main + worker isolates).
void desktopSqliteFfiInit() {
  if (Platform.isWindows) {
    _preloadWindowsCipherLibrary();
  }

  // Force sqlite3 native bindings to load in this isolate.
  sqlite3.openInMemory().close();
}

void _preloadWindowsCipherLibrary() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final candidates = <String>[
    p.join(exeDir, 'sqlite3mc.dll'),
    'sqlite3mc.dll',
  ];

  Object? lastError;
  for (final path in candidates) {
    try {
      DynamicLibrary.open(path);
      return;
    } catch (e) {
      lastError = e;
    }
  }

  throw StateError(
    'Could not load sqlite3mc.dll for SQLCipher. '
    'Looked in: ${candidates.join(", ")}. '
    'Last error: $lastError',
  );
}

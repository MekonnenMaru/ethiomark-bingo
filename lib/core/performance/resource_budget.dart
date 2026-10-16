import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/painting.dart';

/// Tunes batch sizes and load strategy for weak cashier PCs (2–4 GB RAM).
abstract final class ResourceBudget {
  static int? _totalRamMb;

  static int get totalRamMb => _totalRamMb ??= _readTotalRamMb() ?? 4096;

  /// True on PCs with about 6 GB RAM or less.
  static bool get lowMemory => totalRamMb <= 6144;

  /// Typical Ethiopian shop PC: 2-core CPU and/or 4 GB RAM.
  static bool get lowSpecPc =>
      lowMemory || Platform.numberOfProcessors <= 2;

  /// Skip confetti, bounce, and pulse animations on weak hardware.
  static bool get reduceAnimations => lowSpecPc;

  /// Prefer flat paints (no multi-layer shadows / gradients) on weak hardware.
  static bool get reduceDecorations => lowSpecPc;

  /// SQLite insert batch size during first-run cartela import.
  static int get importChunkSize {
    if (totalRamMb <= 3072) return 20;
    if (totalRamMb <= 6144) return 40;
    return 75;
  }

  /// Run screen DB calls one-by-one instead of all at once.
  static bool get sequentialScreenLoads => lowSpecPc;

  static void applyImageCacheLimits() {
    if (!lowSpecPc) return;
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 40;
    cache.maximumSizeBytes = 24 << 20;
  }

  static int? _readTotalRamMb() {
    if (!Platform.isWindows) return null;
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final globalMemoryStatusEx = kernel32.lookupFunction<
          Int32 Function(Pointer<MEMORYSTATUSEX>),
          int Function(Pointer<MEMORYSTATUSEX>)>('GlobalMemoryStatusEx');
      final status = calloc<MEMORYSTATUSEX>();
      status.ref.dwLength = sizeOf<MEMORYSTATUSEX>();
      final ok = globalMemoryStatusEx(status);
      if (ok == 0) {
        calloc.free(status);
        return null;
      }
      final mb = status.ref.ullTotalPhys ~/ (1024 * 1024);
      calloc.free(status);
      return mb;
    } catch (_) {
      return null;
    }
  }
}

final class MEMORYSTATUSEX extends Struct {
  @Uint32()
  external int dwLength;

  @Uint32()
  external int dwMemoryLoad;

  @Uint64()
  external int ullTotalPhys;

  @Uint64()
  external int ullAvailPhys;

  @Uint64()
  external int ullTotalPageFile;

  @Uint64()
  external int ullAvailPageFile;

  @Uint64()
  external int ullTotalVirtual;

  @Uint64()
  external int ullAvailVirtual;

  @Uint64()
  external int ullAvailExtendedVirtual;
}

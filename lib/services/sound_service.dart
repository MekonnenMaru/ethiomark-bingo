import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Plays number voices and game effect sounds from `assets/sounds/`.
///
/// Uses [flutter_soloud] (SoLoud) instead of Media Foundation / audioplayers on
/// Windows so the app runs on PCs without MFPlat.dll (e.g. Windows N).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Stable indices stored in DB — do not reorder keys (add new indices only).
  static const Map<int, String> voiceFoldersByIndex = {
    1: 'wedi',
    2: 'addis',
    3: 'foromifa',
    4: 'modern-arada',
    5: 'arada',
    6: 'bereket',
  };

  /// Fallback when SoLoud reports a zero/unknown clip length (slow PCs).
  static const Duration _minNumberDuration = Duration(milliseconds: 900);

  final SoLoud _soloud = SoLoud.instance;
  bool _initialized = false;

  SoundHandle? _numberHandle;

  /// Cached number WAVs keyed by `folder/number` so we do not reload every call.
  final Map<String, AudioSource> _numberSourceCache = {};

  SoundHandle? _effectHandle;
  AudioSource? _effectSource;
  AudioSource? _shuffleSource;

  /// Serializes number playback so slow machines never overlap load/play/stop.
  Future<void> _numberPlayChain = Future<void>.value();

  /// Anbesa-style bonus reel ticks (square wave).
  AudioSource? _bonusTickSource;
  SoundHandle? _bonusTickHandle;

  String folderForVoice(int soundIndex) {
    return voiceFoldersByIndex[soundIndex] ??
        voiceFoldersByIndex[5] ??
        'arada';
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _soloud.init();
    _initialized = true;
  }

  bool _isActive(SoundHandle? handle) {
    return handle != null && _soloud.getIsValidVoiceHandle(handle);
  }

  Future<void> _stopNumberHandle() async {
    if (_isActive(_numberHandle)) {
      await _soloud.stop(_numberHandle!);
    }
    _numberHandle = null;
  }

  Future<void> _disposeNumberCache() async {
    await _stopNumberHandle();
    final sources = _numberSourceCache.values.toList(growable: false);
    _numberSourceCache.clear();
    for (final source in sources) {
      try {
        await _soloud.disposeSource(source);
      } catch (_) {}
    }
  }

  Future<AudioSource> _loadNumberSource(String folder, int number) async {
    final key = '$folder/$number';
    final cached = _numberSourceCache[key];
    if (cached != null) return cached;

    final source = await _soloud.loadAsset(
      'assets/sounds/$folder/$number.wav',
      mode: LoadMode.memory,
    );
    _numberSourceCache[key] = source;
    return source;
  }

  int? _preloadingVoiceIndex;
  Future<void>? _preloadInFlight;

  /// Warm the cache for numbers 1–75 of [voiceIndex] so draw calls never hitch
  /// on first-time asset load (main fix for silent skips on slow PCs).
  Future<void> preloadVoiceNumbers(int voiceIndex) {
    if (_preloadingVoiceIndex == voiceIndex && _preloadInFlight != null) {
      return _preloadInFlight!;
    }

    _preloadingVoiceIndex = voiceIndex;
    final folder = folderForVoice(voiceIndex);
    final run = () async {
      await _ensureInitialized();
      for (var n = 1; n <= 75; n++) {
        if (_preloadingVoiceIndex != voiceIndex) return;
        if (_numberSourceCache.containsKey('$folder/$n')) continue;
        try {
          await _loadNumberSource(folder, n);
        } catch (_) {
          // Skip missing/corrupt clip; playNumber will retry later.
        }
      }
    }();

    _preloadInFlight = run.whenComplete(() {
      if (_preloadingVoiceIndex == voiceIndex) {
        _preloadInFlight = null;
      }
    });
    return _preloadInFlight!;
  }

  Future<void> _stopEffect() async {
    if (_isActive(_effectHandle)) {
      await _soloud.stop(_effectHandle!);
    }
    _effectHandle = null;
    if (_effectSource != null) {
      await _soloud.disposeSource(_effectSource!);
      _effectSource = null;
    }
    if (_shuffleSource != null) {
      await _soloud.disposeSource(_shuffleSource!);
      _shuffleSource = null;
    }
  }

  Future<void> _ensureBonusTickSource() async {
    await _ensureInitialized();
    _bonusTickSource ??=
        await _soloud.loadWaveform(WaveForm.square, false, 1, 0);
  }

  /// Anbesa `playTick` — short square beep used while lucky cards spin.
  Future<void> playBonusTick({
    double frequency = 720,
    double durationSec = 0.05,
  }) async {
    try {
      await _ensureBonusTickSource();
      final source = _bonusTickSource!;
      _soloud.setWaveformFreq(source, frequency.clamp(80, 4000));
      if (_isActive(_bonusTickHandle)) {
        await _soloud.stop(_bonusTickHandle!);
      }
      _bonusTickHandle = await _soloud.play(source, volume: 0.14);
      final fadeMs = (durationSec * 1000).round().clamp(20, 400);
      _soloud.fadeVolume(
        _bonusTickHandle!,
        0,
        Duration(milliseconds: fadeMs),
      );
      unawaited(
        Future<void>.delayed(Duration(milliseconds: fadeMs + 20), () async {
          if (_isActive(_bonusTickHandle)) {
            await _soloud.stop(_bonusTickHandle!);
            _bonusTickHandle = null;
          }
        }),
      );
    } catch (_) {
      // Bonus UI must not break if audio fails on a thin Windows install.
    }
  }

  /// Anbesa `playWinChime` — C5 → E5 → G5 → C6 after all cards land.
  Future<void> playBonusWinChime() async {
    const freqs = [523.0, 659.0, 784.0, 1046.0];
    for (var i = 0; i < freqs.length; i++) {
      final freq = freqs[i];
      unawaited(
        Future<void>.delayed(Duration(milliseconds: i * 120), () {
          unawaited(playBonusTick(frequency: freq, durationSec: 0.18));
        }),
      );
    }
  }

  /// Plays a bingo number voice. Returns clip length so callers can wait for a
  /// silence gap after the sound finishes before the next call.
  ///
  /// Calls are serialized and WAV sources are cached — avoids silent skips on
  /// slower PCs when the next number was loading while the previous still played.
  Future<Duration> playNumber(int number, {int voiceIndex = 5}) async {
    if (number < 1 || number > 75) return Duration.zero;

    late final Completer<Duration> done;
    done = Completer<Duration>();
    _numberPlayChain = _numberPlayChain.then((_) async {
      try {
        final duration = await _playNumberInternal(number, voiceIndex);
        if (!done.isCompleted) done.complete(duration);
      } catch (e, st) {
        if (!done.isCompleted) done.completeError(e, st);
      }
    });
    // Keep the chain alive even if this play fails.
    _numberPlayChain = _numberPlayChain.catchError((_) {});

    try {
      return await done.future;
    } catch (_) {
      return _minNumberDuration;
    }
  }

  Future<Duration> _playNumberInternal(int number, int voiceIndex) async {
    await _ensureInitialized();
    final folder = folderForVoice(voiceIndex);

    Future<Duration> attempt() async {
      await _stopNumberHandle();
      // Let SoLoud release the voice slot on slow machines.
      await Future<void>.delayed(const Duration(milliseconds: 16));

      final source = await _loadNumberSource(folder, number);
      var length = _soloud.getLength(source);
      if (length < _minNumberDuration) {
        length = _minNumberDuration;
      }

      final handle = await _soloud.play(source);
      if (!_soloud.getIsValidVoiceHandle(handle)) {
        throw StateError('Number voice handle invalid for $number');
      }
      _numberHandle = handle;
      return length;
    }

    try {
      return await attempt();
    } catch (_) {
      // Drop a possibly corrupt cache entry and retry once.
      final key = '$folder/$number';
      final bad = _numberSourceCache.remove(key);
      if (bad != null) {
        try {
          await _soloud.disposeSource(bad);
        } catch (_) {}
      }
      try {
        return await attempt();
      } catch (_) {
        return _minNumberDuration;
      }
    }
  }

  /// Ethiomark `good_bingo_sound`: 0=good.wav, 1=clapping.mp3, 2=goodbingo.mp3
  Future<void> playGoodBingo({int variant = 0}) async {
    final file = switch (variant) {
      1 => 'clapping.mp3',
      2 => 'goodbingo.mp3',
      _ => 'good.wav',
    };
    await _playEffect(file);
  }

  Future<void> playNotGood() => _playEffect('notgood.wav');

  Future<void> playLateBingo() => _playEffect('late.mp3');

  Future<void> playNotRegistered() => _playEffect('notreg.wav');

  Future<void> playLockedCard() => _playEffect('locked_card.mp3');

  /// Round start modal — `lijemr_new.mp3`
  Future<void> playWillStart() => _playEffect('lijemr_new.mp3');

  /// BINGO draw start / stop
  Future<void> playDrawStart() => _playEffect('start.mp3');

  Future<void> playDrawStop() => _playEffect('stop.mp3');

  /// Shuffle animation — plays once; duration matches [shuffle.wav] length.
  Future<Duration> playShuffle() async {
    await _ensureInitialized();
    await _stopEffect();
    _shuffleSource = await _soloud.loadAsset(
      'assets/sounds/shuffle.wav',
      mode: LoadMode.memory,
    );
    final length = _soloud.getLength(_shuffleSource!);
    _effectHandle = await _soloud.play(_shuffleSource!, looping: false);
    return length;
  }

  Future<void> stopShuffle() async {
    await _ensureInitialized();
    if (_isActive(_effectHandle)) {
      await _soloud.stop(_effectHandle!);
    }
    _effectHandle = null;
    if (_shuffleSource != null) {
      await _soloud.disposeSource(_shuffleSource!);
      _shuffleSource = null;
    }
  }

  Future<void> _playEffect(String file) async {
    await _ensureInitialized();
    final isMp3 = file.endsWith('.mp3');
    await _stopEffect();
    _effectSource = await _soloud.loadAsset(
      'assets/sounds/$file',
      mode: isMp3 ? LoadMode.memory : LoadMode.disk,
    );
    _effectHandle = await _soloud.play(_effectSource!);
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await _disposeNumberCache();
    await _stopEffect();
    if (_isActive(_bonusTickHandle)) {
      await _soloud.stop(_bonusTickHandle!);
    }
    _bonusTickHandle = null;
    if (_bonusTickSource != null) {
      await _soloud.disposeSource(_bonusTickSource!);
      _bonusTickSource = null;
    }
    _soloud.deinit();
    _initialized = false;
  }
}

import 'package:flutter/foundation.dart';

import '../../data/repositories/cartela_importer.dart';
import 'bootstrap_cache.dart';

void _appendCartelaLog(String message) {
  if (kDebugMode) {
    debugPrint('CartelaLoadService: $message');
  }
}

/// Background cartela import with progress — login can show while this runs.
class CartelaLoadService extends ChangeNotifier {
  CartelaLoadService._();
  static final CartelaLoadService instance = CartelaLoadService._();

  static const _progressNotifyInterval = Duration(milliseconds: 300);

  bool _ready = false;
  bool _loading = false;
  int _current = 0;
  int _total = 0;
  String? _error;
  Future<void>? _task;
  DateTime _lastProgressNotify = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isReady => _ready;
  bool get isLoading => _loading;
  int get current => _current;
  int get total => _total;
  double? get progress => _total > 0 ? _current / _total : null;
  String? get error => _error;

  void markReady() {
    _ready = true;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> ensureLoaded(CartelaImporter importer) {
    if (_ready) return Future.value();
    if (_task != null) return _task!;
    _task = _run(importer);
    return _task!;
  }

  Future<void> _run(CartelaImporter importer) async {
    if (_ready) return;

    if (await BootstrapCache.isCartelasReady()) {
      markReady();
      return;
    }

    _loading = true;
    _error = null;
    _current = 0;
    _total = 0;
    notifyListeners();

    try {
      await importer.importIfEmpty(
        onProgress: (current, total) {
          _current = current;
          _total = total;
          final now = DateTime.now();
          final done = total > 0 && current >= total;
          if (done ||
              now.difference(_lastProgressNotify) >= _progressNotifyInterval) {
            _lastProgressNotify = now;
            notifyListeners();
          }
        },
      );
      _ready = true;
    } catch (e, stack) {
      _error = '$e';
      _task = null;
      _appendCartelaLog('import failed: $e\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

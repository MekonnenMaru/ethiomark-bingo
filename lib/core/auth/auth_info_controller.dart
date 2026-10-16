import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../network/user_facing_error.dart';
import 'auth_info_prefs.dart';

/// Optional notice pushed from the remote server (shown on login/setup).
class AuthRemoteNotice {
  const AuthRemoteNotice({
    this.id,
    required this.title,
    required this.body,
    this.messageType = 'notice',
    this.updatedAt,
    this.fetchedAt,
  });

  final int? id;
  final String title;
  final String body;
  final String messageType;
  final DateTime? updatedAt;
  final DateTime? fetchedAt;

  factory AuthRemoteNotice.fromJson(Map<String, dynamic> json) {
    return AuthRemoteNotice(
      id: int.tryParse('${json['id'] ?? ''}'),
      title: '${json['title'] ?? ''}'.trim(),
      body: '${json['body'] ?? json['message'] ?? ''}'.trim(),
      messageType: '${json['message_type'] ?? 'notice'}'.trim(),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'body': body,
        'message_type': messageType,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  bool get isValid => title.isNotEmpty || body.isNotEmpty;
}

/// Loads remote auth-screen notices when online; caches locally for offline use.
class AuthInfoController extends ChangeNotifier {
  static const messagesPerPage = 5;
  static const welcomeMessageType = 'welcome';

  List<AuthRemoteNotice> _remoteNotices = [];
  bool _loading = false;
  bool _fromCache = false;
  NetworkErrorKind? _lastNetworkError;
  DateTime? _lastSyncedAt;

  List<AuthRemoteNotice> get remoteNotices =>
      List<AuthRemoteNotice>.unmodifiable(_remoteNotices);

  /// Pinned welcome copy (from remote/local cache), shown above other notices.
  AuthRemoteNotice? get pinnedWelcome {
    for (final notice in _remoteNotices) {
      if (notice.messageType == welcomeMessageType) return notice;
    }
    return null;
  }

  /// Active notices excluding the pinned welcome block.
  List<AuthRemoteNotice> get feedNotices => _remoteNotices
      .where((notice) => notice.messageType != welcomeMessageType)
      .toList(growable: false);

  AuthRemoteNotice? get remoteNotice =>
      _remoteNotices.isNotEmpty ? _remoteNotices.first : null;

  bool get loading => _loading;
  bool get fromCache => _fromCache;
  NetworkErrorKind? get lastNetworkError => _lastNetworkError;
  bool get hasRemoteNotices => feedNotices.isNotEmpty;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get totalPages {
    final feed = feedNotices;
    return feed.isEmpty ? 0 : ((feed.length - 1) ~/ messagesPerPage) + 1;
  }

  List<AuthRemoteNotice> pageSlice(int page) {
    final feed = feedNotices;
    if (feed.isEmpty) return const [];
    final start = page * messagesPerPage;
    if (start >= feed.length) return const [];
    final end = (start + messagesPerPage).clamp(0, feed.length);
    return feed.sublist(start, end);
  }

  Future<void> loadCached() async {
    final snapshot = await AuthInfoPrefs.loadSnapshot();
    if (snapshot.notices.isEmpty) return;
    _remoteNotices = snapshot.notices;
    _lastSyncedAt = snapshot.lastSyncedAt;
    _fromCache = true;
    notifyListeners();
  }

  Future<void> refreshIfOnline() async {
    if (_loading) return;

    _loading = true;
    _lastNetworkError = null;
    notifyListeners();

    try {
      final url = await AppConfig.remoteAuthInfoUrl();
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        _lastNetworkError = NetworkErrorKind.serverUnavailable;
        return;
      }

      final decoded = jsonDecode(response.body);
      final notices = _parseNotices(decoded);
      await _applyServerNotices(notices);
    } catch (e) {
      _lastNetworkError = classifyNetworkError(e);
      if (_remoteNotices.isEmpty) {
        await loadCached();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Replace local list with server active messages (removes disabled remotely).
  Future<void> _applyServerNotices(List<AuthRemoteNotice> notices) async {
    final fetchedAt = DateTime.now();
    _remoteNotices = notices
        .map(
          (n) => AuthRemoteNotice(
            id: n.id,
            title: n.title,
            body: n.body,
            messageType: n.messageType,
            updatedAt: n.updatedAt,
            fetchedAt: fetchedAt,
          ),
        )
        .where((n) => n.isValid)
        .toList();
    _remoteNotices = AuthInfoPrefs.ensureBundledWelcome(_remoteNotices);
    _fromCache = false;
    _lastSyncedAt = fetchedAt;
    _lastNetworkError = null;
    await AuthInfoPrefs.saveSnapshot(
      notices: _remoteNotices,
      lastSyncedAt: _lastSyncedAt,
    );
  }

  List<AuthRemoteNotice> _parseNotices(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return [];

    final rawMessages = decoded['messages'];
    if (rawMessages is List) {
      return rawMessages
          .whereType<Map>()
          .map((m) => AuthRemoteNotice.fromJson(Map<String, dynamic>.from(m)))
          .where((n) => n.isValid)
          .toList();
    }

    final legacy = AuthRemoteNotice.fromJson(decoded);
    return legacy.isValid ? [legacy] : [];
  }

  void clearRemoteNotices() {
    _remoteNotices = [];
    _fromCache = false;
    _lastSyncedAt = null;
    AuthInfoPrefs.saveSnapshot(notices: [], lastSyncedAt: null);
    notifyListeners();
  }
}

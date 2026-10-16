import '../l10n/app_strings.dart';

enum NetworkErrorKind {
  noConnection,
  timedOut,
  serverUnavailable,
}

bool looksLikeNetworkError(Object? value) {
  if (value == null) return false;
  final raw = value.toString().toLowerCase();
  return raw.contains('socketexception') ||
      raw.contains('clientexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('no address associated with hostname') ||
      raw.contains('connection refused') ||
      raw.contains('connection reset') ||
      raw.contains('connection timed out') ||
      raw.contains('timed out') ||
      raw.contains('timeout') ||
      raw.contains('http://') ||
      raw.contains('https://') ||
      raw.contains('uri=') ||
      raw.contains('errno =');
}

NetworkErrorKind classifyNetworkError(Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('timed out') || raw.contains('timeout')) {
    return NetworkErrorKind.timedOut;
  }
  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('no address associated') ||
      raw.contains('connection refused') ||
      raw.contains('connection reset') ||
      raw.contains('clientexception')) {
    return NetworkErrorKind.noConnection;
  }
  return NetworkErrorKind.serverUnavailable;
}

String userFacingNetworkMessage(Object error, AppStrings strings) {
  return switch (classifyNetworkError(error)) {
    NetworkErrorKind.noConnection => strings.noInternetConnection,
    NetworkErrorKind.timedOut => strings.connectionTimedOut,
    NetworkErrorKind.serverUnavailable => strings.serverUnreachable,
  };
}

String networkErrorMessage(NetworkErrorKind kind, AppStrings strings) {
  return switch (kind) {
    NetworkErrorKind.noConnection => strings.noInternetConnection,
    NetworkErrorKind.timedOut => strings.connectionTimedOut,
    NetworkErrorKind.serverUnavailable => strings.serverUnreachable,
  };
}

String sanitizeUserMessage(String? message, AppStrings strings) {
  if (message == null || message.trim().isEmpty) {
    return strings.connectionProblem;
  }
  if (looksLikeNetworkError(message)) {
    return userFacingNetworkMessage(message, strings);
  }

  final withoutUrls = message
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'uri=\S+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (withoutUrls.isEmpty || looksLikeNetworkError(withoutUrls)) {
    return strings.connectionProblem;
  }
  return withoutUrls;
}

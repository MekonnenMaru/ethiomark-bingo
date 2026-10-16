import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openSystemDateSettings() async {
  if (kIsWeb) return false;

  final Uri? uri = switch (defaultTargetPlatform) {
    TargetPlatform.android => Uri.parse(
        'intent:#Intent;action=android.settings.DATE_SETTINGS;end',
      ),
    TargetPlatform.windows => Uri.parse('ms-settings:dateandtime'),
    _ => null,
  };

  if (uri == null) return false;

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

bool get canOpenSystemDateSettings {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isWindows;
}

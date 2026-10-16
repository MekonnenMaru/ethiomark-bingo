import 'auth_info_controller.dart';

/// Bundled welcome copy — mirrors remote DB seed for first-run local cache.
class AuthWelcomeDefaults {
  AuthWelcomeDefaults._();

  static const title = 'Welcome to Ethiomark Bingo';

  static const body = 'Offline bingo cashier — Windows & Android.\n\n'
      'Our games\n'
      '• Bingo — 75-number offline cashier (this app)\n'
      '• Keno — offline keno cashier\n'
      '• Spin — offline spin game\n\n'
      'Game modes\n'
      '• Classic 75-number bingo\n'
      '• Many win patterns (lines, L, T, X, full card…)\n'
      '• All-in-one — lines, outside & inside corners\n'
      '• Flexible stakes (10–1000 birr)\n\n'
      'Key features\n'
      '• Fully offline — no internet required\n'
      '• Daily reports & wallet management\n'
      '• Manual or automatic card checking\n'
      '• Multiple voices · house cut · bonus rounds\n'
      '• 5 free trial rounds (0 birr wallet)';

  static AuthRemoteNotice get bundled => const AuthRemoteNotice(
        title: title,
        body: body,
        messageType: AuthInfoController.welcomeMessageType,
      );
}

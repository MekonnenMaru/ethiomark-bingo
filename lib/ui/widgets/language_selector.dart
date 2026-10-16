import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_language.dart';
import '../../core/l10n/locale_controller.dart';
import '../theme/auth_theme.dart';
import '../theme/bingo_colors.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.compact = false,
    this.goldAccent = false,
  });

  final bool compact;
  final bool goldAccent;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final accent = goldAccent
        ? BingoColors.gold
        : Colors.white.withValues(alpha: 0.9);
    final textColor = goldAccent ? BingoColors.gold : Colors.white;

    return DropdownButtonHideUnderline(
      child: DropdownButton<AppLanguage>(
        value: locale.language,
        dropdownColor: BingoColors.surface,
        icon: Icon(
          Icons.language,
          color: accent,
          size: compact ? 20 : 22,
        ),
        style: TextStyle(
          color: textColor,
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
        items: AppLanguage.values
            .map(
              (lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang.nativeName),
              ),
            )
            .toList(),
        onChanged: (lang) {
          if (lang != null) locale.setLanguage(lang);
        },
        selectedItemBuilder: (context) => AppLanguage.values
            .map(
              (lang) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  compact ? lang.code.toUpperCase() : lang.nativeName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class LanguageSelectorTile extends StatelessWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final s = locale.strings;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: s.languageLabel,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          isExpanded: true,
          value: locale.language,
          dropdownColor: BingoColors.surface,
          items: AppLanguage.values
              .map(
                (lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang.nativeName),
                ),
              )
              .toList(),
          onChanged: (lang) {
            if (lang != null) locale.setLanguage(lang);
          },
        ),
      ),
    );
  }
}

/// Input text and border labels inside auth fields.
const authFieldTextColor = AuthTheme.textPrimary;

const authFieldLabelColor = AuthTheme.textSecondary;

const _authFieldFillColor = AuthTheme.fieldFill;
const _authFieldBorderColor = AuthTheme.fieldBorder;
const _authFieldFocusColor = AuthTheme.fieldFocus;
const authFieldSpacing = 18.0;

/// Wraps login/setup fields with dark inputs and white text/labels.
class AuthFormScope extends StatelessWidget {
  const AuthFormScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: authFieldLabelColor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          onSurface: authFieldTextColor,
          onSurfaceVariant: authFieldLabelColor,
          primary: _authFieldFocusColor,
          surface: _authFieldFillColor,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: labelStyle,
          floatingLabelStyle: labelStyle,
          fillColor: _authFieldFillColor,
          filled: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: authFieldTextColor),
          bodyMedium: TextStyle(color: authFieldTextColor),
        ),
      ),
      child: child,
    );
  }
}

/// Shared outlined field style for login/setup forms.
InputDecoration authFieldDecoration(String label) {
  const borderRadius = BorderRadius.all(Radius.circular(5));

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  const labelStyle = TextStyle(
    color: authFieldLabelColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    floatingLabelAlignment: FloatingLabelAlignment.start,
    filled: true,
    fillColor: _authFieldFillColor,
    labelStyle: labelStyle,
    floatingLabelStyle: labelStyle,
    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
    border: border(_authFieldBorderColor),
    enabledBorder: border(_authFieldBorderColor),
    focusedBorder: border(_authFieldFocusColor, 1.5),
  );
}

/// Field wrapper — top padding leaves room for border labels (not clipped).
class AuthFieldSurface extends StatelessWidget {
  const AuthFieldSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: authFieldSpacing),
      child: child,
    );
  }
}

/// Login/setup form field styled language picker.
class AuthLanguageField extends StatelessWidget {
  const AuthLanguageField({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final s = locale.strings;

    return AuthFieldSurface(
      child: DropdownButtonFormField<AppLanguage>(
        value: locale.language,
        decoration: authFieldDecoration(s.languageLabel),
        dropdownColor: _authFieldFillColor,
        icon: const Icon(Icons.expand_more, color: authFieldTextColor),
        style: const TextStyle(
          color: authFieldTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: AppLanguage.values
            .map(
              (lang) => DropdownMenuItem(
                value: lang,
                child: Text(
                  lang.nativeName,
                  style: const TextStyle(color: authFieldTextColor),
                ),
              ),
            )
            .toList(),
        onChanged: (lang) {
          if (lang != null) locale.setLanguage(lang);
        },
      ),
    );
  }
}

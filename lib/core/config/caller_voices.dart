import 'cashier_defaults.dart';

/// Caller voice labels and sound indices (map to [SoundService.voiceFoldersByIndex]).
class CallerVoiceOption {
  const CallerVoiceOption({required this.soundIndex, required this.label});

  final int soundIndex;
  final String label;
}

/// Display order for caller voice pickers (indices stable for saved cashier data).
const kCallerVoiceOptions = <CallerVoiceOption>[
  CallerVoiceOption(soundIndex: 5, label: 'Arada'),
  CallerVoiceOption(soundIndex: 2, label: 'Addis'),
  CallerVoiceOption(soundIndex: 6, label: 'Bereket'),
  CallerVoiceOption(soundIndex: 4, label: 'Modern Arada'),
  CallerVoiceOption(soundIndex: 1, label: 'Wedi (Tigrigna)'),
  CallerVoiceOption(soundIndex: 3, label: 'Foromifa (Oromifa)'),
];

int normalizeCallerVoiceIndex(int? value) {
  final index = value ?? CashierDefaults.callerVoice;
  if (kCallerVoiceOptions.any((o) => o.soundIndex == index)) return index;
  return CashierDefaults.callerVoice;
}

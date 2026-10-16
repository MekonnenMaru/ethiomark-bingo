import '../config/app_currency.dart';
import '../bingo/bingo_claim_mode.dart';
import '../bingo/bingo_pattern_names.dart';
import '../format/app_number_format.dart';
import 'app_language.dart';

class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  String get languageLabel => switch (language) {
        AppLanguage.am => 'ቋንቋ',
        AppLanguage.en => 'Language',
        AppLanguage.om => 'Afaan',
        AppLanguage.ti => 'ቋንቋ',
      };

  String get languageHelp => _t(
        'የመተግበሪያውን ቋንቋ ይምረጡ።',
        'Choose the app display language.',
        'Afaan agarsiisa appii filadhu.',
        'ቋንቋ ኣፕሊኬሽን ምረጹ።',
      );

  String get navReport => switch (language) {
        AppLanguage.am => 'ሪፖርት',
        AppLanguage.en => 'Report',
        AppLanguage.om => 'Gabaasa',
        AppLanguage.ti => 'ሪፖርት',
      };

  String get navPlay => switch (language) {
        AppLanguage.am => 'ጨዋታ',
        AppLanguage.en => 'Play',
        AppLanguage.om => 'Tapha',
        AppLanguage.ti => 'ጸወታ',
      };

  String get navCartelaManagement => switch (language) {
        AppLanguage.am => 'ካርድ አስተዳደር',
        AppLanguage.en => 'Cartela Management',
        AppLanguage.om => 'Bulchiinsa Kaardii',
        AppLanguage.ti => 'ኣመሓዳይ ካርድ',
      };

  String get navProfile => switch (language) {
        AppLanguage.am => 'ፓኬጅ',
        AppLanguage.en => 'Package',
        AppLanguage.om => 'Paakeejii',
        AppLanguage.ti => 'ፓኬጅ',
      };

  String get registerPackageButton => _t(
        'ፓኬጅ',
        'Package (ፓኬጅ)',
        'Paakeejii',
        'ፓኬጅ',
      );

  String get navPagesMenu => switch (language) {
        AppLanguage.am => 'ገጾች',
        AppLanguage.en => 'Pages',
        AppLanguage.om => 'Fuulli',
        AppLanguage.ti => 'ገጻት',
      };

  String get navAbout => switch (language) {
        AppLanguage.am => 'ስለ',
        AppLanguage.en => 'About',
        AppLanguage.om => 'Waa\'ee',
        AppLanguage.ti => 'ብዛዕባ',
      };

  String get navHelp => switch (language) {
        AppLanguage.am => 'እገዛ',
        AppLanguage.en => 'Help',
        AppLanguage.om => 'Gargaarsa',
        AppLanguage.ti => 'ሓገዝ',
      };

  String get helpPageTitle => _t(
        'እገዛ እና ድጋፍ',
        'Help & Support',
        'Gargaarsa fi deeggarsa',
        'ሓገዝን ድጋፍን',
      );

  String get helpGuidesTitle => _t(
        'መመሪያዎች',
        'Guides',
        'Qajeelfama',
        'መምርሒታት',
      );

  String gameRound(int round) => switch (language) {
        AppLanguage.am => 'ዙር $round',
        AppLanguage.en => 'Round $round',
        AppLanguage.om => 'Raaundii $round',
        AppLanguage.ti => 'ዙር $round',
      };

  String roundShort(int round) => switch (language) {
        AppLanguage.am => 'ዙር $round',
        AppLanguage.en => 'Round $round',
        AppLanguage.om => 'Raaundii $round',
        AppLanguage.ti => 'ዙር $round',
      };

  String selectedSummary(int selected, int total) => switch (language) {
        AppLanguage.am => '$selected ተመርጠዋል · $total ካርዶች',
        AppLanguage.en => '$selected selected · $total cards',
        AppLanguage.om => '$selected filatame · kaardii $total',
        AppLanguage.ti => '$selected ተመርጺዎም · $total ካርድ',
      };

  String selectedOnly(int selected) => switch (language) {
        AppLanguage.am => 'ተመርጠዋል: $selected',
        AppLanguage.en => 'Selected: $selected',
        AppLanguage.om => 'Filatame: $selected',
        AppLanguage.ti => 'ተመርጺ: $selected',
      };

  String get keyboardHint => switch (language) {
        AppLanguage.am => '[በ ኪቦርድ መመዝገብ ይችላሉ ⌨️]',
        AppLanguage.en => '[Type card number on keyboard ⌨️]',
        AppLanguage.om => '[Lakkoofsa kaardii keyboard irratti barreessi ⌨️]',
        AppLanguage.ti => '[ቁጽሪ ካርድ ብኪቦርድ ጽሓፉ ⌨️]',
      };

  String typingLabel(String value) => switch (language) {
        AppLanguage.am => 'በመጻፍ ላይ: $value',
        AppLanguage.en => 'Typing: $value',
        AppLanguage.om => 'Barreeffama: $value',
        AppLanguage.ti => 'ይጽሕፉ: $value',
      };

  String get registerCards => switch (language) {
        AppLanguage.am => 'ካርዶችን ይመዝግቡ',
        AppLanguage.en => 'Register Cards',
        AppLanguage.om => 'Kaardii Galmeessi',
        AppLanguage.ti => 'ካርድ ኣመዝግብ',
      };

  String get selectedCardsTitle => switch (language) {
        AppLanguage.am => 'የተመረጡ ካርዶች',
        AppLanguage.en => 'Selected cards',
        AppLanguage.om => 'Kaardii filataman',
        AppLanguage.ti => 'ዝተመረጹ ካርድ',
      };

  String get emptySelectionHint => switch (language) {
        AppLanguage.am =>
          'ከጎን በኩል ቁጥሮችን ይጫኑ ወይም ቁጥር ይፃፉና Enter ይጫኑ።',
        AppLanguage.en =>
          'Click numbers on the grid or type a card number and press Enter.',
        AppLanguage.om =>
          'Lakkoofsota cuqaasi ykn lakkoofsa barreessi Enter tuqi.',
        AppLanguage.ti =>
          'ቁጽርታት ምረጹ ወይ ቁጽሪ ጽሓፉ ከምኡ Enter ጠውቑ።',
      };

  String get registeredNumberLabel => _t(
        'የተመዘገበ ቁጥር',
        'Registered number',
        'Lakkoofsi galmaa\'e',
        'ዝተመዝገበ ቁጽሪ',
      );

  String get numberAlreadyRegisteredUnselectQuestion => _t(
        'ቁጥሩ ተመዝግቧል ማጥፋት ይፈልጋሉ?',
        'The number is registered. Do you want to remove it?',
        'Lakkoofsi kun galmaa\'eera. Haquu barbaaddaa?',
        'እቲ ቁጽሪ ተመዝገበ። ክትሰርዞ ትደሊ?',
      );

  String get unselectYesLabel => _t(
        'አዎ፣ እፈልጋለሁ',
        'Yes, I want to',
        'Eeyyee, barbaada',
        'እወ፣ እደሊ',
      );

  String get unselectNoLabel => _t(
        'አይ፣ አልፈልግም',
        'No, I don\'t want to',
        'Lakki, hin barbaadu',
        'ኣይ፣ ኣይደልየን',
      );

  String get yes => _t('አዎ', 'Yes', 'Eeyyee', 'እወ');
  String get no => _t('አይ', 'No', 'Lakki', 'ኣይፋል');

  String get selectFirstCardsPrefix => switch (language) {
        AppLanguage.am => 'የመጀመሪያውን',
        AppLanguage.en => 'Select the first',
        AppLanguage.om => 'Kaardii jalqabaa',
        AppLanguage.ti => 'ናይ መጀመርታ',
      };

  String get selectFirstCardsSuffix => switch (language) {
        AppLanguage.am => 'ካርዶች ይምረጡ',
        AppLanguage.en => 'cards',
        AppLanguage.om => 'filadhu',
        AppLanguage.ti => 'ካርድ ምረጹ',
      };

  String get selectFirstCardsApply => switch (language) {
        AppLanguage.am => 'ምረጥ',
        AppLanguage.en => 'Select',
        AppLanguage.om => 'Filadhu',
        AppLanguage.ti => 'ምረጽ',
      };

  String get allCards => switch (language) {
        AppLanguage.am => 'ሁሉም ካርዶች',
        AppLanguage.en => 'All cards',
        AppLanguage.om => 'Kaardii hunda',
        AppLanguage.ti => 'ኩሉ ካርድ',
      };

  String get derash => switch (language) {
        AppLanguage.am => 'ደራሽ',
        AppLanguage.en => 'Derash',
        AppLanguage.om => 'Derash',
        AppLanguage.ti => 'ደራሽ',
      };

  String currencyLabel(String code) => switch (normalizeCurrencyCode(code)) {
        'usd' => _t('ዶላር', 'USD', 'Doolaara', 'ዶላር'),
        'eur' => _t('ዩሮ', 'EUR', 'Yuuroo', 'ዩሮ'),
        'gbp' => _t('ፓውንድ', 'GBP', 'Pawundii', 'ፓውንድ'),
        'kes' => _t('ሼሊንግ', 'KES', 'Shilingii', 'ሼሊንግ'),
        _ => birr,
      };

  /// Short currency label for compact report table columns.
  String currencyCompact(String code) {
    final normalized = normalizeCurrencyCode(code);
    if (normalized == AppCurrency.birr) {
      return switch (language) {
        AppLanguage.am => 'ብር',
        AppLanguage.en => 'Br',
        AppLanguage.om => 'Birrii',
        AppLanguage.ti => 'ብር',
      };
    }
    return currencyLabel(code);
  }

  String reportStakeColumnHeader(String currencyCode) =>
      currencyLabel(currencyCode);

  String get currencyHelp => _t(
        'ምንዛሬ ለደራሽ መጠን እና ዋጋ ማሳያ።',
        'Currency shown with derash amounts and prices.',
        'Maallaqa derash fi gatii agarsiisu.',
        'ንጥረ ደራሽንንን ዋጋ ንምርኣይ ዝውል ገንዘብ።',
      );

  String get currencyFieldLabel =>
      _t('ምንዛሬ', 'Currency', 'Maallaqa', 'ገንዘብ');

  String get incomeRoundingLabel => _t(
        'የገቢ ማስተካከል',
        'Income rounding',
        'Income rounding',
        'ምትሕያር ገቢ',
      );

  String get incomeRoundingHelp => _t(
        'የገቢ ማስተካከል በደራሽ ላይ እንዴት እንደሚተገበር ይምረጡ።',
        'Choose whether house income is rounded before derash is shown.',
        'Income rounding derash irratti akkamitti akka hojjetu filadhu.',
        'እንታይ ገቢ ከም ዘይተሓላለፈ ኣብ ደራሽ ምርኣይ ይምረጹ።',
      );

  String get allowIncomeRounding => _t(
        'Allow rounding',
        'Allow rounding',
        'Rounding hayyami',
        'ምትሕያር ፍቐድ',
      );

  String get removeIncomeRounding => _t(
        'Remove rounding',
        'Remove rounding',
        'Rounding balleessi',
        'ምትሕያር ኣልግስ',
      );

  String get toggleAllowIncomeRounding => _t(
        'የገቢ ማስተካከል ፍቀድ',
        'Allow net income rounding',
        'Net income rounding hayyami',
        'ምትሕያር ገቢ ንጥረ ገቢ ፍቐድ',
      );

  String derashAmountLabel(num amount, String currencyCode) {
    final formatted = AppNumberFormat.format(amount);
    return '$formatted ${currencyLabel(currencyCode)} $derash';
  }

  String derashCurrencyLabel(String currencyCode) =>
      '${currencyLabel(currencyCode)} $derash';

  static String normalizeCurrencyCode(String code) =>
      AppCurrency.normalize(code);

  String cardQuantityLabel(int count) => _t(
        'ብዛት: $count',
        'Cards: $count',
        'Baay\'ina: $count',
        'ብዝሒ: $count',
      );

  String get cardsStatShort => _t('ካርዶች', 'Cards', 'Kaardii', 'ካርድ');

  String get callsStatShort => _t('ጥሪ', 'Calls', 'Waamicha', 'ጻዕሪ');

  String callCountLabel(int count) => _t(
        'ጥሪ: $count',
        'Calls: $count',
        'Waamicha: $count',
        'ጻዕሪ: $count',
      );

  String cardsCount(int count) {
    final formatted = AppNumberFormat.format(count);
    return switch (language) {
      AppLanguage.am => '$formatted ካርዶች',
      AppLanguage.en => '$formatted cards',
      AppLanguage.om => 'kaardii $formatted',
      AppLanguage.ti => '$formatted ካርድ',
    };
  }

  String priceLabel(String currencyCode) {
    final currency = currencyLabel(currencyCode);
    return switch (language) {
      AppLanguage.am => 'ዋጋ ($currency)',
      AppLanguage.en => 'Price ($currency)',
      AppLanguage.om => 'Gatii ($currency)',
      AppLanguage.ti => 'ዋጋ ($currency)',
    };
  }

  String priceOption(int p, String currencyCode) {
    final currency = currencyLabel(currencyCode);
    return switch (language) {
      AppLanguage.am => 'በ $p$currency',
      AppLanguage.en => '$p $currency',
      AppLanguage.om => '$currency $p',
      AppLanguage.ti => '$p $currency',
    };
  }

  String priceCompact(int p, String currencyCode) =>
      priceOption(p, currencyCode);

  String get patternLabel => switch (language) {
        AppLanguage.am => 'ቅርጽ ይምረጡ',
        AppLanguage.en => 'Select pattern',
        AppLanguage.om => 'Akkaataa filadhu',
        AppLanguage.ti => 'ቅርጺ ምረጽ',
      };

  String patternName(int pattern) => BingoPatternNames.englishName(pattern);

  String selectedPatternLabel(String englishPatternName) => _t(
        'የተመረጠ ቅርጽ: $englishPatternName',
        'Selected pattern: $englishPatternName',
        'Akkaataa filatame: $englishPatternName',
        'ዝተመረጸ ቅርጺ: $englishPatternName',
      );

  String patternSummary(int pattern) =>
      BingoPatternNames.summaryEnglish(pattern);

  /// Short label for mobile header (e.g. "1 line", "Default").
  String patternCompact(int pattern) =>
      BingoPatternNames.compactEnglish(pattern);

  String get clear => switch (language) {
        AppLanguage.am => 'አጥራ',
        AppLanguage.en => 'Clear',
        AppLanguage.om => 'Haqi',
        AppLanguage.ti => 'ኣጽዳ',
      };

  String get play => switch (language) {
        AppLanguage.am => 'ጀምር',
        AppLanguage.en => 'PLAY',
        AppLanguage.om => 'Taphaali',
        AppLanguage.ti => 'ጀምር',
      };

  String get loadingCards => switch (language) {
        AppLanguage.am => 'ካርዶች በመጫን ላይ…',
        AppLanguage.en => 'Loading cards…',
        AppLanguage.om => 'Kaardii fe\'aa jira…',
        AppLanguage.ti => 'ካርድ ይጽዕን…',
      };

  String get registeringRound => switch (language) {
        AppLanguage.am => 'ዙር በመመዝገብ ላይ…',
        AppLanguage.en => 'Registering round…',
        AppLanguage.om => 'Raaundii galmeessaa jira…',
        AppLanguage.ti => 'ዙር ይመዝገብ…',
      };

  String get fontSize => switch (language) {
        AppLanguage.am => 'የፊደል መጠን',
        AppLanguage.en => 'Font size',
        AppLanguage.om => 'Hagamtaa qubee',
        AppLanguage.ti => 'መጠን ፊደል',
      };

  String get boardZoom => switch (language) {
        AppLanguage.am => 'የቦርድ ማጉላት',
        AppLanguage.en => 'Board zoom',
        AppLanguage.om => 'Zoom boordii',
        AppLanguage.ti => 'ዙም ቦርድ',
      };

  String _t(String am, String en, String om, String ti) => switch (language) {
        AppLanguage.am => am,
        AppLanguage.en => en,
        AppLanguage.om => om,
        AppLanguage.ti => ti,
      };

  // —— Common ——
  String get appName => _t(
        'Ethiomark Bingo',
        'Ethiomark Bingo',
        'Ethiomark Bingo',
        'Ethiomark Bingo',
      );

  String get ok => _t('እሺ', 'OK', 'Tole', 'እሺ');
  String get cancel => _t('ሰርዝ', 'Cancel', 'Haqi', 'ሰርዝ');
  String get save => _t('አስቀምጥ', 'Save', 'Olkaa\'i', 'ዓቅም');
  String get search => _t('ፈልግ', 'Search', 'Barbaadi', 'ድለ');
  String get searchNumber =>
      _t('ቁጥር ፈልግ', 'Search number', 'Lakkoofsa barbaadi', 'ቁጽሪ ድለ');
  String get searchCategory =>
      _t('ምድብ ፈልግ', 'Search category', 'Gosa barbaadi', 'ክፍሊት ድለ');
  String get retry => _t('እንደገና ሞክር', 'Retry', 'Irra deebi\'i', 'ደጊምካ ፈትን');
  String get close => _t('ዝጋ', 'Close', 'Cufi', 'ዕጸው');
  String get copy => _t('ቅዳ', 'Copy', 'Garagalchi', 'ቅዳ');
  String get copied => _t('ተቀድቷል', 'Copied', 'Garagaleera', 'ተቐዲሑ');
  String get help => _t('እገዛ', 'Help', 'Gargaarsa', 'ሓገዝ');
  String get apply => _t('ተግብር', 'Apply', 'Hojiirsi', 'ኣተግብር');
  String get refresh => _t('አድስ', 'Refresh', 'Haaromsi', 'ሓድስ');
  String get delete => _t('ሰርዝ', 'Delete', 'Haqi', 'ሰርዝ');
  String get loading => _t('በመጫን ላይ…', 'Loading…', 'Fe\'aa jira…', 'ይጽዕን…');
  String get pleaseWait => _t('እባክዎ ይጠብቁ…', 'Please wait…', 'Mee eegi…', 'በጃኻ ተጸበ…');
  String get domain => _t('ዶሜይን', 'Domain', 'Domeenii', 'ዶመይን');
  String get birr => _t('ብር', 'birr', 'birr', 'ብር');

  // —— Bootstrap ——
  String get preparingDatabase =>
      _t('ኦፍላይን ዳታቤዝ በማዘጋጀት ላይ…', 'Preparing offline database…', 'Kuusaa daataa oflaayinii qopheessaa jira…', 'ኦፍላይን ዳታቤዝ ይዳለይ…');

  String loadingCartelasProgress(int current, int total) => _t(
        'ካርዶች በመጫን ላይ $current / $total…',
        'Loading cartelas $current / $total…',
        'Kaardii fe\'aa jira $current / $total…',
        'ካርድ ይጽዕን $current / $total…',
      );

  String readyCartelasLoaded(int count) => _t(
        'ተዘጋጁ — $count ካርዶች ተጭነዋል',
        'Ready — $count cartelas loaded',
        'Qophaa\'e — kaardii $count fe\'ame',
        'ድሉው — $count ካርድ ተሓዚሑ',
      );

  String startupError(String error) => _t(
        'የመነሻ ስህተት: $error',
        'Startup error: $error',
        'Dogoggora jalqabaa: $error',
        'ጌጋ መነሻ: $error',
      );

  String get databaseDeviceMismatch => _t(
        'ይህ ዳታቤዝ ለሌላ መሣሪያ ነው። ኮፒ የተደረገ ፋይል በዚህ ኮምፒዩተር ላይ አይሰራም።',
        'This database belongs to another device. A copied database cannot be used on this computer.',
        'Kuusaan daataa kun meeshaa biraati. Fayyaa kophaa meeshaa kana irratti hin hojjetu.',
        'እዚ ዳታቤዝ ንኻልእ መሳርሒ እዩ። ዝተቐዳሐ ፋይል ኣብዚ ኮምፒዩተር ኣይሰርሕን።',
      );

  String get deviceDateMismatchTitle => _t(
        'የቀን እና ሰዓት ትክክል አይደለም',
        'Incorrect date and time',
        'Guyyaa fi sa\'aatii sirrii miti',
        'ዕለትን ሰዓትን ቅኑዕ ኣይኮነን',
      );

  String get deviceDateMismatchIntro => _t(
        'የመሣሪያዎ ቀን እና ሰዓት ከመጨረሻው እንቅስቃሴ ይቀርባል። ከመቀጠልዎ በፊት እባክዎ ያስተካክሉ።',
        'Your device date and time is behind the last activity. Please correct it before continuing.',
        'Guyyaa fi sa\'aatii meeshaa kee sochii dhumaa dura jira. Itti fufuu dura sirreessi.',
        'ዕለትን ሰዓትን መሳርያኻ ካብ ናይ መወዳእታ ንጥፈት ዝሓለፈ እዩ። ቅድሚ ምቕጻልካ በጃኻ ኣስተኻኽሎ።',
      );

  String get deviceTimezoneMismatchIntro => _t(
        'የመሣሪያዎ የሰዓት ቀጠና ትክክል አይደለም። እባክዎ ወደ ምስራቅ አፍሪካ ሰዓት (UTC+3) — ናይሮቢ ወይም አዲስ አበባ — ያስተካክሉ።',
        'Your device timezone is incorrect. Please set it to East Africa Time (UTC+3) — Nairobi or Addis Ababa.',
        'Sa\'aatii naannoo meeshaa kee sirrii miti. Mee gara Sa\'aatii Afrikaa Bahaa (UTC+3) — Nairobi ykn Addis Ababa — sirreessi.',
        'ናይ መሳርያኻ ናይ ሰዓት ዞባ ቅኑዕ ኣይኮነን። በጃኻ ናብ ምብራቕ ኣፍሪቃ ሰዓት (UTC+3) — ናይሮቢ ወይ ኣዲስ አበባ — ኣስተኻኽል።',
      );

  String get deviceDateAndTimezoneMismatchIntro => _t(
        'የመሣሪያዎ ቀን/ሰዓት እና የሰዓት ቀጠና ትክክል አይደለም። እባክዎ ከመቀጠልዎ በፊት ያስተካክሉ።',
        'Your device date/time and timezone are incorrect. Please fix them before continuing.',
        'Guyyaa, sa\'aatii fi naannoo sa\'aatii meeshaa kee sirrii miti. Itti fufuu dura sirreessi.',
        'ዕለት/ሰዓትን ናይ ሰዓት ዞባን መሳርያኻ ቅኑዕ ኣይኮነን። ቅድሚ ምቕጻልካ በጃኻ ኣስተኻኽሎ።',
      );

  String get deviceDateDeviceTimeLabel => _t(
        'የመሣሪያ ቀን እና ሰዓት',
        'Device date & time',
        'Guyyaa fi sa\'aatii meeshaa',
        'ዕለትን ሰዓትን መሳርያ',
      );

  String get deviceDateLastActivityLabel => _t(
        'የመጨረሻ እንቅስቃሴ',
        'Last activity',
        'Sochii dhumaa',
        'ናይ መወዳእታ ንጥፈት',
      );

  String get deviceDateTimezoneLabel => _t(
        'የመሣሪያ የሰዓት ቀጠና',
        'Device timezone',
        'Naannoo sa\'aatii meeshaa',
        'ናይ መሳርያኻ ናይ ሰዓት ዞባ',
      );

  String get deviceDateRequiredTimezoneLabel => _t(
        'የሚፈለገው የሰዓት ቀጠና',
        'Required timezone',
        'Naannoo sa\'aatii barbaachisu',
        'ዘድሊ ናይ ሰዓት ዞባ',
      );

  String get deviceDateRequiredTimezoneValue => _t(
        'ምስራቅ አፍሪካ ሰዓት (UTC+3) · ናይሮቢ / አዲስ አበባ',
        'East Africa Time (UTC+3) · Nairobi / Addis Ababa',
        'Sa\'aatii Afrikaa Bahaa (UTC+3) · Nairobi / Addis Ababa',
        'ምብራቕ ኣፍሪቃ ሰዓት (UTC+3) · ናይሮቢ / ኣዲስ አበባ',
      );

  String get deviceDateFixInstructions => _t(
        'በመሣሪያዎ ላይ የሰዓት ቀጠናን ወደ ምስራቅ አፍሪካ (UTC+3) ቀን እና ሰዓትን ያስተካክሉ፣ ከዚያ «እንደገና ይፈትሹ» ይጫኑ።',
        'Set timezone to East Africa Time (UTC+3) and the correct date & time on your device, then tap Check again.',
        'Naannoo sa\'aatii gara Afrikaa Bahaa (UTC+3) fi guyyaa fi sa\'aatii sirrii meeshaa kee irratti sirreessi, booda «Irra deebi\'ii ilaali» tuqi.',
        'ናይ ሰዓት ዞባ ናብ ምብራቕ ኣፍሪቃ (UTC+3)ን ቅኑዕ ዕለትን ሰዓትን ኣብ መሳርያኻ ኣስተኻኽል፣ ድሕሪኡ «ደጊምካ ፈትን» ጠውቕ።',
      );

  String get deviceDateStillWrongTitle => _t(
        'አሁንም ቀን እና ሰዓት ትክክል አይደለም',
        'Date, time, or timezone still incorrect',
        'Guyyaa, sa\'aatii ykn naannoo sa\'aatii ammallee sirrii miti',
        'ዕለት፣ ሰዓት ወይ ናይ ሰዓት ዞባ ኣሁን እውን ቅኑዕ ኣይኮነን',
      );

  String get openDateSettings => _t(
        'የቀን እና ሰዓት ቅንብር ክፈት',
        'Open date & time settings',
        'Qindaa\'ina guyyaa fi sa\'aatii bani',
        'ናይ ዕለትን ሰዓትን ቅንጥብ ክፈት',
      );

  String get checkDateAgain => _t(
        'እንደገና ይፈትሹ',
        'Check again',
        'Irra deebi\'ii ilaali',
        'ደጊምካ ፈትን',
      );

  // —— Login / Setup ——
  String get loginTitle => _t('ግባ', 'LOGIN', 'SEENI', 'እቶ');
  String get loginSubtitle => _t(
        'ኦፍላይን ካሺየር · ዊንዶውስ እና አንድሮይድ',
        'Offline cashier · Windows & Android',
        'Kaashiyeerii oflaayinii · Windows & Android',
        'ኦፍላይን ካሺየር · ዊንዶውስን ኣንድሮይድን',
      );

  String domainLabel(String d) =>
      _t('ዶሜይን: $d', 'Domain: $d', 'Domeenii: $d', 'ዶመይን: $d');

  String get signingIn => _t('በመግባት ላይ…', 'Signing in…', 'Seenaa jira…', 'ይኣቱ…');
  String get restoringSession =>
      _t('ክፍለ ጊዜ በመመለስ ላይ…', 'Restoring session…', 'Seeshinii deebisaa jira…', 'ክፍለ ግዜ ይመለስ…');

  String get cashierId => _t('የካሺየር መለያ', 'Cashier ID', 'ID Kaashiyeerii', 'መለለዪ ካሺየር');
  String get password => _t('የይለፍ ቃል', 'Password', 'Jecha iccitii', 'መሕለፊ ቃል');
  String get loginButton => _t('ግባ', 'Login', 'Seeni', 'እቶ');
  String get invalidCredentials => _t(
        'የካሺየር መለያ ወይም የይለፍ ቃል ትክክል አይደለም።',
        'Invalid cashier ID or password.',
        'ID ykn jecha iccitii dogoggora.',
        'መለለዪ ካሺየር ወይ መሕለፊ ቃል ጌጋ እዩ።',
      );
  String loginAttemptsRemaining(int remaining, int max) => _t(
        'የተሳሳተ የይለፍ ቃል። $remaining ሙከራ ቀርቷል (ከ $max)።',
        'Wrong password. You have $remaining of $max trials left.',
        'Jecha iccitii dogoggora. Yaalii $remaining / $max hafte.',
        'መሕለፊ ቃል ጌጋ። $remaining ካብ $max ፈተነ ተሪፉ።',
      );
  String get cashierAccountLocked => _t(
        'የካሺየር መለያ ተቆልፏል። በጣም ብዙ የተሳሳቱ ሙከራዎች ተደርገዋል።',
        'Cashier account is locked. Too many wrong password attempts.',
        'Akkaawuntii kaashiyeerii cufameera. Yaalii dogoggoraa hedduun raawwatame.',
        'ናይ ካሺየር ሕሳብ ተዓጽዩ። ብዙሕ ጌጋ ፈተነታት ተገይሩ።',
      );
  String get cashierAccountInactive => _t(
        'የካሺየር መለያ ንቁ አይደለም።',
        'Cashier account is not active.',
        'Akkaawuntii kaashiyeerii hin socho\'u.',
        'ናይ ካሺየር ሕሳብ ንጡፍ ኣይኮነን።',
      );

  String loginFailed(String error) => _t(
        'መግባት አልተሳካም: $error',
        'Login failed: $error',
        'Seenuun hin milkoofne: $error',
        'እታይ ኣይተኻእለን: $error',
      );

  String get noInternetConnection => _t(
        'ኢንተርኔት አልተገኘም።',
        'No internet connection.',
        'Interneetiin hin jiru.',
        'ኢንተርነት ኣይተረኽበን።',
      );
  String get connectionTimedOut => _t(
        'ግንኙነት ጊዜው አልፏል። እንደገና ይሞክሩ።',
        'Connection timed out. Please try again.',
        'Yeroon walqunnamtii darbe. Irra deebi\'ii yaali.',
        'ግዜ ምትእስሳር ተዛዚሙ። ደጊምካ ፈትን።',
      );
  String get serverUnreachable => _t(
        'ሰርቨር ሊደረስ አልተቻለም።',
        'Could not reach the server.',
        'Sarvarii ga\'uu hin dandeenye.',
        'ሰርቨር ክበጽሕ ኣይከኣለን።',
      );
  String get connectionProblem => _t(
        'ግንኙነት ችግር አለ። እንደገና ይሞክሩ።',
        'Connection problem. Please try again.',
        'Rakkoo walqunnamtii. Irra deebi\'ii yaali.',
        'ናይ ምትእስሳር ጸገም። ደጊምካ ፈትን።',
      );

  String get loginInfoWelcome => _t(
        'እንኳን ወደ Ethiomark Bingo በደህና መጡ',
        'Welcome to Ethiomark Bingo',
        'Baga gara Ethiomark Bingo dhufte',
        'ናብ Ethiomark Bingo ብደሓን መጻእኩም',
      );
  String get loginInfoTagline => _t(
        'ኦፍላይን ቢንጎ ካሺየር ስርዓት — ዊንዶውስ እና አንድሮይድ።',
        'Offline bingo cashier — Windows & Android.',
        'Kaashiyeerii bingoo oflaayinii — Windows & Android.',
        'ኦፍላይን ቢንጎ ካሺየር — ዊንዶውስን ኣንድሮይድን።',
      );
  String get loginInfoVersionLabel =>
      _t('ስሪት', 'Version', 'Gosa', 'ስሪት');
  String get loginInfoOurGamesTitle =>
      _t('የእኛ ጨዋታዎች', 'Our games', 'Taphoota keenya', 'ጸወታታትና');
  String get loginInfoOurGamesBody => _t(
        '• ቢንጎ — 75-ቁጥር ኦፍላይን ካሺየር (ይህ መተግበሪያ)\n'
        '• ኬኖ — ኦፍላይን ኬኖ ካሺየር\n'
        '• ስፒን — ኦፍላይን ስፒን ጨዋታ',
        '• Bingo — 75-number offline cashier (this app)\n'
        '• Keno — offline keno cashier\n'
        '• Spin — offline spin game',
        '• Bingo — kaashiyeerii oflaayinii lakkoofsa 75 (app kana)\n'
        '• Keno — kaashiyeerii keno oflaayinii\n'
        '• Spin — tapha naanna\'ii oflaayinii',
        '• ቢንጎ — 75-ቁጽሪ ኦፍላይን ካሺየር (እዚ ኣፕ ኢዩ)\n'
        '• ኬኖ — ኦፍላይን ኬኖ ካሺየር\n'
        '• ስፒን — ኦፍላይን ስፒን ጸወታ',
      );
  String get loginInfoGamesTitle =>
      _t('የጨዋታ ዓይነቶች', 'Game modes', 'Haalota tapha', 'ዓይነት ጸወታ');
  String get loginInfoGamesBody => _t(
        '• ክላሲክ 75-ቁጥር ቢንጎ\n'
        '• ብዙ የድል ቅርጾች (መስመር፣ L፣ T፣ X፣ ሙሉ ካርድ…)\n'
        '• ኦል-ኢን-ዋን — መስመር፣ ውጫዊ እና ውስጣዊ ማዕዘኖች\n'
        '• ብዙ ዋጋዎች (10–1000 ብር)',
        '• Classic 75-number bingo\n'
        '• Many win patterns (lines, L, T, X, full card…)\n'
        '• All-in-one — lines, outside & inside corners\n'
        '• Flexible stakes (10–1000 birr)',
        '• Bingoo lakkoofsa 75 kan caalmaa\n'
        '• Akkaataa mo\'aa hedduu (sarara, L, T, X, kaardii guutuu…)\n'
        '• Hunda tokkotti — sararoota fi gonkumoota\n'
        '• Kaffaltii adda addaa (10–1000 birr)',
        '• ክላሲክ 75-ቁጽሪ ቢንጎ\n'
        '• ብዙሕ ናይ ዓወት ቅርጺ (መስመር፣ L፣ T፣ X፣ ሙሉ ካርድ…)\n'
        '• ኩሉ-ኣብ-ሓደ — መስመራትን ጥዕናታትን\n'
        '• ዋጋታት (10–1000 ብር)',
      );
  String get loginInfoFeaturesTitle =>
      _t('ዋና ባህሪያት', 'Key features', 'Amaloota ijoo', 'ቀንዲ ባህርያት');
  String get loginInfoFeaturesBody => _t(
        '• ሙሉ በሙሉ ኦፍላይን — ኢንተርኔት አያስፈልግም\n'
        '• የዕለት ተዕለት ሪፖርት እና የቦርሳ አስተዳደር\n'
        '• በእጅ ወይም አውቶማቲክ ካርድ ማረጋገጥ\n'
        '• ብዙ ድምጾች · የቤት ድርሻ · ቦነስ ዙሮች\n'
        '• 5 ነጻ ሙከራ ዙሮች (0 ብር ቦርሳ)',
        '• Fully offline — no internet required\n'
        '• Daily reports & wallet management\n'
        '• Manual or automatic card checking\n'
        '• Multiple voices · house cut · bonus rounds\n'
        '• 5 free trial rounds (0 birr wallet)',
        '• Guutummaatti oflaayinii — interneetiin hin barbaachisu\n'
        '• Gabaasa guyyaa fi bulchiinsa kuusaa\n'
        '• Qorannoo kaardii harkaa ykn ofumaan\n'
        '• Sagalee hedduu · kutaa mana · boonasii\n'
        '• Raaundii yaali bilisaa 5 (kuusaa 0 birr)',
        '• ሙሉእ ኦፍላይን — ኢንተርነት የድሊ ኣይኮነን\n'
        '• መዓልታዊ ጸብጻብን ቦርሳን ምሕዳስ\n'
        '• ኢድ ወይ ኣውቶማቲክ ምፍታሽ ካርድ\n'
        '• ብዙሕ ድምጺ · ክፍሊት ቤት · ቦነስ\n'
        '• 5 ነጻ ምፍታሽ ዙር (0 ብር ቦርሳ)',
      );
  String get loginInfoRemoteTitle => _t(
        'ከሰርቨር የተላከ ማስታወቂያ',
        'Notice from server',
        'Beeksisa sarvarii irraa',
        'ካብ ሰርቨር ዝመጸ ሓበሬታ',
      );
  String get loginInfoRefresh => _t(
        'አድስ',
        'Refresh',
        'Haaromsi',
        'ኣድስ',
      );
  String get loginInfoRefreshHint => _t(
        'ከሰርቨር ማስታወቂያ ይጫኑ',
        'Load notice from server',
        'Beeksisa sarvarii fe\'i',
        'ካብ ሰርቨር ሓበሬታ ጽዕነት',
      );
  String get loginInfoNoRemoteMessage => _t(
        'ንቁ ማስታወቂያ የለም',
        'No active notice',
        'Beeksisni hin jiru',
        'ንቑሕ ሓበሬታ የለን',
      );
  String loginInfoPageOf(int page, int total) => _t(
        'ገጽ $page ከ$total',
        'Page $page of $total',
        'Fuula $page/$total',
        'ገጽ $page ካብ $total',
      );
  String get loginInfoPrevious => _t('ቀዳሚ', 'Previous', 'Dura', 'ቅድሚ');
  String get loginInfoNext => _t('ቀጣይ', 'Next', 'Itti aanu', 'ቀጻሊ');
  String get loginInfoCachedHint => _t(
        'ከመሸጎጫ የተጫነ',
        'Loaded from offline cache',
        'Kuufama irraa',
        'ካብ ካሽ ተጻዊቱ',
      );
  String loginInfoSeeNotices([int count = 0]) => count > 0
      ? _t(
          'ማስታወቂያዎችን ይመልከቱ ($count)',
          'See notices ($count)',
          'Beeksisa ilaali ($count)',
          'ሓበሬታ ርአ ($count)',
        )
      : _t(
          'ማስታወቂያዎችን ይመልከቱ',
          'See notices',
          'Beeksisa ilaali',
          'ሓበሬታ ርአ',
        );
  String get loginInfoShowLess => _t(
        'አሳንስ',
        'Show less',
        'Xiqqeessi',
        'ኣጉድስ',
      );
  String get loginInfoMore => _t('ተጨማሪ', 'More', 'Dabalata', 'ተወሳኺ');

  String get setupTitle => _t('ማዋቀር', 'SETUP', 'QOPHEESSA', 'ምድላው');
  String get setupSubtitle =>
      _t('ለመጀመሪያ ጊዜ ምዝገባ', 'First time registration', 'Galmeessa jalqabaa', 'መዝገብ መጀመርያ');
  String get setupDescription => _t(
        'ከአድሚን ሰርቨር የተሰጠዎትን የካሺየር መለያ እና የይለፍ ቃል ያስገቡ። ቀሪ ሂሳብን በኋላ ከመገለጫ ይሙሉ።',
        'Enter your Cashier ID and password from the admin server. Top up wallet balance later from Profile.',
        'ID fi jecha iccitii kaashiyeerii server admin irraa galchi. Hanga booda Profile irraa kuusaa guuti.',
        'መለለዪ ካሺየርን መሕለፊ ቃልን ካብ ኣድሚን ሰርቨር ኣእትዉ። ቀሪ ሂሳብ ድሕሪ ካብ መገለጺ ይሙሉ።',
      );
  String get newCashierContact =>
      _t('አዲስ ካሺየር? ያግኙን:', 'New cashier? Contact us:', 'Kaashiyeerii haaraa? Nu qunnamaa:', 'ሓድስ ካሺየር? ተወከሱና:');
  String get partnerId => _t('የአጋር መለያ', 'Partner ID', 'ID Partner', 'መለለዪ መሻርኽ');
  String get createAccount => _t('መለያ ፍጠር', 'Create account', 'Akkaawuntii uumi', 'ኣካውንት ፍጠር');
  String get creatingAccount =>
      _t('መለያ በመፍጠር ላይ…', 'Creating account…', 'Akkaawuntii uumaa jira…', 'ኣካውንት ይፈጥር…');
  String get storagePermissionRequired => _t(
        'ለመቀጠል የሚያስፈልገው ፈቃድ ያስፈልጋል። በቅንብሮች ውስጥ ፍቀዱ፣ ከዚያ እንደገና ይሞክሩ።',
        'Permission is required to continue. Please allow it in settings, then try again.',
        'Itti fufuuf hayyama barbaachisa. Settings keessatti hayyami, booda irra deebi\'i.',
        'ንምቕጻል ፍቓድ ኣድላዪ እዩ። ኣብ ቅንጅታት ፍቀድ፣ ድሕሪኡ ደጊምካ ፈትን።',
      );
  String get cashierPasswordRequired => _t(
        'የካሺየር መለያ እና የይለፍ ቃል ያስፈልጋሉ።',
        'Cashier ID and password are required.',
        'ID fi jecha iccitii barbaachisa.',
        'መለለዪ ካሺየርን መሕለፊ ቃል ኣድላዪ እዩ።',
      );
  String get partnerIdPositive => _t(
        'የአጋር መለያ ቁጥር መሆን አለበት።',
        'Partner ID must be a positive number.',
        'ID Partner lakkoofsa poozatiivii ta\'uu qaba.',
        'መለለዪ መሻርኽ ቁጽሪ ክኸውን ኣለዎ።',
      );
  String registrationFailed(String error) => _t(
        'ምዝገባ አልተሳካም: $error',
        'Registration failed: $error',
        'Galmeessuun hin milkoofne: $error',
        'ምዝገብ ኣይተኻእለን: $error',
      );

  // —— Game flow ——
  String get loadingGame => _t('ጨዋታ በመጫን ላይ…', 'Loading game…', 'Tapha fe\'aa jira…', 'ጸወታ ይጽዕን…');
  String couldNotLoadGame(String error) => _t(
        'ጨዋታ ማስገባት አልተቻለም: $error',
        'Could not load game: $error',
        'Tapha fe\'uun hin danda\'amne: $error',
        'ጸወታ ክጽዕን ኣይተኻእለን: $error',
      );
  String get roundAlreadyStarted => _t(
        'ዙሩ ተጀምሯል — ካርዶችን መቀየር አይቻልም።',
        'Round already started — cannot change cards.',
        'Raaundiin jalqabee jira — kaardii jijjiiruun hin danda\'amu.',
        'ዙር ጀሚሩ — ካርድ ክትቀይር ኣይትኽእልን።',
      );

  // —— Start round modal ——
  String get start => _t('ጀምር', 'Start', 'Jalqabi', 'ጀምር');
  String get startingRound =>
      _t('ዙር በመጀመር ላይ…', 'Starting round…', 'Raaundii jalqabsiisaa jira…', 'ዙር ይጅምር…');
  String get registerShort => _t('መዝገብ', 'Register', 'Galmeessi', 'ኣመዝግብ');
  String get registerCard =>
      _t('ካርድ መዝገብ', 'Register Card', 'Kaardii Galmeessi', 'ካርድ ኣመዝግብ');
  String get packageRunningLow => _t(
        'ሒሳብዎ እያለቀ ነው!',
        'Your balance is running out!',
        'Kuusaan kee ni dhumaa jira!',
        'ቦርሳኻ ይወድቕ ኣሎ!',
      );

  ({String quote, String author}) startRoundQuote(int roundNumber) {
    final quotes = [
      (
        am: 'እያንዳንዱ የተጠራ ቁጥር አዲስ የማሸነፍ እድል ነው።',
        en: 'Every number called is a fresh chance to win.',
        om: 'Lakkoofsi tokkoon tokkoon waamamu carraa mo\'aa haaraa dha.',
        ti: 'ነፍሲ ወከፍ ዝተጸወዐ ቁጽሪ ሓድሽ ዕድል ምዕዋት እዩ።',
      ),
      (
        am: 'እድል ደፋሮችን ይወዳል — ትኩረት ይስጡ እና ካርድዎን ይምረጡ።',
        en: 'Fortune favors the bold — stay sharp and mark your card.',
        om: 'Carraan namoota cimoo jaallata — xiyyeeffannaa qabi kaardii kee mallattoo godhi.',
        ti: 'ዕድል ንደፋር ይፈቱ — ትኩረት ግበሩ ካርድኩም ምልክት ግበሩ።',
      ),
      (
        am: 'የእርስዎ የእድል ጊዜ አንድ ቦል ብቻ ርቀት ላይ ሊሆን ይችላል።',
        en: 'Your lucky moment might be just one ball away.',
        om: 'Yeroo carraa kee kubbaa tokkoo qofa fagaatee jiraachuu danda\'a.',
        ti: 'ናይ ዕድልኩም ግዜ ሓንቲ ኳድር ጥራይ ርሕቀት ክኸውን ይኽእል እዩ።',
      ),
      (
        am: 'ትዕግስት፣ ትኩረት እና ትንሽ እድል — አሸናፊዎች እንደዚህ ይጫወታሉ።',
        en: 'Patience, focus, and a little luck — that is how champions play.',
        om: 'Obsa, xiyyeeffannaa fi carraa xiqqoo — akkasitti mo\'attoonni taphatu.',
        ti: 'ትዕግስት፣ ትኩረትን ቁሩብ ዕድልን — ክልኣውያን ከምዚ ይጻወቱ።',
      ),
      (
        am: 'በካርድዎ ይተማመኑ። ቀጣዩ ጥሪ ሁሉን ሊቀይር ይችላል።',
        en: 'Believe in your card. The next call could change everything.',
        om: 'Kaardii kee amani. Waamichi itti aanu waan hunda jijjiiruu danda\'a.',
        ti: 'ኣብ ካርድኩም ተኣምኑ። ዝቕጽል ጻዕሪ ኩሉ ክቕይር ይኽእል እዩ።',
      ),
      (
        am: 'ታላቅ ተጫዋቾች እድል አይከተሉም — ሲመጣ ዝግጁ ናቸው።',
        en: 'Great players do not chase luck — they are ready when it arrives.',
        om: 'Taphattoonni gurguddoon carraa hin hordofan — yeroo dhufu qophaa\'an.',
        ti: 'ዓበይቲ ተጻዋትቲ ዕድል ኣይከተሉን — ምስ ዝመጽእ ድሉው እዮም።',
      ),
    ];
    final q = quotes[roundNumber % quotes.length];
    return (
      quote: _t(q.am, q.en, q.om, q.ti),
      author: appName,
    );
  }

  // —— Check card modal ——
  String get checkingCard => _t('ካርድ በመፈተሽ ላይ…', 'Checking card…', 'Kaardii qoraa jira…', 'ካርድ ይፈትሽ…');
  String get good => _t('ጥሩ', 'Good', 'Gaarii', 'ጽቡቕ');
  String get notBingo => _t('አይደለም', 'Not', 'Hin ta\'u', 'ኣይኮነን');
  String get tooLateBtn => _t('ዘግይቷል', 'Too late', 'Dhiyoo', 'ዘግይቱ');
  String get seePatternBtn =>
      _t('ቅርጽ ተመልከት', 'See pattern', 'Akkaataa ilaali', 'ቅርጺ ርአ');
  String get hidePatternBtn =>
      _t('ቅርጽ ደብቅ', 'Hide pattern', 'Akkaataa dhoksi', 'ቅርጺ ሕብእ');
  String get tooLateClaim => _t('በጣም ዘግይቷል!', 'Too late!', 'Dhiyoo dha!', 'ዘግይቱ!');
  String get lock => _t('ቆልፍ', 'Lock', 'Cufti', 'ዕጸው');
  String get cardLocked => _t('ካርዱ ተቆልፏል', 'Card is locked', 'Kaardiin cufameera', 'ካርድ ተዓጽዩ');
  String get notWinner => _t('አሸናፊ አይደለም', 'Not a winner', 'Mo\'aa miti', 'ዓዋተኛ ኣይኮነን');
  String get reviewCard =>
      _t('ካርዱን ይመልከቱ እና ካሸነፈ Good ይጫኑ።', 'Review the card and tap Good if it wins.', 'Kaardii ilaali yoo mo\'ate Good tuqi.', 'ካርድ ርአ እንተ ዓወተ Good ጠውቑ።');
  String bingoLines(int lines) => _t(
        'ቢንጎ! · $lines መስመር${lines == 1 ? '' : 'ዎች'}',
        'BINGO! · $lines line${lines == 1 ? '' : 's'}',
        'BINGO! · sarara $lines',
        'ቢንጎ! · $lines መስመር',
      );
  String bingoPattern(String pattern) => 'BINGO! · $pattern';

  String allInOneWinMessage({required int winningLines, required int bonusWin}) {
    if (winningLines > 0) return bingoLines(winningLines);
    return switch (bonusWin) {
      1 => bingoPattern(allInOneOutsideCorners),
      2 => bingoPattern(allInOneInsideCorners),
      _ => bingoPattern(patternName(14)),
    };
  }

  String get patternHelpTitle => _t(
        'የድል ቅርጾች መመሪያ',
        'Win patterns guide',
        'Qajeelfama akkaataa mo\'aa',
        'መምርሒ ኣይነት ዓወት',
      );

  String get patternHelpSectionDefault => _t(
        'ነባሪ ቅርጽ',
        'Default pattern',
        'Akkaataa baramaa',
        'ነባሪ ቅርጺ',
      );

  String get patternHelpSectionLines => _t(
        'የመስመር ቅርጾች',
        'Line patterns',
        'Akkaataa sararaa',
        'ኣይነት መስመር',
      );

  String get patternHelpSectionShapes => _t(
        'ቅርጽ እና ልዩ ቅርጾች',
        'Shape & special patterns',
        'Akkaataa bifa & addaa',
        'ቅርጺን ፍሉይ ቅርጺን',
      );

  String get patternHelpFreeSpaceNote => _t(
        '★ የነጻ ቦታ ነው — ሁልጊዜ እንደተመዘገበ ይቆጠራል።',
        '★ is the free space — it always counts as marked.',
        '★ bakka bilisaa dha — yeroo hunda akka mallatteeffameetti ni lakkaa\'ama.',
        '★ ነጻ ቦታ እዩ — ኩሉ ግዜ ከም ዝተመዝገበ ይቖጸር።',
      );

  String patternDescription(int pattern) => switch (pattern) {
        14 => _t(
              'ነባሪ ቅርጽ። ተጫዋቹ ማንኛውም አንድ ሙሉ ረድፍ፣ አምድ ወይም አንደኛ፣ ወይም አራቱን ውጭ ማእዘናት (B1, O1, B5, O5)፣ ወይም ከነጻ ቦታው ዙሪያ ያሉ አራት ውስጥ ማእዘናት (I2, G2, I4, G4) ሲያጠናቅቅ ያሸንፋል።',
              'The default pattern. Win by completing any one full row, column, or diagonal, OR all four outside corners (B1, O1, B5, O5), OR the four inside corners around the free space (I2, G2, I4, G4).',
              'Akkaataa baramaa. Sarara, tarree ykn daagonalii tokko guutuu, ykn gonkumaa afur ala, ykn gonkumaa afur bakka bilisaa naannoo guutuu yoo taate mo\'ata.',
              'ነባሪ ቅርጺ። ሓንቲ ምሉእ ረድፍ፣ ንዑስ፣ ኣንደኛ፣ ወይ ኣርባዕተ ደገ ጥራይ፣ ወይ ኣብ ዙሪያ ነጻ ቦታ ኣርባዕተ ውሽጢ ጥራይ ምስ ትዛዘም ትዕወት።',
            ),
        1 => _t(
              'ማንኛውም አንድ ሙሉ ረድፍ፣ አምድ ወይም አንደኛ ሲጠናቀቅ ያሸንፋል።',
              'Win when any single horizontal row, vertical column, or diagonal is fully marked.',
              'Sarara cinaatti, dheerina ykn daagonalii tokko guutuu yoo taate mo\'ata.',
              'ሓንቲ ምሉእ ረድፍ፣ ንዑስ ወይ ኣንደኛ ምስ ትዛዘም ትዕወት።',
            ),
        2 => _t(
              'ማንኛውም ሁለት ሙሉ መስመሮች (ረድፍ፣ አምድ ወይም አንደኛ) በአንድ ጊዜ ሲጠናቀቁ ያሸንፋል።',
              'Win when any two complete lines (rows, columns, or diagonals) are marked at the same time.',
              'Sararoota lama guutuu yeroo tokkotti yoo mallatteeffatan mo\'ata.',
              'ክልተ ምሉእ መስመራት ምስ ትዛዘማ ትዕወት።',
            ),
        3 => _t(
              'ማንኛውም ሶስት ሙሉ መስመሮች በአንድ ጊዜ ሲጠናቀቁ ያሸንፋል።',
              'Win when any three complete lines (rows, columns, or diagonals) are marked at the same time.',
              'Sararoota sadii guutuu yeroo tokkotti yoo mallatteeffatan mo\'ata.',
              'ሰለስተ ምሉእ መስመራት ምስ ትዛዘማ ትዕወት።',
            ),
        7 => _t(
              'በካርዱ ላይ ያሉ ሁሉም ቁጥሮች (25 ሳell) መመዘገብ አለባቸው። ሙሉ ካርድ።',
              'Every number on the card must be marked — all 25 cells. Full card blackout.',
              'Lakkoofsi kaardii hunda mallatteeffamuu qaba — sellii 25 hunda. Kaardii guutuu.',
              'ኩሉ ቁጽሪ ካርድ ክምልከት ኣለዎ — 25 ሳell ኩሉ። ምሉእ ካርድ።',
            ),
        8 => _t(
              'ማንኛውም አንድ ሙሉ አምድ (B, I, N, G, ወይም O) ሲጠናቀቅ ያሸንፋል።',
              'Win when any single vertical column (B, I, N, G, or O) is fully marked.',
              'Tarree dhaabbataa tokko (B, I, N, G, ykn O) guutuu yoo taate mo\'ata.',
              'ሓንቲ ምሉእ ንዑስ ዓምዲ (B, I, N, G, ወይ O) ምስ ትዛዘም ትዕወት።',
            ),
        9 => _t(
              'ማንኛውም አንድ ሙሉ ረድፍ (ረድፍ 1–5) ሲጠናቀቅ ያሸንፋል።',
              'Win when any single horizontal row (row 1–5) is fully marked.',
              'Sarara cinaatti tokko (tarree 1–5) guutuu yoo taate mo\'ata.',
              'ሓንቲ ምሉእ ረድፍ (ረድፍ 1–5) ምስ ትዛዘም ትዕወት።',
            ),
        5 => _t(
              'ከላይኛው ረድፍ (ረድፍ 1) እና መሃል N አምድ ሙሉ ሲሆኑ ያሸንፋል — ቅርጽ T።',
              'Mark the entire top row plus the full center N column — T shape.',
              'Sarara gubbaa guutuu fi tarree N gidduu guutuu mallatteeffadhu — bifa T.',
              'ላዕለዋይ ረድፍን ምሉእ N ዓምድን ኣመልክት — ቅርጺ T።',
            ),
        10 => _t(
              'የታችኛው ረድፍ (ረድፍ 5) እና መሃል N አምድ ሙሉ ሲሆኑ ያሸንፋል — reverse T።',
              'Mark the entire bottom row plus the full center N column — reverse T.',
              'Sarara jala guutuu fi tarree N gidduu guutuu mallatteeffadhu — reverse T.',
              'ታሕተኛ ረድፍን ምሉእ N ዓምድን ኣመልክት — reverse T።',
            ),
        6 => _t(
              'ሁለቱም አንደኞች በነጻ ቦታው ያሻጋራሉ — ቅርጽ X።',
              'Both diagonals crossing through the free space must be marked — X shape.',
              'Daagonaloonni lamaan bakka bilisaa keessa darbu mallatteeffamuu qabu — bifa X.',
              'ክልተ ኣንደኛታት ብነጻ ቦታ ዝሓሉ ክምልከቱ ኣለዎን — ቅርጺ X።',
            ),
        4 => _t(
              'የግራ B አምድ ሙሉ እና የታችኛው ረድፍ — ቅርጽ L።',
              'Mark the full left B column and the entire bottom row — L shape.',
              'Tarree B bitaa guutuu fi sarara jala guutuu mallatteeffadhu — bifa L.',
              'ምሉእ B ዓምድን ታሕተኛ ረድፍን ኣመልክት — ቅርጺ L።',
            ),
        11 => _t(
              'የቀኝ O አምድ ሙሉ እና የታችኛው ረድፍ — reverse L።',
              'Mark the full right O column and the entire bottom row — reverse L.',
              'Tarree O mirgaa guutuu fi sarara jala guutuu mallatteeffadhu — reverse L.',
              'ምሉእ O ዓምድን ታሕተኛ ረድፍን ኣመልክት — reverse L።',
            ),
        12 => _t(
              'ከላይኛው ከፍተኛ ክፍል — ረድፍ 1 እና 2 ሙሉ ሲሆኑ ያሸንፋል።',
              'Mark the top half of the card — rows 1 and 2 must be fully covered.',
              'Walakkaa gubbaa kaardii mallatteeffadhu — tarree 1 fi 2 guutuu ta\'uu qabu.',
              'ላዕለዋይ ፍርቂ ካርድ — ረድፍ 1ን 2ን ምሉእ ክኸውኑ ኣለዎን።',
            ),
        13 => _t(
              'የታችኛው ከፍተኛ ክፍል — ረድፍ 4 እና 5 ሙሉ ሲሆኑ ያሸንፋል።',
              'Mark the bottom half of the card — rows 4 and 5 must be fully covered.',
              'Walakkaa jala kaardii mallatteeffadhu — tarree 4 fi 5 guutuu ta\'uu qabu.',
              'ታሕተኛ ፍርቂ ካርድ — ረድፍ 4ን 5ን ምሉእ ክኸውኑ ኣለዎን።',
            ),
        _ => '',
      };

  String get allInOneHelpTitle => patternHelpTitle;

  String get allInOneHelpIntro => _t(
        'ማንኛውም አንድ መስመር (ረድፍ፣ አምድ ወይም አንደኛ) ወይም ከዚህ በታች ያሉትን ማእዘናት ሲያጠናቅቁ ያሸንፋሉ።',
        'Win with any one complete line (row, column, or diagonal), or by completing either corner pattern below.',
        'Sarara tokko guutuu ykn naannoo gonkumaa armaan gadii guutuu yoo taate mo\'atta.',
        'ሓንቲ ምሉእ መስመር (ረድፍ፣ ንዑስ ወይ ኣንደኛ) ወይ ካብ ታሕቲ ዝተሰየሙ ጥራይ ምስ ትዛዘሙ ትዕወት።',
      );

  String get allInOneOutsideTitle => _t(
        'ውጭ አራት ማእዘን',
        'Outside four corners',
        'Gonkumaa afur ala',
        'ደገ ኣርባዕተ ጥራይ',
      );

  String get allInOneInsideTitle => _t(
        'ውስጥ አራት ማእዘን',
        'Inside four corners',
        'Gonkumaa afur keessaa',
        'ውሽጢ ኣርባዕተ ጥራይ',
      );

  String get allInOneOutsideCorners => _t(
        'ውጭ ማእዘን',
        'outside corners',
        'gonkumaa ala',
        'ደገ ጥራይ',
      );

  String get allInOneInsideCorners => _t(
        'ውስጥ ማእዘን',
        'inside corners',
        'gonkumaa keessaa',
        'ውሽጢ ጥራይ',
      );

  String get patternHelpTooltip => _t(
        'የቅርጽ ማብራሪያ',
        'Pattern help',
        'Gargaarsa akkaataa',
        'ሓገዝ ቅርጺ',
      );

  String get patternViewBtn => _t(
        'ቅርጽ',
        'Pattern',
        'Akkaataa',
        'ቅርጺ',
      );

  String get patternViewTitle => _t(
        'የዚህ ዙር ድል ቅርጽ',
        'Round win pattern',
        'Akkaataa mo\'aa marsaa kanaa',
        'ናይዚ ዙር ዓወት ቅርጺ',
      );

  String get patternSelectToPreview => _t(
        'ቅርጽ ይምረጡ እንዲሳይ በቀጥታ አኒሜሽን ይመልከቱ',
        'Select a pattern to see its live animation',
        'Akkaataa filadhu animation live ilaali',
        'ቅርጺ ምረጽ ንቀጥታ ኣኒሜሽን ርአ',
      );

  String patternAnimProgress(int index, int total, int percent) => _t(
        'እያሳያ $index ከ $total ($percent%) — ሲጨርስ ይቀጥል',
        'Showing $index of $total ($percent%) — loops when finished',
        'Agarsiisa $index kan $total ($percent%) — xumuramee itti fufa',
        'ዘርዝሕ $index ካብ $total ($percent%) — ምስ ዛዘም ይቀጽል',
      );

  String get patternAnimLoops => _t(
        'አኒሜሽኑ ሲጨርስ ይቀጥል',
        'Animation loops when finished',
        'Animation xumuramee itti fufa',
        'ኣኒሜሽን ምስ ዛዘም ይቀጽል',
      );

  String patternAnimComboHint(int count) => _t(
        'ሁሉ $count ትክክለኛ ድርድሮች አንድ በአንድ ይታዩ',
        'Plays all $count winning combinations one by one',
        'Waluma $count combination tokko tokkoon agarsiisa',
        'ኩሉ $count ዕድላዊ ጥራይታት ሓንሓን መልክት',
      );

  String get helpTabHelps => _t(
        'እገዛ',
        'Helps',
        'Gargaarsa',
        'ሓገዝ',
      );

  String get helpTabAbout => _t(
        'ስለ መተግበሪያ',
        'About',
        'Waa\'ee',
        'ዝርዝር',
      );

  String get checkCardHelpTitle => _t(
        'የካርድ ፍተሻ እገዛ',
        'Card check help',
        'Gargaarsa qormaata kaardii',
        'ሓገዝ ፍተሻ ካርድ',
      );
  String get checkCardHelpTooltip => _t(
        'እገዛ እና ማብራሪያ',
        'Help & guide',
        'Gargaarsa fi qajeelfama',
        'ሓገዝን መምርሒን',
      );
  String get checkCardHelpTabScreen => _t('ማያ ገጽ', 'Screen', 'Iskiriinii', 'ስክሪን');
  String get checkCardHelpTabPatterns =>
      _t('ቅርጾች', 'Patterns', 'Akkaataa', 'ቅርጺታት');
  String get checkCardHelpTabSettings =>
      _t('ቅንብሮች', 'Settings', 'Qindaa\'ina', 'ቅንጥብታት');
  String get checkCardHelpColorsTitle => _t(
        'የቀለም ምልክቶች',
        'Color guide',
        'Mallattoo halluu',
        'መምርሒ ሕብሪ',
      );
  String get checkCardHelpColorsBody => _t(
        '• አረንጓዴ — አሸናፊ ቅርጽ (ትክክለኛ ወይም ዘግይቷል)\n'
        '• ቀይ — ቀድሞ የተጠሩ ቁጥሮች\n'
        '• ሰማያዊ — የመጨረሻው የተጠራ ቁጥር (ይብራራል)\n'
        '• ነጭ — ገና ያልተጠሩ ቁጥሮች',
        '• Green — winning pattern (valid or too late)\n'
        '• Red — numbers already called\n'
        '• Blue — last ball called (blinks)\n'
        '• White — numbers not called yet',
        '• Magariisa — akkaataa mo\'aa (sirrii ykn dhiyoo)\n'
        '• Diimaa — lakkoofsa dura waamame\n'
        '• Cuquliisa — lakkoofsa dhumaa waamame (ni ifa)\n'
        '• Adii — lakkoofsa ammallee hin waamamne',
        '• ኣረንጓዴ — ዓዋተኛ ቅርጺ (ቅኑዕ ወይ ዘግይቱ)\n'
        '• ቀይሕ — ዝሓለፉ ዝተጻዕሩ ቁጽርታት\n'
        '• ሰማያዊ — ናይ መወዳእታ ዝተጻዕረ ቁጽሪ (ይብርሃ)\n'
        '• ጻዕዳ — ዘይተጻዕሩ ቁጽርታት',
      );
  String get checkCardHelpButtonsTitle => _t(
        'አዝራሮች',
        'Buttons',
        'Qabduu',
        'ኣዝራራት',
      );
  String get checkCardHelpButtonsBody => _t(
        '• ጥሩ — ትክክለኛ አሸናፊ፤ ድምጽ ይጫወታል\n'
        '• አይደለም — አሸናፊ አይደለም\n'
        '• ዘግይቷል — ቅርጹ ተሟልቷል ነገር ግን በጊዜው ቢንጎ አልተነገረም\n'
        '• ቆልፍ — ካርዱን ለዚህ ዙር ያግዳል\n'
        '• ቅርጽ ተመልከት / ደብቅ — ቅርጹ በየትኛው ጻዕቂ እንደተሟላ ያሳያል (አረንጓዴ)',
        '• Good — valid winner; plays a sound\n'
        '• Not — not a winner\n'
        '• Too late — pattern was complete but Bingo was not called in time\n'
        '• Lock — blocks this card for the round\n'
        '• See / Hide pattern — shows when the pattern first completed (green)',
        '• Good — mo\'aa sirrii; sagalee taphata\n'
        '• Not — mo\'aa miti\n'
        '• Dhiyoo — akkaataan xumurame garuu yeroo hin taane Bingo hin jedhamne\n'
        '• Lock — kaardii raaundii kanaaf cufa\n'
        '• Akkaataa ilaali / dhoksi — yeroo akkaataan jalqabee xumurame agarsiisa (magariisa)',
        '• Good — ቅኑዕ ዓዋተኛ፤ ድምጺ ይደሊ\n'
        '• Not — ዓዋተኛ ኣይኮነን\n'
        '• Too late — ቅርጺ ተዛዚሙ ግን ብግዜ ቢንጎ ኣይተባልን\n'
        '• Lock — ካርድ ንዚ ዙር ይዕጸው\n'
        '• ቅርጺ ርአ / ሕብእ — ቅርጺ ኣበይ ከም ዝተዛዘመ ይሕብኦ (ኣረንጓዴ)',
      );
  String get checkCardHelpSettingsIntro => _t(
        'ከጨዋታ ቅንብሮች (በታች መስመር ወይም ቅንብሮች)፡',
        'From play settings (bottom bar or settings icon):',
        'Qindaa\'ina taphaa (bar gadii ykn mallattoo qindaa\'inaa):',
        'ካብ ቅንጥብታት ጸወታ (ታሕቲ ባር ወይ ኣዝራር ቅንጥብታት):',
      );

  String tooLate(int calls, int limit) => _t(
        'በጣም ዘግይቷል! · ቅርጹ $calls ቁጥር${calls == 1 ? '' : 'ዎች'} በፊት ዝግጁ ነበር',
        'Too late! · Pattern was ready $calls call${calls == 1 ? '' : 's'} ago',
        'Dhiyoo dha! · Akkaataan waggaa $calls dura qophaa\'e',
        'ዘግይቱ! · ቅርጺ $calls ጻዕሪ ቅድሚ ድሉው ነበረ',
      );
  String tooLateForMode(BingoClaimMode mode) => switch (mode) {
        BingoClaimMode.allowLaterPatterns => _t(
              'ዘግይቷል — ያ ዕድል አልፏል። ለአዲስ የማሸነፊያ ቅርጽ ይጠብቁ።',
              'Too late — that winning opportunity has passed. Wait for a new winning pattern.',
              'Yeroon darbeera — akkaataa moo\'annoo haaraa eegaa.',
              'ዘግይቱ — እቲ ዕድል ሓሊፉ። ንሓድሽ ቅርጺ ዓወት ተጸበዩ።',
            ),
        BingoClaimMode.disqualifyOnMiss => _t(
              'ዘግይቷል — ካርዱ ለዚህ ጨዋታ ተቆልፏል / ማሸነፍ አይችልም።',
              'Too late — this card is locked and cannot win again this game.',
              'Yeroon darbeera — kaardiin cufamee tapha kana keessatti moo\'achuu hin danda\'u.',
              'ዘግይቱ — እዚ ካርድ ንዚ ጸወታ ተዓጽዩ ክዕውት ኣይኽእልን።',
            ),
        BingoClaimMode.noRestriction => tooLate(0, -1),
      };
  String get lateClaimHint => _t(
        'ተጫዋቹ ቅርጹ ሲጠናቀቅ በሰዓቱ ቢንጎ መናገር አለበት።',
        'Player must say Bingo on time when the pattern is ready.',
        'Taphataan yeroo akkaataan qophaa\'uuf yeroon Bingo jedhuu qaba.',
        'ተጻዋቲ ቅርጺ ምስ ዝተዛዘመ በግዜ ቢንጎ ክብል ኣለዎ።',
      );
  String latePatternAtCall(int callNumber) => _t(
        'ቅርጹ በ $callNumberኛው ጻዕቂ ተሟልቷል (አረንጓዴ)',
        'Pattern completed on call $callNumber (green)',
        'Akkaataan waggaa $callNumber irratti xumurame (magariisa)',
        'ቅርጺ ኣብ $callNumber ጻዕሪ ተዛዚሙ (ኣረንጓዴ)',
      );
  String get roundLabel => _t('ዙር ', 'Round ', 'Raaundii ', 'ዙር ');
  String get cardLabel => _t('ካርድ : ', 'Card : ', 'Kaardii : ', 'ካርድ : ');

  // —— Play screen ——
  String get bingo => _t('ቢንጎ', 'BINGO', 'BINGO', 'ቢንጎ');
  String get stop => _t('አቁም', 'STOP', 'Dhaabi', 'ኣቋርጽ');
  String get shuffle => _t('ቀልብ', 'Shuffle', 'Makaa', 'ደብስ');
  String get finish => _t('ጨርስ', 'Finish', 'Xumuri', 'ዛዘም');
  String get settings => _t('ቅንብሮች', 'Settings', 'Qindaa\'ina', 'ቅንጥብታት');
  String get check => _t('ፈትሽ', 'Check', 'Qoradhu', 'ፈትሽ');
  String get speed => _t('ፍጥነት', 'Speed', 'Saffisa', 'ፍጥነት');
  String get cardNumberHint => _t('ካርድ #', 'Card #', 'Kaardii #', 'ካርድ #');
  String get loadingRound => _t('ዙር በመጫን ላይ…', 'Loading round…', 'Raaundii fe\'aa jira…', 'ዙር ይጽዕን…');
  String get preparingGame =>
      _t('ጨዋታ በማዘጋጀት ላይ…', 'Preparing game…', 'Tapha qopheessaa jira…', 'ጸወታ ይዳለይ…');
  String get cardNotRegistered => _t(
        'ካርዱ ለዚህ ዙር አልተመዘገበም።',
        'Card not registered for this round.',
        'Kaardiin raaundii kanaaf hin galmoofne.',
        'ካርድ ንዚ ዙር ኣይተመዝገበን።',
      );
  String get couldNotSaveDrawSpeed => _t(
        'የመጥራት ፍጥነት ማስቀመጥ አልተቻለም።',
        'Could not save draw speed.',
        'Saffisa baasuu olkaa\'uu hin danda\'amne.',
        'ፍጥነት ምጥራት ክትዓቅም ኣይተኻእለን።',
      );
  String get shufflingBlocked =>
      _t('ቀልብ እስኪጨርስ ድረስ ይጠብቁ።', 'Wait until shuffling finishes.', 'Makaan xumuramutti eegi.', 'ደብስ ክውድእ ተጸበ።');
  String get startBeforeCheck =>
      _t('ካርድ ከመፈተሽ በፊት ዙሩን ይጀምሩ።', 'Start the round before checking a card.', 'Kaardii qoruu dura raaundii jalqabi.', 'ካርድ ቅድሚ ምፍታሽ ዙር ጀምር።');
  String get stopBeforeCheck =>
      _t('ካርድ ከመፈተሽ በፊት ጨዋታውን ያቁሙ።', 'Stop the game before checking a card.', 'Kaardii qoruu dura tapha dhaabi.', 'ካርድ ቅድሚ ምፍታሽ ጸወታ ኣቋርጽ።');
  String get startBeforeShuffle =>
      _t('ቀልብ ከመስራት በፊት ዙሩን ይጀምሩ።', 'Start the round before shuffling.', 'Makaa dura raaundii jalqabi.', 'ደብስ ቅድሚ ምስራሕ ዙር ጀምር።');
  String get stopBeforeShuffle =>
      _t('ቀልብ ከመስራት በፊት ጨዋታውን ያቁሙ።', 'Stop the game before shuffling.', 'Makaa dura tapha dhaabi.', 'ደብስ ቅድሒ ምስራሕ ጸወታ ኣቋርጽ።');
  String get startBeforeFinish =>
      _t('ከመጨረስ በፊት ዙሩን ይጀምሩ።', 'Start the round before finishing.', 'Xumuraa dura raaundii jalqabi.', 'ቅድሚ ምዛዘም ዙር ጀምር።');
  String get stopBeforeFinish =>
      _t('ዙሩን ከመጨረስ በፊት ጨዋታውን ያቁሙ።', 'Stop the game before finishing the round.', 'Raaundii xumuraa dura tapha dhaabi.', 'ዙር ቅድሚ ምዛዘም ጸወታ ኣቋርጽ።');
  String get playBeforeFinish =>
      _t('ከመጨረስ በፊት ይጫወቱ።', 'Play before closing pls.', 'Xumuraa dura taphaali.', 'ቅድሚ ምዛዘም ተጻወት።');
  String get spaceToStop =>
      _t('ለማቆም Space ይጫኑ', 'Press Space to stop the game', 'Tapha dhaabuuf Space tuqi', 'ጸወታ ንምቁራጽ Space ጠውቑ');
  String get spaceToStart =>
      _t('ለመጀመር Space ይጫኑ', 'Press Space to start the game', 'Tapha jalqabuuf Space tuqi', 'ጸወታ ንምጅማር Space ጠውቑ');

  String get resumeGameTitle => _t(
        'የቀረ ጨዋታ አልሄደም!',
        'Your round didn\'t ghost you',
        'Raaundiin kee hin bade',
        'ዙርኻ ኣይከደነን!',
      );

  String resumeGameJoke(int roundNumber) => _t(
        'ኮምፒዩተሩ ጠፋ? አፕ ተዘጋ? ኃይል ሄደ? ዙር $roundNumber እዚህ ነው — ወንበርዎን አስቀመጥንልዎት።',
        'PC died? App closed? Power went on vacation? Round $roundNumber is still here — we saved your seat.',
        'Kompiitariin du\'e? Appiin cufame? Annisaa deeme? Raaundii $roundNumber as jira — teessoo kee qabanne jirra.',
        'ፒሲ ደሞአ? ኣፕ ተዓጽዩ? ሓይሊ ሄደ? ዙር $roundNumber ኣብዚ ኣሎ — መንበርኻ ኣቐመጥናል።',
      );

  String resumeGameStats(int calledCount) => calledCount > 0
      ? _t(
          '$calledCount ቁጥሮች ተጥሯል · BINGO ንመቀጠል',
          '$calledCount numbers called · hit BINGO to continue the show',
          'Lakkoofsi $calledCount waamame · tapha itti fufuuf BINGO tuqi',
          '$calledCount ቁጽርታት ተጸዊዑ · ጸወታ ንምቕጻል BINGO ጠውቑ',
        )
      : _t(
          'ዙር ተጀምሯል · እስካሁን ምንም ቁጥር አልተጠራም · ዝግጁ ሲሆኑ BINGO',
          'Round started · no numbers called yet · press BINGO when ready',
          'Raaundiin jalqabame · lakkoofsi hin waamamne · qophii ta\'e BINGO tuqi',
          'ዙር ተጅምሩ · ግዜ ኣይተጸዊዑን · ድሉው ምስ ኮይንካ BINGO ጠውቑ',
        );

  String get resumeGameContinue => _t(
        'እሺ — ወደ BINGO!',
        'Back to BINGO!',
        'Tole — gara BINGO!',
        'እሺ — ናብ BINGO!',
      );

  // —— Play settings ——
  String get playSettings => _t('የጨዋታ ቅንብሮች', 'Play settings', 'Qindaa\'ina taphaa', 'ቅንጥብታት ጸወታ');

  String get playerSettings =>
      _t('የተጫዋች ቅንብሮች', 'Player settings', 'Qindaa\'ina taphataa', 'ቅንጥብታት ተጻዋቲ');

  String get systemSettings =>
      _t('የስርዓት ቅንብሮች', 'System settings', 'Qindaa\'ina sirnaa', 'ቅንጥብታት ስርዓት');
  String get playSetupTab =>
      _t('ካርድ እና ማመሳሰል', 'Cards & Sync', 'Kaardii fi sync', 'ካርድን ምስማም');
  String get desktopPackageMovedHint => _t(
        'ተቀማጭ ገንዘብ እና ታሪክ በሪፖርት ገጽ ላይ። ካርድ እና ማመሳሰል ቅንብሮች በጨዋታ ቅንብሮች ውስጥ።',
        'Deposits and history are on the Report page. Card and sync settings are in Play settings.',
        'Kuufama fi seenaan fuula gabaasaa irratti. Qindaa\'inni kaardii fi sync qindaa\'ina taphaa keessatti.',
        'ተቀማጺን ታሪኽ ኣብ ገጽ ሪፖርት። ቅንጥብታት ካርድን ምስማም ኣብ ቅንጥብታት ጸወታ።',
      );
  String get mobilePackageDepositsOnReport => _t(
        'ተቀማጭ ገንዘብ እና ታሪክ በሪፖርት ገጽ ላይ ይገኛሉ።',
        'Deposits and history are on the Report page.',
        'Kuufama fi seenaan fuula gabaasaa irratti argamu.',
        'ተቀማጺን ታሪኽ ኣብ ገጽ ሪፖርት ይርከቡ።',
      );
  String get playSettingsHelp => _t(
        'ጨዋታው እንዴት እንደሚሰማ እና እንዴት እንደሚሄድ ይምረጡ። ሲጨርሱ Save ይጫኑ።',
        'Choose how the game sounds and runs. Tap Save when you are done.',
        'Akkaataa taphni akka dhaga\'amu fi akka deemu filadhu. Yeroo xumurtan Save tuqi.',
        'ከመይ ጸወታ ይሰምዕን ከመይ ይኸይድን ምረጹ። ምስ ዛዘምኩም Save ጠውቑ።',
      );
  String get settingsGroupInstantTitle => _t(
        'ወዲያውኑ ለውጥ',
        'Instant changes',
        'Jijjiirama saffisa',
        'ቅልጡፍ ለውጢ',
      );
  String get settingsGroupInstantHint => _t(
        'በአሁኑ ዙር እና በመጫወቻ ማያ ገጽ ወዲያውኑ ይተገብራል።',
        'Applies immediately on the play screen and during the current round.',
        'Fuula taphaa fi raaundii ammaa irratti battalumatti hojjeta.',
        'ኣብ መጻወቲ ገጽን ኣብ እዋናዊ ዙር ብቕልጡፍ ይተግብር።',
      );
  String get settingsGroupNextRoundTitle => _t(
        'የሚቀጥለው ዙር',
        'Next round',
        'Raaundii itti aanu',
        'ዝቕጽል ዙር',
      );
  String get settingsGroupNextRoundHint => _t(
        'ለሚቀጥለው የተመዘገበ ዙር ይቀመጣል። አሁን ያለው ዙር አይለወጥም።',
        'Saved for your next registered round. The active round is not changed.',
        'Raaundii itti aanu galmaa\'e qofaaf olkaa\'ama. Raaundii ammaa hin jijjiiramu.',
        'ንዝቕጽል ዝተመዝገበ ዙር ይቐመጥ። እቲ ንጡፍ ዙር ኣይቕየርን።',
      );
  String get settingsGroupNextRoundActiveHint => _t(
        'ይህ ዙር ቀድሞ ተጀምሯል — እነዚህ ቅንብሮች ለሚቀጥለው ዙር ብቻ ይተገበራሉ።',
        'This round is already in progress — these settings apply when you start the next round.',
        'Raaundiin kun dursee eegaleera — qindaa\'inni kun raaundii itti aanu qofaaf.',
        'እዚ ዙር ቀድሚ እዩ ተጀሚሩ — እዞም ቅንጥብታት ንዝቕጽል ዙር ጥራይ እዮም።',
      );
  String get checkResult => _t(
        'የፍተሻ ውጤት',
        'Check result',
        'Bu\'aa qormaataa',
        'ውጽኢት ፍተሻ',
      );
  String get sound => _t('ድምፅ', 'Sound', 'Sagalee', 'ድምጺ');
  String get callerVoice => _t('የጥሪ ድምፅ', 'Caller voice', 'Sagalee waamaa', 'ድምጺ ጻዕሪ');
  String get callerVoiceHelp => _t(
        'ቁጥሮችን በጨዋታ ወቅት ማን እንደሚነገር።',
        'Who reads the numbers aloud during the game.',
        'Eenyu lakkoofsota tapha keessatti dubbisu.',
        'ኣብ ጸወታ ቁጽርታት መን እንተ ይዛረብ።',
      );
  String get timeBetweenNumbers => _t('በቁጥሮች መካከል ጊዜ', 'Time between numbers', 'Yeroo lakkoofsota gidduu', 'ግዜ ኣብ መንጎ ቁጽርታት');
  String get timeBetweenNumbersHelp => _t(
        'ከአንዱ ጥሪ ድምጽ በኋላ እስከ ቀጣዩ ጥሪ ድረስ ስንት ሰከንድ ዝምታ።',
        'Seconds of silence after each call sound before the next number.',
        'Sagalee waamichaa tokkoo booda hanga itti aanutti sekondii callisaa.',
        'ድምጺ ጽውዓት ድሕሪ ምውዳኡ ክሳብ ዝቕጽል ጽውዓት ክንደይ ሰከንድ ስቕታ።',
      );
  String get quickPick => _t('ፈጣን ምርጫ', 'Quick pick', 'Filannoo saffisaa', 'ቅልጡፍ ምርጫ');
  String get fineTune => _t('በጥንቃቄ አስተካክል', 'Fine tune', 'Sirreessi', 'ብጥንቃቐ ኣስተኻኽል');
  String seconds(int n) => _t('$n ሰከንድ', '$n seconds', 'sekondii $n', '$n ሰከንድ');
  String secondsShort(int n) => '$n${_t('ሰ', 's', 's', 'ሰ')}';
  String get fastOneSec => _t('ፈጣን (1ሰ)', 'Fast (1s)', 'Saffisa (1s)', 'ቅልጡፍ (1ሰ)');
  String get slowFifteenSec => _t('ዝግታ (15ሰ)', 'Slow (15s)', 'Suuta (15s)', 'ዝግታ (15ሰ)');
  String get houseCut => _t('የቤት ድርሻ', 'House cut', 'Kutaa mana', 'ክፍሊት ቤት');
  String get houseCutHelp => _t(
        'ከደራሽ በፊት ከእያንዳንዱ ዙር የሚወሰድ ድርሻዎ።',
        'Your share taken from each round before the prize (derash).',
        'Qooda kee raaundii tokkoon tokkoon dura badhaasa irraa fudhatamu.',
        'ካብ ነፍሲ ወከፍ ዙር ቅድሚ ሽልማት ዝወሰድ ክፍልኩም።',
      );
  String get houseCutLockedHelp => _t(
        'ይህ ዙር ቀድሞ ተጀምሯል — የቤት ድርሻ ለሚቀጥለው ዙር ብቻ ይተገበራል።',
        'This round already started — house cut applies to the next round only.',
        'Raaundiin kun dursee eegaleera — kutaa mana raaundii itti aanu qofaaf.',
        'እዚ ዙር ቀድሚ እዩ ተጀሚሩ — ክፍሊት ቤት ንዝቕጽል ዙር ጥራይ እዩ።',
      );
  String get useDefaultPlan =>
      _t('ነባሪ', 'Default', 'Baramaa', 'ነባሪ');
  String get checkingWinningCard => _t('አሸናፊ ካርድ መፈተሽ', 'Checking a winning card', 'Kaardii mo\'aa qorachuu', 'ናይ ዓወት ካርድ ምፍታሽ');
  String get checkingWinningCardHelp => _t(
        'ተጫዋቹ ቢንጮ ሲል ካርዱ እንዴት እንደሚፈተሽ ይምረጡ።\n\n'
        'እጅ (Manual)\n'
        '• ቁጥሩን ያስገቡ እና ካርዱን በማያ ገጽ ይመልከቱ።\n'
        '• ጥሩ ካሸነፈ፣ አይደለም ካልሆነ፣ ዘግይቷል ከጊዜ በኋል ካመነ፣ ወይም ቆልፍ ካስፈለገ ይጫኑ።\n'
        '• ድምፅ ቁልፍ ሲጫኑ ብቻ ይሰማል — በራስ-ሰር አይደለም።\n'
        '• «ቅርጽ ተመልከት» የሚለው ቢንጎ የጊዜ ገደብ ሲኖር ቅርጹ በየትኛው ጻዕቂ እንደተሟላ በአረንጓዴ ያሳያል።\n\n'
        'ራስ-ሰር (Automatic)\n'
        '• ቁጥሩን ከገቡ ወዲያውኑ መተግበሪያው ያረጋግጣል።\n'
        '• ትክክለኛ አሸናፊ በራስ-ሰር ይቀመጣል፤ ስህተት ወይም ዘግይቷል ሲሆን ውጤቱ እና ድምፅ ይታያሉ።\n'
        '• ካርድን ከውጤቱ ማያ ገጽ ማቆል አሁንም ይቻላል።\n\n'
        'ሙሉ ቁጥጥር ለመካድ እጅ፤ ፈጣን ጸወታ ለመካድ ራስ-ሰር ይምረጡ።',
        'Choose how the cashier checks a card when a player says Bingo.\n\n'
        'MANUAL\n'
        '• Enter the card number and review the cartela on screen.\n'
        '• Tap Good if it wins, Not if it does not, Too late if they claimed after the allowed time (when Bingo claim time is on), or Lock to block the card.\n'
        '• Sounds play only when you tap a button — not automatically.\n'
        '• Use See pattern (when claim time is enabled) to show when the pattern first completed (green).\n\n'
        'AUTOMATIC\n'
        '• The app checks as soon as you enter the card number.\n'
        '• Valid winners are saved automatically; wrong or late claims show the result with sounds.\n'
        '• You can still lock a card from the result screen.\n\n'
        'Pick Manual for full control; pick Automatic for faster play.',
        'Yeroo taphataan Bingo jedhu kaardii akkamitti qoratamu filadhu.\n\n'
        'Harkaan (Manual)\n'
        '• Lakkoofsa galchi, kaardii iskiriinii irratti ilaali.\n'
        '• Mo\'ate Good, hin ta\'e Not, booda dhiyeessite Too late, ykn cufuuf Lock tuqi.\n'
        '• Sagaleen yeroo qabdu qofa dhaga\'ama — ofiin hin ta\'u.\n'
        '• «Akkaataa ilaali» yeroo daangaa Bingo baname akkaataan waggaa kamitti xumurame agarsiisa.\n\n'
        'Ofiin (Automatic)\n'
        '• Lakkoofsa galchitee booda appiin battalumatti qorata.\n'
        '• Mo\'attoonni sirrii ofiin olkaa\'amu; dogoggora ykn dhiyoo ta\'e sagalee waliin agarsiisa.\n'
        '• Kaardii cufuu iskiriinii bu\'uuraa irraa ammallee ni danda\'ama.\n\n'
        'To\'annoo guutuuuf Harkaan; tapha saffisaaf Ofiin fili.',
        'ተጻዋቲ ቢንጎ ምስ ይብል ካርድ ከመይ ጌርካ ትፈትሾ ክትምረጽ።\n\n'
        'ኢድ (Manual)\n'
        '• ቁጽሪ ኣእቱን ካርድ ኣብ ስክሪን ርአ።\n'
        '• ዓወተ Good፣ ኣይኮነን Not፣ ዘግይቱ Too late፣ ወይ ዕጸው Lock ጠውቕ።\n'
        '• ድምጺ ኣብ ጊዜ ቁልፊ ጥራይ ይሰምዕ — ብኡን ኣይኮነን።\n'
        '• «ቅርጺ ርአ» ኣብ ግዜ ቢንጎ ደረጃ ምስ ይኸውን ቅርጺ ብኣረንጓዴ ኣብ እትኸውን ጻዕሪ ይሕብኦ።\n\n'
        'ብኡን (Automatic)\n'
        '• ቁጽሪ ምስ ትኣቱ ኣፕሊኬሽን ብቐጥታ ይፈትሽ።\n'
        '• ቅኑዕ ዓዋተኛ ብኡን ይዕቀብ፤ ጌጋ ወይ ዘግይቱ ድምጺ ጋር ይረአ።\n'
        '• ካርድ ምዕጻው ካብ ስክሪን ክትከውን ይኽእል እዩ።\n\n'
        'ምሉእ ቁጽጽር ኢድ፤ ቅልጡፍ ጸወታ ብኡን ምረጽ።',
      );
  String get manual => _t('እጅ', 'Manual', 'Harkaan', 'ኢድ');
  String get manualHelp => _t(
        'Good፣ Not ወይም Lock ይጫኑ።',
        'You tap Good Bingo, Not Bingo, or Lock.',
        'Good, Not ykn Lock tuqi.',
        'Good፣ Not ወይ Lock ጠውቑ።',
      );
  String get automatic => _t('ራስ-ሰር', 'Automatic', 'Ofiin', 'ብኡን');
  String get automaticHelp => _t(
        'መተግበሪያው አሸናፊዎችን ያረጋግጣል።',
        'The app confirms winners for you.',
        'Appiin mo\'attoota siif mirkaneessa.',
        'ኣፕሊኬሽን ዓዋተኛታት ይረጋግጽ።',
      );
  String get bingoClaimTime => _t(
        'የቢንጎ የይገባኛል ስርዓት',
        'Instant bingo claim rule',
        'Seera gaaffii Bingo',
        'ሰርዓት ጽውዓት ቢንጎ',
      );
  String get bingoClaimTimeHelp => _t(
        'ተጫዋቹ ቅርጹ ሲጠናቀቅ ቢንጎ መናገር አለበት ወይም በኋላ ይቻላል — በተመረጠው ስርዓት ይወሰናል።',
        'Controls whether a completed pattern can be claimed late, only on a new pattern, or locks the card after a missed window.',
        'Akkaataan erga xumuramee booda Bingo jedhamuu danda\'uu isaa to\'ata.',
        'ቅርጺ ምስ ዝተዛዘመ ብዘግየተ ወይ ብሓድሽ ቅርጺ ጥራይ ምጽዋዕ ይኽእል።',
      );
  String bingoClaimModeLabel(BingoClaimMode mode) => switch (mode) {
        BingoClaimMode.noRestriction => _t(
              'ያለ ዘግይቶ የይገባኛል ገደብ',
              'No Late-Claim Restriction',
              'Daangaa yeroo hin qabu',
              'ብዘይ ደረት ዘግየተ ጽውዓት',
            ),
        BingoClaimMode.allowLaterPatterns => _t(
              'በአዲስ ቅርጾች ማሸነፍ',
              'Allow Winning on New Patterns',
              'Akkaataa haaraa irratti moo\'achuu',
              'ብሓደስቲ ቅርጽታት ምዕዋት',
            ),
        BingoClaimMode.disqualifyOnMiss => _t(
              'ከተሳሳተ ጊዜ በኋላ ማሰናበት',
              'Disqualify After Missed Winning Claim',
              'Yeroo darbanii booda adda baasuu',
              'ድሕሪ ዝተሰናበተ ጽውዓት ምእጋድ',
            ),
      };
  String bingoClaimModeHelp(BingoClaimMode mode) => switch (mode) {
        BingoClaimMode.noRestriction => _t(
              'ነባሪ። ትክክለኛ የማሸነፊያ ቅርጽ ከተጠናቀቀ ቢንጎ ወዲያውኑ ባይነገርም በኋላ ተመሳሳይ ቅርጽ መጠየቅ ይቻላል። ውድቅ የተደረጉ ጥያቄዎች ሌላ ዕድል አያገኙም።',
              'Default. If a player completes a valid winning pattern but does not press Bingo immediately, they can still claim that same pattern later. Rejected or lost Bingo claims do not get another chance.',
              'Akkaataan moo\'annoo erga xumuramee Bingo yeroo sana hin jennees booda gaafachuu danda\'a.',
              'ቅርጺ ዓወት ምስ ዝተዛዘመ ብቕልጡፍ ቢንጎ እንተዘይተበሃለ ድሒሩ ክሕተት ይኽእል።',
            ),
        BingoClaimMode.allowLaterPatterns => _t(
              'ለተጠናቀቀ ቅርጽ የይገባኛል መስኮት ከጠፋ ያ ዕድል ይጠፋል። ካርዱ ይቀጥላል እና አዲስ ቅርጽ ሲጠናቀቅ ብቻ ማሸነፍ ይችላል — እያንዳንዱ የራሱ መስኮት አለው።',
              'If a player misses the claim window for a completed pattern, that specific opportunity is lost. The card stays active and can win only when a new qualifying pattern completes — each with its own claim window.',
              'Yeroo gaaffii yoo darban carraan sun ni bada; akkaataa haaraa qofa irratti moo\'achuu danda\'u.',
              'ናይ ቅርጺ መስኮት እንተዘሎፈ እቲ ዕድል ይጠፍእ፤ ሓድሽ ቅርጺ ምስ ዝተዛዘመ ጥራይ ክዕውት ይኽእል።',
            ),
        BingoClaimMode.disqualifyOnMiss => _t(
              'ቅርጽ ከተጠናቀቀ ቀጣዩ ኳስ ከመጥራቱ በፊት ቢንጎ ካልተነገረ መስኮቱ ይዘጋል። ከዚያ በኋላ ቢንጎ ማለት ካርዱን ይቆልፋል — በዚህ ጨዋታ እንደገና ማሸነፍ አይቻልም።',
              'If a player completes a winning pattern but does not press Bingo before the next ball, that claim window closes. The BINGO button stays available — pressing it after the window closes locks the card. After a missed window the card cannot win again this game.',
              'Kubbaa itti aanu dura Bingo hin jenne ta\'ee carraan ni cufa; booda Bingo jedhuun kaardii cufa.',
              'ቅድሚ ዝቕጽል ኳስ ቢንጎ እንተዘይተበሃለ መስኮት ይዕጸው፤ ድሕሪኡ ቢንጎ ምባል ካርድ የዓጽዎ።',
            ),
      };

  @Deprecated('Use bingoClaimModeLabel')
  String bingoClaimLimitLabel(int value) => bingoClaimModeLabel(
        value < 0
            ? BingoClaimMode.noRestriction
            : BingoClaimMode.disqualifyOnMiss,
      );
  String get winnerSound => _t('የአሸናፊ ድምፅ', 'Winner sound', 'Sagalee mo\'aa', 'ድምጺ ዓዋተኛ');
  String get winnerSoundHelp => _t(
        'ካርድ እንደ አሸናፊ ሲረጋገጥ ይጫወታል።',
        'Plays when a card is confirmed as a winner.',
        'Yeroo kaardiin akka mo\'aa mirkanaa\'u taphata.',
        'ካርድ ከም ዓዋተኛ ምስ ይረጋገጽ ይደሊ።',
      );
  String get clapping => _t('ጭብጨባ', 'Clapping', 'Kutaa harka', 'ኣጥብዒ');
  String get goodBingo => _t('ጥሩ ቢንጎ', 'Good Bingo', 'Bingo Gaarii', 'ጽቡቕ ቢንጎ');
  String get settingsTitleEthiomark =>
      _t('Settings - ማስተካከያ', 'Settings - ማስተካከያ', 'Settings - ማስተካከያ', 'Settings - ማስተካከያ');
  String get bonusStatusLabel =>
      _t('Bonus Management:', 'Bonus Management:', 'Bonus Management:', 'Bonus Management:');
  String get bonusRoundLabel =>
      _t('Bonus round:', 'Bonus round:', 'Bonus round:', 'Bonus round:');
  String get bonusRoundOff => _t('ጠፍቷል', 'Off', 'Cufame', 'ጠፊኡ');
  String get bonusRoundEvery1 =>
      _t('በየ 1 ዙር', 'Every 1 round', 'Round 1 hundaa', 'ኣብ ነፍሲ ወከፍ 1 ዙር');
  String get bonusRoundEvery3 =>
      _t('በየ 3 ዙር', 'Every 3 rounds', 'Round 3 hundaa', 'ኣብ ነፍሲ ወከፍ 3 ዙር');
  String get bonusRoundEvery4 =>
      _t('በየ 4 ዙር', 'Every 4 rounds', 'Round 4 hundaa', 'ኣብ ነፍሲ ወከፍ 4 ዙር');
  String get bonusRoundEvery10 =>
      _t('በየ 10 ዙር', 'Every 10 rounds', 'Round 10 hundaa', 'ኣብ ነፍሲ ወከፍ 10 ዙር');
  String get bonusRoundRandom =>
      _t('በዕድል', 'Random (chance)', 'Carraa', 'ብዕድል');
  String get bonusLuckyCountLabel => _t(
        'Lucky cards per claim:',
        'Lucky cards per claim:',
        'Lucky cards per claim:',
        'Lucky cards per claim:',
      );
  String get bonusPerDayLabel => _t(
        'Number of bonuses / per day:',
        'Number of bonuses / per day:',
        'Number of bonuses / per day:',
        'Number of bonuses / per day:',
      );
  String get bonusDailyLimitReached => _t(
        'የዕለቱ ቦነስ ገደብ ተሞልቷል',
        'Daily bonus limit reached',
        'Daailyyaa bonasii guuttameera',
        'ናይ መዓልቲ ቦነስ ደረት ተማሊኡ',
      );
  String get bonusAmountLabel => _t(
        'የቦነስ መጠን (50–3000):',
        'Bonus amount (fixed) 50–3000:',
        'Bonus amount (fixed) 50–3000:',
        'Bonus amount (fixed) 50–3000:',
      );
  String get bonusMinBetLabel => _t(
        'ዝቅተኛ ጠቅላላ ውርርድ (min 100):',
        'Min total bet (min 100):',
        'Min total bet (min 100):',
        'Min total bet (min 100):',
      );
  String get bonusOff => _t('ጠፍቷል', 'Off', 'Cufame', 'ጠፊኡ');
  String get bonusOn => _t('በርቷል', 'On', 'Banaame', 'በሪሁ');
  String get bonusReadyClaim =>
      _t('ቦነስ ዝግጁ — ይውሰዱ', 'Bonus ready — Claim', 'Bonasii qophaa\'e — Fudhadhu', 'ቦነስ ድሉው — ውሰድ');
  String get bonusClaim => _t('ቦነስ ውሰድ', 'Claim bonus', 'Bonasii fudhadhu', 'ቦነስ ውሰድ');
  String get bonusLuckyTitle =>
      _t('የቦነስ ካርዶች', 'Lucky bonus cards', 'Kaardii bonasii', 'ካርድ ቦነስ');
  String get bonusSpinningKicker => _t(
        'የእድል ካርዶች በመሽከርከር ላይ...',
        'Spinning lucky cards...',
        'Kaardii carraa ni naanna\'a...',
        'ካርድ ዕድል ይሽከረከር ኣሎ...',
      );
  String get bonusSpinningTitle =>
      _t('ማን እድለኛ ነው?', 'Who is lucky?', 'Eenyu carraa qaba?', 'መን ዕድለኛ እዩ?');
  String get bonusRevealedTitle =>
      _t('አሸናፊዎች አሉን!', 'We have winners!', 'Mo\'attoota qabna!', 'ኣሸነፍቲ ኣለውና!');
  String get bonusSkippedNoPlayers => _t(
        'ቦነስ የለም — አሸናፊ ያልሆነ ተጫዋች የለም',
        'No bonus — no non-winning players',
        'Bonasii hin jiru — hin mo\'anne hin jiru',
        'ቦነስ የለን — ዘይተዓወተ ተጻዋታይ የለን',
      );
  String get bonusClaimedToast =>
      _t('ቦነስ ተሰጥቷል', 'Bonus claimed', 'Bonasii kenname', 'ቦነስ ተዋሂቡ');
  String get bonusViewCards =>
      _t('የቦነስ ካርዶች', 'Bonus cards', 'Kaardii bonasii', 'ካርድ ቦነስ');
  String get checkResultSettingsLabel => _t(
        'Check Result - አሸናፊዉን መለየት :',
        'Check Result - አሸናፊዉን መለየት :',
        'Check Result - አሸናፊዉን መለየት :',
        'Check Result - አሸናፊዉን መለየት :',
      );
  String get colorModeLabel => _t(
        'Set result color mode:',
        'Set result color mode:',
        'Set result color mode:',
        'Set result color mode:',
      );
  String get goodBingoSoundSettingsLabel => _t(
        'good bingo sound :',
        'good bingo sound :',
        'good bingo sound :',
        'good bingo sound :',
      );
  String get setProfitLabel => _t('Set Profit:', 'Set Profit:', 'Set Profit:', 'Set Profit:');
  String get colorModeTwo =>
      _t('Two [red and green ]', 'Two [red and green ]', 'Two [red and green ]', 'Two [red and green ]');
  String get colorModeThree => _t(
        'Three [red, green and Yellow ]',
        'Three [red, green and Yellow ]',
        'Three [red, green and Yellow ]',
        'Three [red, green and Yellow ]',
      );
  String get goodBingoSoundEthiomark0 => _t(
        'ይህ ካርቴላ አሸንፏል',
        'ይህ ካርቴላ አሸንፏል',
        'ይህ ካርቴላ አሸንፏል',
        'ይህ ካርቴላ አሸንፏል',
      );
  String get goodBingoSoundEthiomark1 => _t('ጭብጨባ', 'ጭብጨባ', 'ጭብጨባ', 'ጭብጨባ');
  String get goodBingoSoundEthiomark2 => _t(
        'ጉድ ቢንጎ - Good Bingo',
        'ጉድ ቢንጎ - Good Bingo',
        'ጉድ ቢንጎ - Good Bingo',
        'ጉድ ቢንጎ - Good Bingo',
      );
  String get toggleWillStartSound =>
      _t('ሊጀምር ነው ድምጽ', 'ሊጀምር ነው ድምጽ', 'ሊጀምር ነው ድምጽ', 'ሊጀምር ነው ድምጽ');
  String get toggleStartedSound =>
      _t('ጨዋታው ጀምሯል ድምጽ', 'ጨዋታው ጀምሯል ድምጽ', 'ጨዋታው ጀምሯል ድምጽ', 'ጨዋታው ጀምሯል ድምጽ');
  String get toggleStoppedSound =>
      _t('ጨዋታው ቁሟል ድምጽ', 'ጨዋታው ቁሟል ድምጽ', 'ጨዋታው ቁሟል ድምጽ', 'ጨዋታው ቁሟል ድምጽ');
  String get toggleShowCardCount =>
      _t('የተመዘገበ ቁጥር ብዛት', 'የተመዘገበ ቁጥር ብዛት', 'የተመዘገበ ቁጥር ብዛት', 'የተመዘገበ ቁጥር ብዛት');
  String get toggleShowPatternOnStart => _t(
        'በጨዋታ ገጽ ቅርጽ አሳይ',
        'Show pattern on playing page',
        'Fuula taphichaa irratti akkaataa agarsiisi',
        'ኣብ ገጽ ጸወታ ቅርጺ ኣርኢ',
      );
  String get saveChanges =>
      _t('Save Changes', 'Save Changes', 'Save Changes', 'Save Changes');
  String get saveSettings => _t('ቅንብሮችን አስቀምጥ', 'Save settings', 'Qindaa\'ina olkaa\'i', 'ቅንጥብታት ኣቐምጥ');
  String get savingSettings =>
      _t('ቅንብሮችን በማስቀመጥ ላይ…', 'Saving settings…', 'Qindaa\'ina olkaa\'aa jira…', 'ቅንጥብታት ይቐመጥ…');
  String get settingsSaved =>
      _t('ቅንብሮች ተቀምጡ', 'Settings saved', 'Qindaa\'inni olkaa\'ame', 'ቅንጥብታት ተዓቅመ');

  // —— Profile ——
  String get loadingProfile => _t('መገለጫ በመጫን ላይ…', 'Loading profile…', 'Profaayilii fe\'aa jira…', 'መገለጺ ይጽዕን…');
  String get refreshingProfile =>
      _t('መገለጫ በማደስ ላይ…', 'Refreshing profile…', 'Profaayilii haaromsaa jira…', 'መገለጺ ይሓድስ…');
  String get importingCartelas =>
      _t('ካርዶች በመጫን ላይ…', 'Importing cartelas…', 'Kaardii galchaa jira…', 'ካርድ ይሓዝን…');
  String get savingCategory =>
      _t('ምድብ በማስቀመጥ ላይ…', 'Saving category…', 'Gosa olkaa\'aa jira…', 'ክፍል ይቐመጥ…');
  String get savingPartnerId =>
      _t('የአጋር መለያ በማስቀመጥ ላይ…', 'Saving partner ID…', 'ID Partner olkaa\'aa jira…', 'መለለዪ መሻርኽ ይቐመጥ…');
  String get savingDomain =>
      _t('ዶሜይን በማስቀመጥ ላይ…', 'Saving domain…', 'Domeenii olkaa\'aa jira…', 'ዶመይን ይቐመጥ…');
  String get searchingCartela =>
      _t('ካርድ በመፈለግ ላይ…', 'Searching cartela…', 'Kaardii barbaadaa jira…', 'ካርድ ይደሊ…');
  String cashierName(String id) =>
      _t('የካሺየር ስም: $id', 'Cashier Name: $id', 'Maqaa Kaashiyeerii: $id', 'ስም ካሺየር: $id');
  String get cartelaCategory => _t('የካርድ ምድብ', 'Cartela Category', 'Gosa Kaardii', 'ክፍሊት ካርድ');
  String get packageSyncIds => _t('የፓኬጅ ማመሳሰል መለያዎች', 'Package Sync IDs', 'IDwwan walsimsiisa Paakeejii', 'መለለዪታት ምስላል ፓኬጅ');
  String get cartelaLookup => _t('ካርድ ፍለጋ', 'Cartela Lookup', 'Kaardii Barbaadi', 'ድላይ ካርድ');
  String get depositHistory =>
      _t('የግብይት ታሪክ', 'Transaction History', 'Seenaa Daldalaa', 'ታሪኽ ግብይት');
  String get applyCategory => _t('ምድብ ተግብር', 'Apply Category', 'Gosa Hojiirsi', 'ክፍል ኣተግብር');
  String walletBalance(String balance, [String currencyCode = AppCurrency.defaultCode]) {
    final formatted = AppNumberFormat.formatString(balance);
    final currency = currencyLabel(currencyCode);
    return _t(
      'ቦርሳ: $formatted $currency',
      'Wallet: $formatted $currency',
      'Kuusaa: $currency $formatted',
      'ቦርሳ: $formatted $currency',
    );
  }

  String transactionExceedsWallet(
    String balance, [
    String currencyCode = AppCurrency.defaultCode,
  ]) {
    final currency = currencyLabel(currencyCode);
    return _t(
      'ግብይቱ የካሺየር ቦርሳ ($balance $currency) ያልፋል። ለመሙላት ወደ መገለጫ ይሂዱ።',
      'This transaction exceeds your wallet balance ($balance $currency). Go to Profile to top up.',
      'Daldalli kun kuusaa kaashiyeerii ($balance $currency) caala. Kuufuuf gara Profaayilii deemi.',
      'እዚ ግብይት እዚ ንቦርሳ ካሺየር ($balance $currency) ይዝርጋሕ። ንምምላእ ናብ መገለጺ ኪድ።',
    );
  }
  String get goToProfileAction =>
      _t('ወደ ሪፖርት ይሂዱ', 'Go to Report', 'Gara Gabaasaa Deemi', 'ናብ ሪፖርት ኪድ');
  String get logout => _t('ውጣ', 'Log out', 'Ba\'i', 'ውጻእ');
  String get logoutConfirmTitle =>
      _t('ውጣ?', 'Log out?', 'Ba\'uu?', 'ውጻእ?');
  String get logoutConfirmBody => _t(
        'ከመለያዎ ይውጣሉ?',
        'Sign out of this cashier account on this device?',
        'Meeshaa kana irratti herrega kaashiyeerii kana irraa ba\'uu barbaadduu?',
        'ካብ እዚ ካሺየር ኣብ እዚ መሳርሒ ክትወጽእ ዲኻ?',
      );
  String get loggingOut =>
      _t('በመውጣት ላይ…', 'Signing out…', 'Ba\'aa jira…', 'ይወጽእ…');
  String get depositHistoryTitle =>
      _t('የግብይት ታሪክ', 'Transaction history', 'Seenaa daldalaa', 'ታሪኽ ግብይት');
  String get noDepositHistory => _t(
        'ገና የግብይት ታሪክ የለም',
        'No transaction history yet',
        'Ammaaf seenaa daldalaa hin jiru',
        'ክሳብ ሕጂ ታሪኽ ግብይት የለን',
      );
  String depositLogActionLabel(String action) {
    final a = action.toLowerCase();
    if (a.contains('withdrawal')) {
      return _t('ወጪ', 'Withdrawal', 'Baasii', 'ወጻኢ');
    }
    if (a.contains('deposit')) {
      return _t('ተቀማጭ', 'Deposit', 'Kuufama', 'ተቀማጺ');
    }
    return action;
  }
  String get action => _t('ድርጊት', 'Action', 'Gocha', 'ተግባር');
  String get amount => _t('መጠን', 'Amount', 'Hanga', 'መጠን');
  String get time => _t('ጊዜ', 'Time', 'Yeroo', 'ግዜ');
  String get packageTopUp => _t('ፓኬጅ (ለመሙላት)', 'Package', 'Paakeejii', 'ፓኬጅ');
  String get offlineDeposit =>
      _t('ኦፍላይን ተቀማጭ', 'Offline Deposit', 'Kuufama oflaayinii', 'ኦፍላይን ተቀማጺ');
  String get offlineDepositShort =>
      _t('ኦፍላይን', 'Offline', 'Oflaayinii', 'ኦፍላይን');
  String get onlineDeposit =>
      _t('ኦንላይን ተቀማጭ', 'Online Deposit', 'Kuufama olaayinii', 'ኦንላይን ተቀማጺ');
  String get onlineDepositShort =>
      _t('ኦንላይን', 'Online', 'Olaayinii', 'ኦንላይን');
  String get depositHistoryShort =>
      _t('ታሪክ', 'History', 'Seenaa', 'ታሪኽ');
  String get category => _t('ምድብ', 'Category', 'Gosa', 'ክፍሊት');
  String get remoteDomain => _t('ርቀት ዶሜይን', 'Remote domain', 'Domeenii fagoo', 'ርሑቕ ዶመይን');
  String get cartelaNumberHint => _t('ካርድ #', 'Cartela #', 'Kaardii #', 'ካርድ #');
  String cartelaNumber(int n) => _t('ካርድ #$n', 'Cartela #$n', 'Kaardii #$n', 'ካርድ #$n');
  String get loadEncryptedCartela =>
      _t('የተመሰጠረ ካርድ (.enc) ጫን', 'Load encrypted cartela (.enc)', 'Kaardii iccitii (.enc) fe\'i', 'ዝተመሰጠረ ካርድ (.enc) ጽዕን');
  String cashierLabel(String id) => _t('ካሺየር: $id', 'Cashier: $id', 'Kaashiyeerii: $id', 'ካሺየር: $id');
  String categorySetTo(String cat) => _t('የካርድ ምድብ ወደ $cat ተቀናብሯል', 'Cartela category set to $cat', 'Gosa kaardii gara $cat tti sirreeffame', 'ክፍሊት ካርድ ናብ $cat ተቐይሩ');
  String get categoriesTitle =>
      _t('ምድቦች', 'Categories', 'Gosoota', 'ክፍልታት');
  String get newCategory =>
      _t('አዲስ ምድብ', 'New category', 'Gosa haaraa', 'ሓድስ ክፍሊት');
  String get editCategory =>
      _t('ምድብ አርትዕ', 'Edit category', 'Gosa gulaali', 'ክፍሊት ኣርም');
  String get categoryNameLabel =>
      _t('የምድብ ስም', 'Category name', 'Maqaa gosa', 'ስም ክፍሊት');
  String get categoryNameRequired => _t(
        'የምድብ ስም ያስፈልጋል።',
        'Category name is required.',
        'Maqaa gosa barbaachisa.',
        'ስም ክፍሊት ኣድላዪ እዩ።',
      );
  String get categoryNameExists => _t(
        'ይህ ምድብ አስቀድሞ አለ።',
        'This category already exists.',
        'Gosiin kun duraan jira.',
        'እዚ ክፍሊት ድሮ ኣሎ።',
      );
  String deleteCategoryConfirm(String name) => _t(
        'ምድብ «$name» እና ካርዶቹን ሰርዝ?',
        'Delete category «$name» and all its cartelas?',
        'Gosa «$name» fi kaardii isaa hunda haquu?',
        'ክፍሊት «$name»ን ካርድታቱን ሰርዝ?',
      );
  String get categoryRenameWarning => _t(
        'ይህ ምድብ ለሁሉም ካርዶች በዚህ ምድብ ውስጥ ይለወጣል። ይህ ምድብ የተመረጠው ካሺየር በሚቀጥለው ዙር አዲሱን ስም ያያል።',
        'This changes the category name for all cartelas in this group. Cashiers on this category will see the new name when they start their next round.',
        'Kun maqaa gosa kaardii hunda gosa kana keessaa ni jijjiirama. Kaashiyeerii gosa kana filatan raaundii itti aanu maqaa haaraa ni argu.',
        'እዚ ክፍሊት ን ኩሉ ካርድ ኣብዚ ክፍሊት ክለዋወጥ እዩ። ካሺየር ኣብዚ ክፍሊት ዝተመርጸ ኣብ ዝቕጽል ዙር ሓድስ ስም ክርእይ እዩ።',
      );
  String get categoryDeleteWarning => _t(
        'ይህ ምድብ እና ካርዶቹን ለዘለዓለም ይሰርዛል። በዚ ምድብ ላይ የሚገኙ ካሺየሮች ወደ ሌላ ምድብ ይቀየራሉ።',
        'This permanently deletes the category and every cartela inside it. Cashiers on this category will be moved to another category.',
        'Kun gosa fi kaardii isaa hunda dhaabbataadhaan ni haqa. Kaashiyeerii gosa kana irratti gara gosa biraatti ni jijjiiramu.',
        'እዚ ክፍሊትን ኩሉ ካርድ ኣብኡን ንዘለኣለም ክሰርዝ እዩ። ካሺየር ኣብዚ ክፍሊት ናብ ክፍሊት ይቕየር።',
      );
  String renameCategoryTo(String name) => _t(
        '«$name» ወደ',
        'Rename $name to',
        'Maqaa $name gara',
        '«$name» ናብ',
      );
  String get noCategoriesYet => _t(
        'ምድብ አልተገኘም። አዲስ ምድብ ይጨምሩ።',
        'No categories yet. Add a new category.',
        'Gosoonni hin jiran. Gosa haaraa dabaluu.',
        'ክፍሊት ኣይተረኽበን። ሓድስ ክፍሊት ወስኽ።',
      );
  String get noCartelasInCategory => _t(
        'በዚ ምድብ ውስጥ ካርድ አልተገኘም።',
        'No cartelas in this category.',
        'Gosa kana keessatti kaardii hin jiru.',
        'ኣብዚ ክፍሊት ካርድ ኣይተረኽበን።',
      );
  String get newCartela =>
      _t('አዲስ ካርድ', 'New cartela', 'Kaardii haaraa', 'ሓድስ ካርድ');
  String get editCartela =>
      _t('ካርድ አርትዕ', 'Edit cartela', 'Kaardii gulaali', 'ካርድ ኣርም');
  String get cartelaNumberLabel =>
      _t('የካርድ ቁጥር', 'Cartela number', 'Lakkoofsa kaardii', 'ቁጽሪ ካርድ');
  String get cartelaNumberExists => _t(
        'በዚ ምድብ ውስጥ ይህ ቁጥር አስቀድሞ አለ።',
        'This number already exists in the category.',
        'Lakkoofsi kun gosa kana keessatti duraan jira.',
        'እዚ ቁጽሪ ኣብዚ ክፍሊት ድሮ ኣሎ።',
      );
  String deleteCartelaConfirm(int n) => _t(
        'ካርድ #$n ሰርዝ?',
        'Delete cartela #$n?',
        'Kaardii #$n haquu?',
        'ካርድ #$n ሰርዝ?',
      );
  String get invalidCartelaGrid => _t(
        'እያንዳንዱ ረድፍ 5 ቁጥሮች ያስፈልጋል (N ረድፍ መካከል ነጻ ★).',
        'Each column needs 5 numbers (N middle row is free ★).',
        'Tarree hunda lakkoofsa 5 barbaachisa (N gidduu bilisa ★).',
        'እዋን እዋን ረድፍ 5 ቁጽርታት የድሊ (N ማእከላይ ረድፍ ነፃ ★).',
      );
  String cartelasCount(int n) => _t('$n ካርዶች', '$n cartelas', 'Kaardii $n', '$n ካርድ');
  String get enterValidCartela =>
      _t('ትክክለኛ የካርድ ቁጥር ያስገቡ።', 'Enter a valid cartela number.', 'Lakkoofsa kaardii sirrii galchi.', 'ቅኑዕ ቁጽሪ ካርድ ኣእትዉ።');
  String cartelaNotFound(int n, String cat) => _t(
        'ካርድ #$n በ$cat አልተገኘም።',
        'Cartela #$n not found in $cat.',
        'Kaardii #$n gosa $cat keessatti hin argamne.',
        'ካርድ #$n ኣብ $cat ኣይተረኽበን።',
      );
  String get couldNotReadFile =>
      _t('የተመረጠው ፋይል ማንበብ አልተቻለም።', 'Could not read the selected file.', 'Faayilii filatame dubbisuu hin danda\'amne.', 'ዝተመረጸ ፋይል ክንኣብብ ኣይተኻእለን።');
  String importedCartelas(int count) =>
      _t('$count ካርዶች ተጭነዋል።', 'Imported $count cartelas.', 'Kaardii $count galchame.', '$count ካርድ ተሓዚሑ።');
  String importFailed(String error) =>
      _t('መጫን አልተሳካም: $error', 'Import failed: $error', 'Galchuun hin milkoofne: $error', 'ምሕዳስ ኣይተኻእለን: $error');
  String get partnerIdSaved => _t('የአጋር መለያ ተቀምጧል', 'Partner ID saved', 'ID Partner olkaa\'ame', 'መለለዪ መሻርኽ ተዓቅመ');
  String get domainSaved => _t('ዶሜይን ተቀምጧል', 'Domain saved', 'Domeenii olkaa\'ame', 'ዶመይን ተዓቅመ');

  // —— Report ——
  String get loadingReport => _t('ሪፖርት በመጫን ላይ…', 'Loading report…', 'Gabaasa fe\'aa jira…', 'ሪፖርት ይጽዕን…');
  String get today => _t('ዛሬ', 'Today', 'Har\'a', 'ሎሚ');
  String get yesterday => _t('ትላንት', 'Yesterday', 'Kaleessa', 'ትማሊ');
  String get thisWeek => _t('በዚህ ሳምንት', 'This week', 'Torban kana', 'ኣብዚ ሰሙን');
  String get lastWeek => _t('ባለፈው ሳምንት', 'Last week', 'Torban darbe', 'ባለፈ ሰሙን');
  String get thisMonth => _t('በዚህ ወር', 'This month', 'Ji\'a kana', 'ኣብዚ ወርሒ');
  String get custom => _t('ብራሴ', 'Custom', 'Ofii', 'ብራሲ');
  String get fromDate => _t('ከቀን', 'From Date', 'Guyyaa irraa', 'ካብ ዕለት');
  String get toDate => _t('እስከ ቀን', 'To Date', 'Guyyaatti', 'ክሳዕ ዕለት');
  String get todaysNetIncome =>
      _t('የዛሬ ንጥረ ገቢ', "Today's net income", 'Galii qulqulluu har\'aa', 'ንጹር ኣታዊ ሎሚ');
  String get todaysIncome =>
      _t('የዛሬ ገቢ', "Today's income", 'Galii har\'aa', 'ኣታዊ ሎሚ');
  String get todaysBonus =>
      _t('የዛሬ ቦነስ', "Today's bonus", 'Bonasii har\'aa', 'ቦነስ ሎሚ');
  String get totals => _t('ጠቅላላ', 'Totals', 'Ida\'ama', 'ድምር');
  String get noData => _t('መረጃ የለም', 'No data', 'Daataa hin jiru', 'ዳታ የለን');

  // —— About ——
  String get offlineSystem => _t('ኦፍላይን ስርዓት', 'Offline System', 'Sirna oflaayinii', 'ኦፍላይን ስርዓት');
  String get offlineSystemSubtitle => _t(
        'ኢንተርኔት ሳይፈልግ ይሰራል — ለሱቅ ካሺየሮች ተስማሚ',
        'Works without internet — perfect for shop cashiers',
        'Interneetii malee hojjeta — kaashiyeerota dukaanaaf mijataa',
        'ብዘይ ኢንተርነት ይሰርሕ — ንካሺየር ድኳን ፍቹ',
      );
  String get online => _t('ኦንላይን', 'Online', 'Olaayinii', 'ኦንላይን');
  String get onlineSubtitle =>
      _t('በድረ ገጽ ጨዋታ ይጫወቱ እና ያስተዳድሩ', 'Play and manage games on the web', 'Tapha olaayinii irratti taphadhu fi bulchi', 'ኣብ ወብ ጸወታ ተጻወትን ኣመሓድርን');
  String get contact => _t('አግኙን', 'Contact', 'Nu qunnamaa', 'ተወከሱና');
  String get contactSubtitle => _t('እርዳታ ለማግኘት እዚህ ነን', 'We are here to help', 'Gargaarsaaf as jirra', 'ንምሕጋዝ ኣብዚ ኢና');
  String get tapToCall => _t('ለመደወል ይጫኑ', 'Tap to call', 'Waamachuuf tuqi', 'ንምድዋል ጠውቑ');
  String get tapToEmail => _t('ኢሜይል ለመላክ ይጫኑ', 'Tap to send email', 'Imeelii erguuf tuqi', 'ኢመይል ንምልኣኽ ጠውቑ');
  String get couldNotOpenLink =>
      _t('ሊንክ መክፈት አልተቻለም', 'Could not open link', 'Liinkii banuu hin danda\'amne', 'ሊንክ ክኽፈት ኣይተኻእለን');
  String get aboutTagline => _t(
        'ኦፍላይን ካሺየር · ኦንላይን የጨዋታ ስርዓት',
        'Offline cashier · Online gaming ecosystem',
        'Kaashiyeerii oflaayinii · ekosisteemii taphaa olaayinii',
        'ኦፍላይን ካሺየር · ኦንላይን ስርዓት ጸወታ',
      );
  String get keno => _t('ኬኖ', 'Keno', 'Keno', 'ኬኖ');
  String get spin => _t('ስፒን', 'Spin', 'Naanna\'i', 'ስፒን');
  String get telegramBingoBot => _t('የቴሌግራም ቢንጎ ቦት', 'Telegram Bingo Bot', 'Bot Bingo Telegram', 'ቦት ቴሌግራም ቢንጎ');
  String get onlineCasino => _t('ኦንላይን ካሲኖ', 'Online Casino', 'Kaasinoo olaayinii', 'ኦንላይን ካሲኖ');
  String appVersion(String v) => '$appName · v$v';

  String get enterFullScreen =>
      _t('ሙሉ ማያ ገፅ', 'Full screen', 'Iskiriinii guutuu', 'ምሉእ ስክሪን');
  String get exitFullScreen => _t(
        'ከሙሉ ማያ ገፅ ውጣ',
        'Exit full screen',
        'Iskiriinii guutuu irraa ba\'i',
        'ካብ ምሉእ ስክሪን ውጻእ',
      );
  String get fullScreenShortcut => _t('F11 · Esc', 'F11 · Esc', 'F11 · Esc', 'F11 · Esc');
  String get showControls =>
      _t('አሳይ', 'Show', 'Agarsiisi', 'ኣርኢ');
  String get hideControls =>
      _t('ደብቅ', 'Hide', 'Dhoksi', 'ሕብእ');

  // —— Settings screen ——
  String get account => _t('መለያ', 'Account', 'Akkaawuntii', 'ኣካውንት');
  String get accountHelp => _t(
        'ለመግባት እና የፓኬጅ ማመሳሰል በዚህ መሳሪያ ላይ ጥቅም ላይ የሚውሉ መለያዎችን ያርትዑ።',
        'Edit IDs used for login and package sync on this device.',
        'IDwwan seenuu fi walsimsiisa paakeejii meeshaa kana irratti fayyadaman gulaali.',
        'ንእታይን ምስላል ፓኬጅ ኣብዚ መሳርሒ ዝጥቀሙ መለለዪታት ኣርም።',
      );
  String get saveCashierPartnerIds =>
      _t('የካሺየር እና አጋር መለያ አስቀምጥ', 'Save cashier & partner IDs', 'ID kaashiyeerii fi partner olkaa\'i', 'መለለዪ ካሺየርን መሻርኽን ኣቐምጥ');
  String get deleteCashierAccount =>
      _t('የካሺየር መለያ ሰርዝ', 'Delete cashier account', 'Akkaawuntii kaashiyeerii haqi', 'ኣካውንት ካሺየር ሰርዝ');
  String get deleteCashierTitle =>
      _t('የካሺየር መለያ ይሰረዝ?', 'Delete cashier account?', 'Akkaawuntii kaashiyeerii haqamu?', 'ኣካውንት ካሺየር ይሰረዝ?');
  String get deleteCashierBody => _t(
        'ካሺየር፣ ጨዋታዎች፣ ግብይቶች እና ምዝገባዎች ከዚህ መሳሪያ ይሰረዛሉ። ካርዶች ይቆያሉ። እንደገና ማዋቀር ያስፈልጋል።',
        'This removes the cashier, games, transactions, and logs from this device. Cartelas stay installed. You will need to set up again.',
        'Kaashiyeerii, taphoota, daldala fi galmee meeshaa kana irraa haqama. Kaardiin ni hafa. Irra deebi\'anii qopheessuu qabda.',
        'ካሺየር፣ ጸወታታት፣ ግብይታትን መዝገባትን ካብዚ መሳርሒ ይሰርዝ። ካርድ ይቐር። ደጊምካ ምድላው ኣድላዪ እዩ።',
      );
  String get remoteAdminDomain => _t('ርቀት አድሚን ዶሜይን', 'Remote admin domain', 'Domeenii admin fagoo', 'ርሑቕ ዶመይን ኣድሚን');
  String get remoteAdminDomainHelp => _t(
        'ዶሜይን ብቻ ይቀይሩ። ንዑስ ዶሜይን (off1919) እና API መንገድ ቋሚ ናቸው።',
        'Change only the domain. Subdomain (off1919) and API path stay fixed.',
        'Domeenii qofa jijjiiri. Subdomain (off1919) fi karaa API dhaabbataa dha.',
        'ዶመይን ጥራይ ቀይር። ንኡስ ዶመይን (off1919)ን መንገዲ APIን ቋሚ እዮም።',
      );
  String get saveDomain => _t('ዶሜይን አስቀምጥ', 'Save domain', 'Domeenii olkaa\'i', 'ዶመይን ኣቐምጥ');
  String get cashierPartnerIdsSaved =>
      _t('የካሺየር እና አጋር መለያ ተቀምጧል', 'Cashier & partner IDs saved', 'ID kaashiyeerii fi partner olkaa\'ame', 'መለለዪ ካሺየርን መሻርኽን ተዓቅመ');

  // —— Dashboard / widgets ——
  String get freeTrialTitle =>
      _t('ነጻ ሙከራ', 'Free trial', 'Yaali bilisaa', 'ነጻ ምፍታሽ');
  String freeTrialRules(
    String currencyCode, {
    int stake = 10,
  }) {
    final currency = currencyLabel(currencyCode);
    final stakeLabel = priceOption(stake, currencyCode);
    return _t(
      'የቦርሳ ቀሪ 0 $currency — 1 ካርድ ብቻ፣ $stakeLabel ውርርድ።',
      'Wallet balance 0 $currency — 1 card only, $stakeLabel stake.',
      'Haftee kuusaa 0 $currency — kaardii 1 qofa, kaffaltii $stakeLabel.',
      'ቀሪ ቦርሳ 0 $currency — 1 ካርድ ጥራይ፣ $stakeLabel ውርርድ።',
    );
  }
  String freeTrialProgress(int used, int max, int remaining) => _t(
        '$used / $max ዙሮች ተጠቅመዋል · $remaining ቀሩ',
        '$used / $max rounds used · $remaining left',
        'Raaundii $used / $max fayyadame · $remaining hafe',
        '$used / $max ዙሮታት ተጠቒሙ · $remaining ተረፈ',
      );
  String get freeTrialExhaustedTitle => _t(
        'ነጻ ሙከራ አልቋል',
        'Free trial finished',
        'Yaali bilisaa xumurame',
        'ነጻ ምፍታሽ ተዛዚሙ',
      );
  String get freeTrialExhaustedBody => _t(
        '5 ነጻ ዙሮች ተጠቅመዋል። ለመቀጠል ፓኬጅ ይሙሉ።',
        'All 5 free rounds are used. Top up your package to continue.',
        'Raaundii bilisaa 5 hunda fayyadamame. Itti fufuuf paakeejii guuti.',
        'ኩሉ 5 ነጻ ዙሮታት ተጠቒሙ። ንምቕጻል ፓኬጅ ምልኣት።',
      );
  String freeTrialRulesViolation(
    String currencyCode, {
    int stake = 10,
  }) {
    final stakeLabel = priceOption(stake, currencyCode);
    return _t(
      'በነጻ ሙከራ ወቅት 1 ካርድ ብቻ $stakeLabel ይመዘገቡ።',
      'During free trial, register exactly 1 card at $stakeLabel.',
      'Yaali bilisaa keessatti kaardii 1 qofa kaffaltii $stakeLabel galchi.',
      'ኣብ ነጻ ምፍታሽ 1 ካርድ ጥራይ $stakeLabel ኣመዝግብ።',
    );
  }
  String get remainingPackage => _t('ቀሪ ፓኬጅ', 'Remaining Package', 'Paakeejii Hafe', 'ዝተረፈ ፓኬጅ');
  String get lastTransaction => _t('የመጨረሻ ግብይት', 'Last Transaction', 'Daldalli Dhumaa', 'ናይ መወዳእታ ግብይት');
  String get noTransaction => _t('ግብይት የለም', 'No transaction', 'Daldalli hin jiru', 'ግብይት የለን');
  String remainingPackageAmount(
    String balance, [
    String currencyCode = AppCurrency.defaultCode,
  ]) {
    final formatted = AppNumberFormat.formatString(balance);
    final currency = currencyLabel(currencyCode);
    return _t(
      '$formatted $currency',
      '$formatted $currency',
      '$currency $formatted',
      '$formatted $currency',
    );
  }

  String remainingPackageBirr(String balance) =>
      remainingPackageAmount(balance, AppCurrency.birr);
  String get packageDeposit => _t('ፓኬጅ ተቀማጭ', 'Package deposit', 'Kuufama paakeejii', 'ተቀማጺ ፓኬጅ');
  String get manualDeposit =>
      _t('እጅ ግብይት', 'Manual deposit', 'Kuufama harkaa', 'ኢድ ተቀማጺ');
  String get walletId => _t('የቦርሳ መለያ', 'Wallet ID', 'ID kuusaa', 'መለለዪ ቦርሳ');
  String get generatedId =>
      _t('የተፈጠረ መለያ', 'Generated ID', 'ID uumame', 'ዝተፈጠረ መለለዪ');
  String get randomNumberLabel =>
      _t('የዘፈቀደ ቁጥር', 'Random number', 'Lakkoofsa random', 'ዘፈርዕ ቁጽሪ');
  /// Combined Generated ID + 6-digit random (space-separated) for cashiers.
  String get depositRequestId =>
      _t('የጥያቄ ቁጥር', 'Request number', 'Lakkoofsa gaaffii', 'ቁጽሪ ሕቶ');
  String get amountLabel =>
      _t('መጠን ያስገቡ', 'Enter amount', 'Hanga galchi', 'መጠን ኣእትው');
  String get manualDepositAmountHint => _t(
        'Positive = deposit, negative = withdraw (e.g. -20000)',
        'Positive = deposit, negative = withdraw (e.g. -20000)',
        'Gamaa = kuufama, gad-aanaa = irraa hir\'uu (fkn. -20000)',
        'Positive = deposit, negative = withdraw (e.g. -20000)',
      );
  String get responseCodeLabel =>
      _t('የምላሽ ኮድ', 'Response code', 'Koodii deebii', 'ኮድ መልሲ');
  String get copyRequest => _t('ጥያቄ ቅዳ', 'Copy request', 'Gaaffii garagalchi', 'ሕቶ ቅዳ');
  String get refreshRandom =>
      _t('አዲስ ቁጥር', 'New random', 'Lakkoofsa haaraa', 'ሓድስ ቁጽሪ');
  String get depositCode => _t('የግብይት ኮድ', 'Deposit code', 'Koodii kuufama', 'ኮድ ተቀማጺ');
  String get depositCodeHint => _t(
        'ከአድሚን የተላከውን የምላሽ ኮድ',
        'Response code from admin',
        'Koodii deebii admin irraa',
        'ካብ ኣድሚን ዝመጸ ኮድ መልሲ',
      );
  String get applyManualDeposit =>
      _t('ግብይት ተግብር', 'Apply deposit', 'Kuufama hojiirsi', 'ተቀማጺ ኣተግብር');
  String get manualDepositHelp => _t(
        'መጠን ያስገቡ፣ «ጥያቄ ቅዳ» ይጫኑ፣ ከዚያ የምላሽ ኮድ ያስገቡ።',
        'Enter amount, tap Copy request, then enter the response code.',
        'Hanga galchi, «Gaaffii garagalchi» tuqi, achiis koodii deebii galchi.',
        'መጠን ኣእትው፣ «ሕቶ ቅዳ» ጠውቕ፣ ድሕሪኡ ኮድ መልሲ ኣእትው።',
      );
  String get manualDepositHelpTitle =>
      _t('የእጅ ግብይት እገዛ', 'Manual deposit help', 'Gargaarsa kuufama harkaa', 'ሓገዝ ኢድ ተቀማጺ');
  String get manualDepositHelpBody => _t(
        '① የቦርሳ መለያ — ካሺየር መለያዎ ለአድሚን ነው።\n'
        '② የጥያቄ ቁጥር — የመሳሪያ መለያ + 6-አሃዝ ዘፈቀደ ቁጥር (በክፍተት)። ↻ አዲስ ቁጥር የዘፈቀደውን ብቻ ይቀይራል።\n'
        '③ መጠን — አዎንታዊ ግብይት ይጨምራል፤ አሉታዊ (ለምሳሌ -20000) ከቦርሳ ይቀንሳል።\n'
        '④ ጥያቄ ቅዳ — ሁሉንም መረጃ ለአድሚን ይቅዳል (SMS/ስልክ)።\n'
        '⑤ የምላሽ ኮድ — ከአድሚን የተላከውን ቁጥር ያስገቡ፣ ከዚያ «ግብይት ተግብር»።\n\n'
        'ኢንተርኔት አያስፈልግም።',
        '① Wallet ID — your cashier ID for the admin.\n'
        '② Request number — device ID + 6-digit random (space). ↻ refreshes only the random part.\n'
        '③ Amount — positive deposits; negative (e.g. -20000) withdraws from wallet.\n'
        '④ Copy request — copies all fields to send to admin (SMS/phone).\n'
        '⑤ Response code — enter the code from admin, then tap Apply deposit.\n\n'
        'No internet required.',
        '① ID kuusaa — ID kaashiyeerii kee adminf.\n'
        '② Lakkoofsa gaaffii — ID meeshaa + 6 digit random (bakka duwwaa). ↻ random qofa haaromsa.\n'
        '③ Hanga — hanga kuufama birr.\n'
        '④ Gaaffii garagalchi — odeeffannoo hunda adminf.\n'
        '⑤ Koodii deebii — koodii admin irraa galchi, «Kuufama hojiirsi» tuqi.\n\n'
        'Interneetiin hin barbaachisu.',
        '① መለለዪ ቦርሳ — መለለዪ ካሺየርኻ ንኣድሚን።\n'
        '② ቁጽሪ ሕቶ — መለለዪ መሳርሒ + 6 ቁጽሪ ዘፈርዕ (ብባዶ ቦታ)። ↻ ንዘፈርዕ ጥራይ የሐድስ።\n'
        '③ መጠን — መጠን ተቀማጺ ብብር።\n'
        '④ ሕቶ ቅዳ — ኩሉ ሓበሬታ ንኣድሚን።\n'
        '⑤ ኮድ መልሲ — ካብ ኣድሚን ዝመጸ ኮድ ኣእትው፣ «ተቀማጺ ኣተግብር» ጠውቕ።\n\n'
        'ኢንተርነት የዐዘንን።',
      );
  String get manualDepositRequestSection =>
      _t('ጥያቄ', 'Request', 'Gaaffii', 'ሕቶ');
  String get manualDepositResponseSection => _t(
        'እዚአ የምላሽ ኮድ ያስገቡ',
        'Enter response code here',
        'Koodii deebii asitti galchi',
        'እዚአ ኮድ መልሲ ኣእትው',
      );
  String get invalidDepositAmount => _t(
        'Enter a non-zero amount.',
        'Enter a non-zero amount.',
        'Hanga zero hin taane galchi.',
        'Enter a non-zero amount.',
      );
  String insufficientWalletForWithdrawal(String balance) => _t(
        'Insufficient wallet balance. Current balance: $balance birr',
        'Insufficient wallet balance. Current balance: $balance birr',
        'Hafteen kuusaa gahaa miti. Haftee ammaa: birr $balance',
        'Insufficient wallet balance. Current balance: $balance birr',
      );
  String get invalidDepositCode => _t(
        'የምላሽ ኮድ ትክክል አይደለም።',
        'Invalid response code.',
        'Koodiin deebii sirrii miti.',
        'ኮድ መልሲ ቅኑዕ ኣይኮነን።',
      );
  String get duplicateDepositCode => _t(
        'ይህ ጥያቄ ቀድሞ ተጠቅሟል።',
        'This deposit request was already used.',
        'Gaaffiin kun duraan fayyadameera.',
        'እዚ ሕቶ ቀዲሑ ተጠቒሙ ኣሎ።',
      );
  String manualDepositLocked(String countdown) => _t(
        'ብዙ ተሞክረዋል። $countdown በኋላ እንደገና ይሞክሩ።',
        'Too many failed attempts. Try again in $countdown.',
        'Yaalii hedduun darbe. $countdown booda irra deebi\'i.',
        'ብዙሕ ፈተነ። ድሕሪ $countdown ደጊምካ ፈትን።',
      );
  String manualDepositAttemptsRemaining(int remaining) => _t(
        'የምላሽ ኮድ ትክክል አይደለም። $remaining ሙከራዎች ቀሩ።',
        'Invalid response code. $remaining attempts remaining.',
        'Koodiin deebii sirrii miti. Yaalii $remaining hafe.',
        'ኮድ መልሲ ቅኑዕ ኣይኮነን። $remaining ፈተነታት ተሪሑ።',
      );
  String manualDepositSuccess(String balance) => _t(
        'ግብይት ተጠናቋል። አዲስ ቀሪ: $balance ብር',
        'Deposit applied. New balance: $balance birr',
        'Kuufamni hojiirra oole. Haftee haaraa: birr $balance',
        'ተቀማጺ ተኸኢኑ። ሓድሽ ቀሪ: $balance ብር',
      );
  String get fetchingPackage =>
      _t('ፓኬጅ በመጠየቅ ላይ…', 'Fetching package…', 'Paakeejii gaafachaa jira…', 'ፓኬጅ ይሕተት…');
  String get reFetch => _t('እንደገና ጠይቅ', 'Re-fetch', 'Irra deebi\'i', 'ደጊምካ ሕተት');
  String get noResponse => _t('ምላሽ የለም', 'No response', 'Deebiin hin jiru', 'መልሲ የለን');
  String get roundColumn => _t('ዙር', 'Round', 'Raaundii', 'ዙር');

  String recentResultsFor(int round) =>
      _t('የቅርብ ጊዜ ውጤቶች (ዙር $round)', 'Recent Results (Round $round)', 'Bu\'aa Dhiyoo (Raaundii $round)', 'ናይ ቀረባ ግዜ ውጽኢታት (ዙር $round)');

  String get waitingForCalls =>
      _t('— ጥሪ በመጠበቅ ላይ —', '— Waiting for calls —', '— Waamicha eegaa jira —', '— ጻዕሪ ይጽበ… —');

  // —— Report table ——
  String get fromDateBeforeToDate => _t(
        'የመጀመሪያ ቀን ከመጨረሻ ቀን በፊት ወይም እኩል መሆን አለበት።',
        'From date must be on or before To date.',
        'Guyyaan jalqabaa guyyaa xumuraa dura ykn walqixa ta\'uu qaba.',
        'ካብ ዕለት ክሳዕ ዕለት ቅድሚ ወይ ምስ ክኸውን ኣለዎ።',
      );
  String get onlyLastTwoMonths => _t(
        'የመጨረሻዎቹ 2 ወራት ብቻ ይፈቀዳሉ።',
        'Only last 2 months allowed.',
        'Ji\'oota 2 dhumaa qofa hayyamama.',
        'ናይ መወዳእታ 2 ወርሒ ጥራይ ይፍቀድ።',
      );
  String get betTime => _t('የውርርድ ጊዜ', 'Bet Time', 'Yeroo kaffaltii', 'ግዜ ውርርድ');
  String get onCall => _t('በጥሪ', 'On Call', 'Waamicha', 'ኣብ ጻዕሪ');
  String get winnerNumber => _t('አሸናፊ ቁጥር', 'Winner Number', 'Lakkoofsa mo\'aa', 'ቁጽሪ ዓዋተኛ');
  String get totalCard => _t('ጠቅላላ ካርድ', 'Total Card', 'Kaardii waliigalaa', 'ጠቕላላ ካርድ');
  String get totalBet => _t('ጠቅላላ ውርርድ', 'Total Bet', 'Kaffaltii waliigalaa', 'ጠቕላላ ውርርድ');
  String get paid => _t('ተከፍሏል', 'Paid', 'Kaffalame', 'ተኸፊሉ');
  String get income => _t('ገቢ', 'Income', 'Galii', 'ኣታዊ');
  String get bonus => _t('ቦነስ', 'Bonus', 'Bonasii', 'ቦነስ');

  String prizeBonusLabel(num amount) {
    final formatted = AppNumberFormat.format(amount.round());
    return _t(
      'ቦነስ $formatted ብር',
      'Bonus $formatted birr',
      'Bonasii birr $formatted',
      'ቦነስ $formatted ብር',
    );
  }
  String get net => _t('ንጥረ', 'Net', 'Qulqulluu', 'ንጹር');
  String get win => _t('አሸናፊ', 'Win', 'Mo\'aa', 'ዓወት');

  /// Short column titles for the mobile report table.
  List<String> reportTableHeadersCompact(String currencyCode) {
    final stake = currencyCompact(currencyCode);
    return switch (language) {
      AppLanguage.am => [
        'ጊዜ',
        'ዙር',
        'ጥሪ',
        'ዓድ',
        'ካርድ',
        stake,
        'ውርርድ',
        'ተከፍ',
        'ገቢ',
        'ቦነስ',
        'ንጥረ',
      ],
      AppLanguage.en => [
        'Time',
        'Rnd',
        'Call',
        'Win',
        'Crd',
        stake,
        'Bet',
        'Paid',
        'Inc',
        'Bon',
        'Net',
      ],
      AppLanguage.om => [
        'Yeroo',
        'Raan',
        'Waam',
        'Mo\'aa',
        'Kaard',
        stake,
        'Kaff',
        'Kaffal',
        'Galii',
        'Bonas',
        'Qulq',
      ],
      AppLanguage.ti => [
        'ግዜ',
        'ዙር',
        'ጻዕሪ',
        'ዓወት',
        'ካርድ',
        stake,
        'ውርርድ',
        'ተኸፊ',
        'ኣታዊ',
        'ቦነስ',
        'ንጹር',
      ],
    };
  }

  String reportRowSummary(int bet, int net, String winners) => _t(
        'ውርርድ $bet · ንጥረ $net · አሸናፊ: $winners',
        'Bet $bet · Net $net · Win: $winners',
        'Kaffaltii $bet · Qulqulluu $net · Mo\'aa: $winners',
        'ውርርድ $bet · ንጹር $net · ዓወት: $winners',
      );
  String reportTotalsSummary({
    required int totalBet,
    required double totalPaid,
    required double totalIncome,
    required double totalBonus,
    required double netIncome,
  }) =>
      _t(
        'ውርርድ $totalBet · ተከፍሏል ${totalPaid.toStringAsFixed(0)} · ገቢ ${totalIncome.toStringAsFixed(0)} · ቦነስ ${totalBonus.toStringAsFixed(0)} · ንጥረ ${netIncome.toStringAsFixed(0)}',
        'Bet $totalBet · Paid ${totalPaid.toStringAsFixed(0)} · Inc ${totalIncome.toStringAsFixed(0)} · Bon ${totalBonus.toStringAsFixed(0)} · Net ${netIncome.toStringAsFixed(0)}',
        'Kaffaltii $totalBet · Kaffalame ${totalPaid.toStringAsFixed(0)} · Galii ${totalIncome.toStringAsFixed(0)} · Bonasii ${totalBonus.toStringAsFixed(0)} · Qulqulluu ${netIncome.toStringAsFixed(0)}',
        'ውርርድ $totalBet · ተኸፊሉ ${totalPaid.toStringAsFixed(0)} · ኣታዊ ${totalIncome.toStringAsFixed(0)} · ቦነስ ${totalBonus.toStringAsFixed(0)} · ንጹር ${netIncome.toStringAsFixed(0)}',
      );
}

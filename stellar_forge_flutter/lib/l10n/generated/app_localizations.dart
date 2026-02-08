import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('nl'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Stellar Forge'**
  String get appTitle;

  /// No description provided for @tapToInitialize.
  ///
  /// In en, this message translates to:
  /// **'TAP TO INITIALIZE'**
  String get tapToInitialize;

  /// No description provided for @commandDeck.
  ///
  /// In en, this message translates to:
  /// **'COMMAND DECK'**
  String get commandDeck;

  /// No description provided for @systemParameters.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PARAMETERS'**
  String get systemParameters;

  /// No description provided for @progressSync.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS SYNC'**
  String get progressSync;

  /// No description provided for @cloudSaveActive.
  ///
  /// In en, this message translates to:
  /// **'Cloud Save active via CrazyGames'**
  String get cloudSaveActive;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZone;

  /// No description provided for @wipeCoreMemory.
  ///
  /// In en, this message translates to:
  /// **'WIPE CORE MEMORY'**
  String get wipeCoreMemory;

  /// No description provided for @connectGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'CONNECT GOOGLE PLAY'**
  String get connectGooglePlay;

  /// No description provided for @playOffline.
  ///
  /// In en, this message translates to:
  /// **'PLAY OFFLINE'**
  String get playOffline;

  /// No description provided for @manualCloudSave.
  ///
  /// In en, this message translates to:
  /// **'MANUAL CLOUD SAVE'**
  String get manualCloudSave;

  /// No description provided for @manualCloudLoad.
  ///
  /// In en, this message translates to:
  /// **'MANUAL CLOUD LOAD'**
  String get manualCloudLoad;

  /// No description provided for @backToGame.
  ///
  /// In en, this message translates to:
  /// **'BACK TO GAME'**
  String get backToGame;

  /// No description provided for @upgradeQueue.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE QUEUE'**
  String get upgradeQueue;

  /// No description provided for @universeMetrics.
  ///
  /// In en, this message translates to:
  /// **'UNIVERSE METRICS'**
  String get universeMetrics;

  /// No description provided for @ascensionProtocol.
  ///
  /// In en, this message translates to:
  /// **'ASCENSION PROTOCOL'**
  String get ascensionProtocol;

  /// No description provided for @currentBonus.
  ///
  /// In en, this message translates to:
  /// **'Current Bonus'**
  String get currentBonus;

  /// No description provided for @potentialGain.
  ///
  /// In en, this message translates to:
  /// **'POTENTIAL GAIN'**
  String get potentialGain;

  /// No description provided for @initiateRebirth.
  ///
  /// In en, this message translates to:
  /// **'INITIATE REBIRTH'**
  String get initiateRebirth;

  /// No description provided for @moreEnergyRequired.
  ///
  /// In en, this message translates to:
  /// **'MORE ENERGY REQUIRED'**
  String get moreEnergyRequired;

  /// No description provided for @cancelSequence.
  ///
  /// In en, this message translates to:
  /// **'CANCEL SEQUENCE'**
  String get cancelSequence;

  /// No description provided for @initializeWarp.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZE WARP'**
  String get initializeWarp;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LOCATION'**
  String get currentLocation;

  /// No description provided for @multiverseConduit.
  ///
  /// In en, this message translates to:
  /// **'MULTIVERSE CONDUIT'**
  String get multiverseConduit;

  /// No description provided for @restrictedTech.
  ///
  /// In en, this message translates to:
  /// **'RESTRICTED TECH'**
  String get restrictedTech;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'COST'**
  String get cost;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'OUTPUT'**
  String get output;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'LV'**
  String get level;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'REWARD'**
  String get reward;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @matter.
  ///
  /// In en, this message translates to:
  /// **'Matter'**
  String get matter;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @stardust.
  ///
  /// In en, this message translates to:
  /// **'Stardust'**
  String get stardust;

  /// No description provided for @quarks.
  ///
  /// In en, this message translates to:
  /// **'Quarks'**
  String get quarks;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @mana.
  ///
  /// In en, this message translates to:
  /// **'Mana'**
  String get mana;

  /// No description provided for @voidShards.
  ///
  /// In en, this message translates to:
  /// **'Void Shards'**
  String get voidShards;

  /// No description provided for @chronosDust.
  ///
  /// In en, this message translates to:
  /// **'Chronos Dust'**
  String get chronosDust;

  /// No description provided for @solarFlares.
  ///
  /// In en, this message translates to:
  /// **'Solar Flares'**
  String get solarFlares;

  /// No description provided for @bits.
  ///
  /// In en, this message translates to:
  /// **'Bits'**
  String get bits;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

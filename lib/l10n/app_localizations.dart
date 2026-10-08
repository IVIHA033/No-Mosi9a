import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'No Mosi9a'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Watch anything. Hear only the voices.'**
  String get tagline;

  /// No description provided for @homeOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Music removal is off'**
  String get homeOffTitle;

  /// No description provided for @homeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button to start'**
  String get homeOffSubtitle;

  /// No description provided for @homeStartingTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get homeStartingTitle;

  /// No description provided for @homeStartingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing the voice model'**
  String get homeStartingSubtitle;

  /// No description provided for @homeOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Music removal is on'**
  String get homeOnTitle;

  /// No description provided for @homeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open YouTube, Instagram, Facebook… and play any video.'**
  String get homeOnSubtitle;

  /// No description provided for @powerStart.
  ///
  /// In en, this message translates to:
  /// **'Start music removal'**
  String get powerStart;

  /// No description provided for @powerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop music removal'**
  String get powerStop;

  /// No description provided for @liveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveTitle;

  /// No description provided for @liveVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice detected · words protected'**
  String get liveVoice;

  /// No description provided for @meterOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original sound'**
  String get meterOriginal;

  /// No description provided for @meterClean.
  ///
  /// In en, this message translates to:
  /// **'What you hear'**
  String get meterClean;

  /// No description provided for @statDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get statDelay;

  /// No description provided for @statQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get statQuality;

  /// No description provided for @statCpu.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get statCpu;

  /// No description provided for @delayValue.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String delayValue(int ms);

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(int value);

  /// No description provided for @qualityAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get qualityAuto;

  /// No description provided for @qualityFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get qualityFull;

  /// No description provided for @qualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get qualityBalanced;

  /// No description provided for @qualityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get qualityLight;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps being cleaned'**
  String get appsTitle;

  /// No description provided for @appsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No app is playing sound right now.'**
  String get appsEmpty;

  /// No description provided for @appCleaning.
  ///
  /// In en, this message translates to:
  /// **'Music removed'**
  String get appCleaning;

  /// No description provided for @appBlocked.
  ///
  /// In en, this message translates to:
  /// **'This app blocks processing — plays unchanged'**
  String get appBlocked;

  /// No description provided for @appNotMuted.
  ///
  /// In en, this message translates to:
  /// **'Could not silence the original sound'**
  String get appNotMuted;

  /// No description provided for @boostTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice boost'**
  String get boostTitle;

  /// No description provided for @boostValue.
  ///
  /// In en, this message translates to:
  /// **'+{db} dB'**
  String boostValue(int db);

  /// No description provided for @boostHint.
  ///
  /// In en, this message translates to:
  /// **'Music removal lowers the overall loudness. Boost the voice back up.'**
  String get boostHint;

  /// No description provided for @autoSwitchedNote.
  ///
  /// In en, this message translates to:
  /// **'The best quality was too heavy for this phone, so the app switched to a lighter one.'**
  String get autoSwitchedNote;

  /// No description provided for @errorProjectionDenied.
  ///
  /// In en, this message translates to:
  /// **'Android did not allow the audio capture. Tap start and accept.'**
  String get errorProjectionDenied;

  /// No description provided for @errorProjectionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Android stopped the audio capture (screen locked or sharing stopped).'**
  String get errorProjectionRevoked;

  /// No description provided for @errorSetupMissing.
  ///
  /// In en, this message translates to:
  /// **'The one-time activation is missing or was removed.'**
  String get errorSetupMissing;

  /// No description provided for @errorEngineFailed.
  ///
  /// In en, this message translates to:
  /// **'The audio engine stopped unexpectedly. Try again.'**
  String get errorEngineFailed;

  /// No description provided for @errorCaptureDenied.
  ///
  /// In en, this message translates to:
  /// **'The audio capture permission is missing.'**
  String get errorCaptureDenied;

  /// No description provided for @actionOpenSetup.
  ///
  /// In en, this message translates to:
  /// **'Open setup'**
  String get actionOpenSetup;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @tipTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip: one-tap switch'**
  String get tipTileTitle;

  /// No description provided for @tipTileBody.
  ///
  /// In en, this message translates to:
  /// **'Add the “No music” tile to your quick settings to switch it on or off without leaving YouTube.'**
  String get tipTileBody;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// No description provided for @setupIntro.
  ///
  /// In en, this message translates to:
  /// **'Two minutes, one time only. After that, a single tap is enough.'**
  String get setupIntro;

  /// No description provided for @setupStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get setupStatusDone;

  /// No description provided for @setupStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get setupStatusMissing;

  /// No description provided for @setupStatusOptional.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get setupStatusOptional;

  /// No description provided for @setupStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Allow audio capture'**
  String get setupStep1Title;

  /// No description provided for @setupStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Android calls this “record audio”: it lets the app receive the sound of other apps. Nothing is recorded, saved or sent anywhere.'**
  String get setupStep1Body;

  /// No description provided for @setupStep1Button.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get setupStep1Button;

  /// No description provided for @setupStep2Title.
  ///
  /// In en, this message translates to:
  /// **'One-time activation'**
  String get setupStep2Title;

  /// No description provided for @setupStep2Body.
  ///
  /// In en, this message translates to:
  /// **'To silence the original sound of YouTube & co — so you only hear the cleaned voice — Android needs a permission that can only be given once, from developer tools. It stays until you uninstall the app.'**
  String get setupStep2Body;

  /// No description provided for @setupWithPc.
  ///
  /// In en, this message translates to:
  /// **'With a computer (ADB)'**
  String get setupWithPc;

  /// No description provided for @setupWithPcSteps.
  ///
  /// In en, this message translates to:
  /// **'1. On the phone: Settings › About phone › tap “Build number” 7 times.\n2. Settings › Developer options › turn on “USB debugging”.\n3. Plug the phone into the computer and run:'**
  String get setupWithPcSteps;

  /// No description provided for @setupWithoutPc.
  ///
  /// In en, this message translates to:
  /// **'Without a computer (Shizuku)'**
  String get setupWithoutPc;

  /// No description provided for @setupShizukuSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Install Shizuku (free, open source).\n2. Start it with “Wireless debugging” (Shizuku explains how).\n3. Come back here and tap the button below.'**
  String get setupShizukuSteps;

  /// No description provided for @setupShizukuButton.
  ///
  /// In en, this message translates to:
  /// **'Grant with Shizuku'**
  String get setupShizukuButton;

  /// No description provided for @setupShizukuGet.
  ///
  /// In en, this message translates to:
  /// **'Get Shizuku'**
  String get setupShizukuGet;

  /// No description provided for @setupShizukuNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is not running. Open Shizuku and start it first.'**
  String get setupShizukuNotRunning;

  /// No description provided for @setupShizukuDenied.
  ///
  /// In en, this message translates to:
  /// **'The Shizuku permission was refused.'**
  String get setupShizukuDenied;

  /// No description provided for @setupShizukuFailed.
  ///
  /// In en, this message translates to:
  /// **'Shizuku could not grant the permission.'**
  String get setupShizukuFailed;

  /// No description provided for @setupCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get setupCheckAgain;

  /// No description provided for @setupCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get setupCopy;

  /// No description provided for @setupCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get setupCopied;

  /// No description provided for @setupCommandsHint.
  ///
  /// In en, this message translates to:
  /// **'The second command is recommended: it skips Android\'s capture pop-up and keeps the app working with the screen off.'**
  String get setupCommandsHint;

  /// No description provided for @setupPermDump.
  ///
  /// In en, this message translates to:
  /// **'Mute other apps'**
  String get setupPermDump;

  /// No description provided for @setupPermProjection.
  ///
  /// In en, this message translates to:
  /// **'Auto-consent & screen off'**
  String get setupPermProjection;

  /// No description provided for @setupStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Keep it running'**
  String get setupStep3Title;

  /// No description provided for @setupStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Some phones close background apps to save battery. Let No Mosi9a run without restrictions.'**
  String get setupStep3Body;

  /// No description provided for @setupStep3Button.
  ///
  /// In en, this message translates to:
  /// **'Battery settings'**
  String get setupStep3Button;

  /// No description provided for @setupFinish.
  ///
  /// In en, this message translates to:
  /// **'Start using the app'**
  String get setupFinish;

  /// No description provided for @setupMuteUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone does not have the audio effect needed to silence other apps, so the app cannot work on it.'**
  String get setupMuteUnsupported;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsQuality.
  ///
  /// In en, this message translates to:
  /// **'Sound quality'**
  String get settingsQuality;

  /// No description provided for @settingsQualityAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses the best quality your phone can handle'**
  String get settingsQualityAutoDesc;

  /// No description provided for @settingsQualityFullDesc.
  ///
  /// In en, this message translates to:
  /// **'Most natural voice (48 kHz), uses more battery'**
  String get settingsQualityFullDesc;

  /// No description provided for @settingsQualityBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Same music removal, phone-call sound (16 kHz)'**
  String get settingsQualityBalancedDesc;

  /// No description provided for @settingsQualityLightDesc.
  ///
  /// In en, this message translates to:
  /// **'For older phones: lighter, removes a little less music (16 kHz)'**
  String get settingsQualityLightDesc;

  /// No description provided for @settingsSpeedTest.
  ///
  /// In en, this message translates to:
  /// **'Test my phone again'**
  String get settingsSpeedTest;

  /// No description provided for @settingsSpeedTestDone.
  ///
  /// In en, this message translates to:
  /// **'The speed test will run on the next start.'**
  String get settingsSpeedTestDone;

  /// No description provided for @settingsLatency.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get settingsLatency;

  /// No description provided for @settingsLatencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Low keeps lips in sync. Stable avoids crackles on slow phones.'**
  String get settingsLatencyDesc;

  /// No description provided for @latencyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get latencyLow;

  /// No description provided for @latencyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get latencyNormal;

  /// No description provided for @latencyStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get latencyStable;

  /// No description provided for @settingsProtection.
  ///
  /// In en, this message translates to:
  /// **'Voice protection'**
  String get settingsProtection;

  /// No description provided for @settingsProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'When someone talks over loud music, the AI can cut parts of their words. Voice protection notices speech and keeps the words whole. Music alone is always removed.'**
  String get settingsProtectionDesc;

  /// No description provided for @protectionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get protectionOff;

  /// No description provided for @protectionNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get protectionNormal;

  /// No description provided for @protectionStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get protectionStrong;

  /// No description provided for @protectionOffDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum removal. Words can be cut when the music is loud.'**
  String get protectionOffDesc;

  /// No description provided for @protectionNormalDesc.
  ///
  /// In en, this message translates to:
  /// **'Recommended. Words stay whole; a faint trace of music can remain under the voice, only while someone talks.'**
  String get protectionNormalDesc;

  /// No description provided for @protectionStrongDesc.
  ///
  /// In en, this message translates to:
  /// **'For very loud music. Keeps the most speech; more music stays under the voice while someone talks.'**
  String get protectionStrongDesc;

  /// No description provided for @settingsExcluded.
  ///
  /// In en, this message translates to:
  /// **'Apps to leave untouched'**
  String get settingsExcluded;

  /// No description provided for @settingsExcludedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None} =1{1 app} other{{count} apps}}'**
  String settingsExcludedCount(int count);

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @settingsBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get settingsBattery;

  /// No description provided for @settingsBatteryDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow running in the background'**
  String get settingsBatteryDesc;

  /// No description provided for @settingsSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup & permissions'**
  String get settingsSetup;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'100% offline'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The app has no internet permission. The sound is processed on your phone and never leaves it.'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @excludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave untouched'**
  String get excludedTitle;

  /// No description provided for @excludedHint.
  ///
  /// In en, this message translates to:
  /// **'Sound from these apps is not processed or muted (for example a Quran app or a podcast app).'**
  String get excludedHint;

  /// No description provided for @excludedSearch.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get excludedSearch;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get helpTitle;

  /// No description provided for @helpHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How does it work?'**
  String get helpHowTitle;

  /// No description provided for @helpHowBody.
  ///
  /// In en, this message translates to:
  /// **'The app receives the sound other apps play, runs it through an on-device neural network (DPDFNet) that keeps human voices and removes everything else, and plays the cleaned voice. At the same time it silences the original sound of those apps.'**
  String get helpHowBody;

  /// No description provided for @help100Title.
  ///
  /// In en, this message translates to:
  /// **'Is the music removed 100%?'**
  String get help100Title;

  /// No description provided for @help100Body.
  ///
  /// In en, this message translates to:
  /// **'Instrumental music is removed almost completely: in tests, music alone went from full volume to silence (−60 to −100 dB), and speech over music stays clear. Singing is a human voice, so the voice of a singer can remain (the instruments are still removed).'**
  String get help100Body;

  /// No description provided for @helpAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Which apps work?'**
  String get helpAppsTitle;

  /// No description provided for @helpAppsBody.
  ///
  /// In en, this message translates to:
  /// **'YouTube, Instagram, Facebook, TikTok, Snapchat and most video apps. Apps that forbid audio capture (Netflix, Spotify, some browsers like Chrome, a few games) keep playing unchanged — the app shows them as “blocks processing”.'**
  String get helpAppsBody;

  /// No description provided for @helpAdbTitle.
  ///
  /// In en, this message translates to:
  /// **'Why the one-time activation?'**
  String get helpAdbTitle;

  /// No description provided for @helpAdbBody.
  ///
  /// In en, this message translates to:
  /// **'Android lets apps capture other apps\' sound, but not silence them. The activation gives the app the right to see which app is playing so it can mute its original sound. Without it, you would hear the music and the cleaned voice at the same time.'**
  String get helpAdbBody;

  /// No description provided for @helpDelayTitle.
  ///
  /// In en, this message translates to:
  /// **'The sound is slightly late'**
  String get helpDelayTitle;

  /// No description provided for @helpDelayBody.
  ///
  /// In en, this message translates to:
  /// **'Cleaning needs about 50 ms plus the audio buffers. Choose “Low” delay in the settings. Bluetooth headphones add their own delay.'**
  String get helpDelayBody;

  /// No description provided for @helpBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get helpBatteryTitle;

  /// No description provided for @helpBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'The model runs only while sound is playing. When the video is paused the engine idles. Light quality uses about 4× less processing.'**
  String get helpBatteryBody;

  /// No description provided for @helpPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get helpPrivacyTitle;

  /// No description provided for @helpPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything happens on the phone and the app cannot access the internet at all. Android shows a screen-sharing icon while it runs, because capturing other apps\' sound goes through the same system as screen sharing; the app never looks at your screen.'**
  String get helpPrivacyBody;

  /// No description provided for @helpTroubleTitle.
  ///
  /// In en, this message translates to:
  /// **'I hear the music and the voice together'**
  String get helpTroubleTitle;

  /// No description provided for @helpTroubleBody.
  ///
  /// In en, this message translates to:
  /// **'Check that the activation is done (Settings › Setup). If the app is listed as “blocks processing”, Android does not allow cleaning it.'**
  String get helpTroubleBody;

  /// No description provided for @helpCutTitle.
  ///
  /// In en, this message translates to:
  /// **'Words are cut or the voice drops'**
  String get helpCutTitle;

  /// No description provided for @helpCutBody.
  ///
  /// In en, this message translates to:
  /// **'When the music is as loud as the voice, the AI can take parts of words for music. Voice protection (Settings) listens for speech with two separate detectors and keeps the words, while music alone is still removed. If words are still cut, set it to Strong, or choose Full quality if your phone can run it.'**
  String get helpCutBody;

  /// No description provided for @helpSilentTitle.
  ///
  /// In en, this message translates to:
  /// **'An app has no sound after closing No Mosi9a'**
  String get helpSilentTitle;

  /// No description provided for @helpSilentBody.
  ///
  /// In en, this message translates to:
  /// **'If No Mosi9a is force-stopped while a video plays, Android can keep that video muted. Open No Mosi9a or pull down the quick settings: it restores the sound automatically. Stopping it with its own button never causes this.'**
  String get helpSilentBody;

  /// No description provided for @helpSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Open setup'**
  String get helpSetupAction;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

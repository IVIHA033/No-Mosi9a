// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'No Mosi9a';

  @override
  String get tagline => 'Watch anything. Hear only the voices.';

  @override
  String get homeOffTitle => 'Music removal is off';

  @override
  String get homeOffSubtitle => 'Tap the button to start';

  @override
  String get homeStartingTitle => 'Starting…';

  @override
  String get homeStartingSubtitle => 'Preparing the voice model';

  @override
  String get homeOnTitle => 'Music removal is on';

  @override
  String get homeOnSubtitle =>
      'Open YouTube, Instagram, Facebook… and play any video.';

  @override
  String get powerStart => 'Start music removal';

  @override
  String get powerStop => 'Stop music removal';

  @override
  String get liveTitle => 'Live';

  @override
  String get liveVoice => 'Voice detected · words protected';

  @override
  String get meterOriginal => 'Original sound';

  @override
  String get meterClean => 'What you hear';

  @override
  String get statDelay => 'Delay';

  @override
  String get statQuality => 'Quality';

  @override
  String get statCpu => 'Processor';

  @override
  String delayValue(int ms) {
    return '$ms ms';
  }

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String get qualityAuto => 'Automatic';

  @override
  String get qualityFull => 'Full';

  @override
  String get qualityBalanced => 'Balanced';

  @override
  String get qualityLight => 'Light';

  @override
  String get appsTitle => 'Apps being cleaned';

  @override
  String get appsEmpty => 'No app is playing sound right now.';

  @override
  String get appCleaning => 'Music removed';

  @override
  String get appBlocked => 'This app blocks processing — plays unchanged';

  @override
  String get appNotMuted => 'Could not silence the original sound';

  @override
  String get boostTitle => 'Voice boost';

  @override
  String boostValue(int db) {
    return '+$db dB';
  }

  @override
  String get boostHint =>
      'Music removal lowers the overall loudness. Boost the voice back up.';

  @override
  String get autoSwitchedNote =>
      'The best quality was too heavy for this phone, so the app switched to a lighter one.';

  @override
  String get errorProjectionDenied =>
      'Android did not allow the audio capture. Tap start and accept.';

  @override
  String get errorProjectionRevoked =>
      'Android stopped the audio capture (screen locked or sharing stopped).';

  @override
  String get errorSetupMissing =>
      'The one-time activation is missing or was removed.';

  @override
  String get errorEngineFailed =>
      'The audio engine stopped unexpectedly. Try again.';

  @override
  String get errorCaptureDenied => 'The audio capture permission is missing.';

  @override
  String get actionOpenSetup => 'Open setup';

  @override
  String get actionRetry => 'Try again';

  @override
  String get tipTileTitle => 'Tip: one-tap switch';

  @override
  String get tipTileBody =>
      'Add the “No music” tile to your quick settings to switch it on or off without leaving YouTube.';

  @override
  String get setupTitle => 'Setup';

  @override
  String get setupIntro =>
      'Two minutes, one time only. After that, a single tap is enough.';

  @override
  String get setupStatusDone => 'Done';

  @override
  String get setupStatusMissing => 'To do';

  @override
  String get setupStatusOptional => 'Recommended';

  @override
  String get setupStep1Title => 'Allow audio capture';

  @override
  String get setupStep1Body =>
      'Android calls this “record audio”: it lets the app receive the sound of other apps. Nothing is recorded, saved or sent anywhere.';

  @override
  String get setupStep1Button => 'Allow';

  @override
  String get setupStep2Title => 'One-time activation';

  @override
  String get setupStep2Body =>
      'To silence the original sound of YouTube & co — so you only hear the cleaned voice — Android needs a permission that can only be given once, from developer tools. It stays until you uninstall the app.';

  @override
  String get setupWithPc => 'With a computer (ADB)';

  @override
  String get setupWithPcSteps =>
      '1. On the phone: Settings › About phone › tap “Build number” 7 times.\n2. Settings › Developer options › turn on “USB debugging”.\n3. Plug the phone into the computer and run:';

  @override
  String get setupWithoutPc => 'Without a computer (Shizuku)';

  @override
  String get setupShizukuSteps =>
      '1. Install Shizuku (free, open source).\n2. Start it with “Wireless debugging” (Shizuku explains how).\n3. Come back here and tap the button below.';

  @override
  String get setupShizukuButton => 'Grant with Shizuku';

  @override
  String get setupShizukuGet => 'Get Shizuku';

  @override
  String get setupShizukuNotRunning =>
      'Shizuku is not running. Open Shizuku and start it first.';

  @override
  String get setupShizukuDenied => 'The Shizuku permission was refused.';

  @override
  String get setupShizukuFailed => 'Shizuku could not grant the permission.';

  @override
  String get setupCheckAgain => 'Check again';

  @override
  String get setupCopy => 'Copy';

  @override
  String get setupCopied => 'Copied';

  @override
  String get setupCommandsHint =>
      'The second command is recommended: it skips Android\'s capture pop-up and keeps the app working with the screen off.';

  @override
  String get setupPermDump => 'Mute other apps';

  @override
  String get setupPermProjection => 'Auto-consent & screen off';

  @override
  String get setupStep3Title => 'Keep it running';

  @override
  String get setupStep3Body =>
      'Some phones close background apps to save battery. Let No Mosi9a run without restrictions.';

  @override
  String get setupStep3Button => 'Battery settings';

  @override
  String get setupFinish => 'Start using the app';

  @override
  String get setupMuteUnsupported =>
      'This phone does not have the audio effect needed to silence other apps, so the app cannot work on it.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsQuality => 'Sound quality';

  @override
  String get settingsQualityAutoDesc =>
      'Uses the best quality your phone can handle';

  @override
  String get settingsQualityFullDesc =>
      'Most natural voice (48 kHz), uses more battery';

  @override
  String get settingsQualityBalancedDesc =>
      'Same music removal, phone-call sound (16 kHz)';

  @override
  String get settingsQualityLightDesc =>
      'For older phones: lighter, removes a little less music (16 kHz)';

  @override
  String get settingsSpeedTest => 'Test my phone again';

  @override
  String get settingsSpeedTestDone =>
      'The speed test will run on the next start.';

  @override
  String get settingsLatency => 'Delay';

  @override
  String get settingsLatencyDesc =>
      'Low keeps lips in sync. Stable avoids crackles on slow phones.';

  @override
  String get latencyLow => 'Low';

  @override
  String get latencyNormal => 'Normal';

  @override
  String get latencyStable => 'Stable';

  @override
  String get settingsProtection => 'Voice protection';

  @override
  String get settingsProtectionDesc =>
      'When someone talks over loud music, the AI can cut parts of their words. Voice protection notices speech and keeps the words whole. Music alone is always removed.';

  @override
  String get protectionOff => 'Off';

  @override
  String get protectionNormal => 'Normal';

  @override
  String get protectionStrong => 'Strong';

  @override
  String get protectionOffDesc =>
      'Maximum removal. Words can be cut when the music is loud.';

  @override
  String get protectionNormalDesc =>
      'Recommended. Words stay whole; a faint trace of music can remain under the voice, only while someone talks.';

  @override
  String get protectionStrongDesc =>
      'For very loud music. Keeps the most speech; more music stays under the voice while someone talks.';

  @override
  String get settingsExcluded => 'Apps to leave untouched';

  @override
  String settingsExcludedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'None',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get settingsBattery => 'Battery optimization';

  @override
  String get settingsBatteryDesc => 'Allow running in the background';

  @override
  String get settingsSetup => 'Setup & permissions';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyTitle => '100% offline';

  @override
  String get settingsPrivacy =>
      'The app has no internet permission. The sound is processed on your phone and never leaves it.';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get excludedTitle => 'Leave untouched';

  @override
  String get excludedHint =>
      'Sound from these apps is not processed or muted (for example a Quran app or a podcast app).';

  @override
  String get excludedSearch => 'Search apps';

  @override
  String get helpTitle => 'Questions';

  @override
  String get helpHowTitle => 'How does it work?';

  @override
  String get helpHowBody =>
      'The app receives the sound other apps play, runs it through an on-device neural network (DPDFNet) that keeps human voices and removes everything else, and plays the cleaned voice. At the same time it silences the original sound of those apps.';

  @override
  String get help100Title => 'Is the music removed 100%?';

  @override
  String get help100Body =>
      'Instrumental music is removed almost completely: in tests, music alone went from full volume to silence (−60 to −100 dB), and speech over music stays clear. Singing is a human voice, so the voice of a singer can remain (the instruments are still removed).';

  @override
  String get helpAppsTitle => 'Which apps work?';

  @override
  String get helpAppsBody =>
      'YouTube, Instagram, Facebook, TikTok, Snapchat and most video apps. Apps that forbid audio capture (Netflix, Spotify, some browsers like Chrome, a few games) keep playing unchanged — the app shows them as “blocks processing”.';

  @override
  String get helpAdbTitle => 'Why the one-time activation?';

  @override
  String get helpAdbBody =>
      'Android lets apps capture other apps\' sound, but not silence them. The activation gives the app the right to see which app is playing so it can mute its original sound. Without it, you would hear the music and the cleaned voice at the same time.';

  @override
  String get helpDelayTitle => 'The sound is slightly late';

  @override
  String get helpDelayBody =>
      'Cleaning needs about 50 ms plus the audio buffers. Choose “Low” delay in the settings. Bluetooth headphones add their own delay.';

  @override
  String get helpBatteryTitle => 'Battery';

  @override
  String get helpBatteryBody =>
      'The model runs only while sound is playing. When the video is paused the engine idles. Light quality uses about 4× less processing.';

  @override
  String get helpPrivacyTitle => 'Privacy';

  @override
  String get helpPrivacyBody =>
      'Everything happens on the phone and the app cannot access the internet at all. Android shows a screen-sharing icon while it runs, because capturing other apps\' sound goes through the same system as screen sharing; the app never looks at your screen.';

  @override
  String get helpTroubleTitle => 'I hear the music and the voice together';

  @override
  String get helpTroubleBody =>
      'Check that the activation is done (Settings › Setup). If the app is listed as “blocks processing”, Android does not allow cleaning it.';

  @override
  String get helpCutTitle => 'Words are cut or the voice drops';

  @override
  String get helpCutBody =>
      'When the music is as loud as the voice, the AI can take parts of words for music. Voice protection (Settings) listens for speech with two separate detectors and keeps the words, while music alone is still removed. If words are still cut, set it to Strong, or choose Full quality if your phone can run it.';

  @override
  String get helpSilentTitle => 'An app has no sound after closing No Mosi9a';

  @override
  String get helpSilentBody =>
      'If No Mosi9a is force-stopped while a video plays, Android can keep that video muted. Open No Mosi9a or pull down the quick settings: it restores the sound automatically. Stopping it with its own button never causes this.';

  @override
  String get helpSetupAction => 'Open setup';
}

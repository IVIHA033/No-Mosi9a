// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'No Mosi9a';

  @override
  String get tagline =>
      'Regardez ce que vous voulez. N\'entendez que les voix.';

  @override
  String get homeOffTitle => 'Suppression de la musique désactivée';

  @override
  String get homeOffSubtitle => 'Appuyez sur le bouton pour démarrer';

  @override
  String get homeStartingTitle => 'Démarrage…';

  @override
  String get homeStartingSubtitle => 'Préparation du modèle vocal';

  @override
  String get homeOnTitle => 'Suppression de la musique activée';

  @override
  String get homeOnSubtitle =>
      'Ouvrez YouTube, Instagram, Facebook… et lancez une vidéo.';

  @override
  String get powerStart => 'Démarrer la suppression de la musique';

  @override
  String get powerStop => 'Arrêter la suppression de la musique';

  @override
  String get liveTitle => 'En direct';

  @override
  String get liveVoice => 'Voix détectée · mots protégés';

  @override
  String get meterOriginal => 'Son d\'origine';

  @override
  String get meterClean => 'Ce que vous entendez';

  @override
  String get statDelay => 'Délai';

  @override
  String get statQuality => 'Qualité';

  @override
  String get statCpu => 'Processeur';

  @override
  String delayValue(int ms) {
    return '$ms ms';
  }

  @override
  String percentValue(int value) {
    return '$value %';
  }

  @override
  String get qualityAuto => 'Automatique';

  @override
  String get qualityFull => 'Complète';

  @override
  String get qualityBalanced => 'Équilibrée';

  @override
  String get qualityLight => 'Légère';

  @override
  String get appsTitle => 'Apps nettoyées';

  @override
  String get appsEmpty => 'Aucune app ne joue de son pour le moment.';

  @override
  String get appCleaning => 'Musique supprimée';

  @override
  String get appBlocked => 'Cette app bloque le traitement — son inchangé';

  @override
  String get appNotMuted => 'Impossible de couper le son d\'origine';

  @override
  String get boostTitle => 'Amplification de la voix';

  @override
  String boostValue(int db) {
    return '+$db dB';
  }

  @override
  String get boostHint =>
      'Supprimer la musique baisse le volume global. Remontez la voix ici.';

  @override
  String get autoSwitchedNote =>
      'La meilleure qualité était trop lourde pour ce téléphone : l\'app est passée à une qualité plus légère.';

  @override
  String get errorProjectionDenied =>
      'Android n\'a pas autorisé la capture audio. Appuyez sur démarrer et acceptez.';

  @override
  String get errorProjectionRevoked =>
      'Android a arrêté la capture audio (écran verrouillé ou partage arrêté).';

  @override
  String get errorSetupMissing =>
      'L\'activation unique est absente ou a été retirée.';

  @override
  String get errorEngineFailed =>
      'Le moteur audio s\'est arrêté de façon inattendue. Réessayez.';

  @override
  String get errorCaptureDenied => 'L\'autorisation de capture audio manque.';

  @override
  String get actionOpenSetup => 'Ouvrir la configuration';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get tipTileTitle => 'Astuce : un seul geste';

  @override
  String get tipTileBody =>
      'Ajoutez la vignette « Sans musique » aux réglages rapides pour l\'activer ou la couper sans quitter YouTube.';

  @override
  String get setupTitle => 'Configuration';

  @override
  String get setupIntro =>
      'Deux minutes, une seule fois. Ensuite, un seul appui suffit.';

  @override
  String get setupStatusDone => 'Fait';

  @override
  String get setupStatusMissing => 'À faire';

  @override
  String get setupStatusOptional => 'Recommandé';

  @override
  String get setupStep1Title => 'Autoriser la capture audio';

  @override
  String get setupStep1Body =>
      'Android appelle cela « enregistrer l\'audio » : l\'app peut recevoir le son des autres apps. Rien n\'est enregistré, conservé ni envoyé.';

  @override
  String get setupStep1Button => 'Autoriser';

  @override
  String get setupStep2Title => 'Activation unique';

  @override
  String get setupStep2Body =>
      'Pour couper le son d\'origine de YouTube & co — afin de n\'entendre que la voix nettoyée — Android exige une autorisation qu\'on ne peut donner qu\'une fois, via les outils développeur. Elle reste jusqu\'à la désinstallation.';

  @override
  String get setupWithPc => 'Avec un ordinateur (ADB)';

  @override
  String get setupWithPcSteps =>
      '1. Sur le téléphone : Paramètres › À propos › appuyez 7 fois sur « Numéro de build ».\n2. Paramètres › Options pour les développeurs › activez « Débogage USB ».\n3. Branchez le téléphone à l\'ordinateur et lancez :';

  @override
  String get setupWithoutPc => 'Sans ordinateur (Shizuku)';

  @override
  String get setupShizukuSteps =>
      '1. Installez Shizuku (gratuit, open source).\n2. Démarrez-le avec le « Débogage sans fil » (Shizuku explique comment).\n3. Revenez ici et appuyez sur le bouton ci-dessous.';

  @override
  String get setupShizukuButton => 'Autoriser via Shizuku';

  @override
  String get setupShizukuGet => 'Obtenir Shizuku';

  @override
  String get setupShizukuNotRunning =>
      'Shizuku n\'est pas démarré. Ouvrez Shizuku et démarrez-le d\'abord.';

  @override
  String get setupShizukuDenied => 'L\'autorisation Shizuku a été refusée.';

  @override
  String get setupShizukuFailed =>
      'Shizuku n\'a pas pu accorder l\'autorisation.';

  @override
  String get setupCheckAgain => 'Vérifier à nouveau';

  @override
  String get setupCopy => 'Copier';

  @override
  String get setupCopied => 'Copié';

  @override
  String get setupCommandsHint =>
      'La deuxième commande est recommandée : elle évite la fenêtre de capture d\'Android et garde l\'app active écran éteint.';

  @override
  String get setupPermDump => 'Couper les autres apps';

  @override
  String get setupPermProjection => 'Accord automatique & écran éteint';

  @override
  String get setupStep3Title => 'Rester actif';

  @override
  String get setupStep3Body =>
      'Certains téléphones ferment les apps en arrière-plan pour économiser la batterie. Laissez No Mosi9a fonctionner sans restriction.';

  @override
  String get setupStep3Button => 'Réglages batterie';

  @override
  String get setupFinish => 'Commencer';

  @override
  String get setupMuteUnsupported =>
      'Ce téléphone n\'a pas l\'effet audio nécessaire pour couper les autres apps : l\'app ne peut pas fonctionner ici.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsQuality => 'Qualité du son';

  @override
  String get settingsQualityAutoDesc =>
      'Utilise la meilleure qualité que votre téléphone supporte';

  @override
  String get settingsQualityFullDesc =>
      'Voix la plus naturelle (48 kHz), consomme plus';

  @override
  String get settingsQualityBalancedDesc =>
      'Même suppression de la musique, son qualité téléphone (16 kHz)';

  @override
  String get settingsQualityLightDesc =>
      'Pour les anciens téléphones : plus léger, retire un peu moins de musique (16 kHz)';

  @override
  String get settingsSpeedTest => 'Retester mon téléphone';

  @override
  String get settingsSpeedTestDone =>
      'Le test de vitesse sera relancé au prochain démarrage.';

  @override
  String get settingsLatency => 'Délai';

  @override
  String get settingsLatencyDesc =>
      'Bas garde les lèvres synchronisées. Stable évite les grésillements sur les téléphones lents.';

  @override
  String get latencyLow => 'Bas';

  @override
  String get latencyNormal => 'Normal';

  @override
  String get latencyStable => 'Stable';

  @override
  String get settingsProtection => 'Protection de la voix';

  @override
  String get settingsProtectionDesc =>
      'Quand quelqu\'un parle sur une musique forte, l\'IA peut couper des bouts de mots. La protection de la voix repère la parole et garde les mots entiers. La musique seule est toujours retirée.';

  @override
  String get protectionOff => 'Désactivée';

  @override
  String get protectionNormal => 'Normale';

  @override
  String get protectionStrong => 'Forte';

  @override
  String get protectionOffDesc =>
      'Retrait maximal. Des mots peuvent être coupés quand la musique est forte.';

  @override
  String get protectionNormalDesc =>
      'Recommandé. Les mots restent entiers ; une légère trace de musique peut rester sous la voix, seulement pendant qu\'on parle.';

  @override
  String get protectionStrongDesc =>
      'Pour une musique très forte. Garde le plus de parole ; plus de musique reste sous la voix pendant qu\'on parle.';

  @override
  String get settingsExcluded => 'Apps à ne pas toucher';

  @override
  String settingsExcludedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'Aucune',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du téléphone';

  @override
  String get settingsBattery => 'Optimisation de la batterie';

  @override
  String get settingsBatteryDesc =>
      'Autoriser le fonctionnement en arrière-plan';

  @override
  String get settingsSetup => 'Configuration & autorisations';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacyTitle => '100 % hors ligne';

  @override
  String get settingsPrivacy =>
      'L\'app n\'a pas l\'autorisation Internet. Le son est traité sur votre téléphone et n\'en sort jamais.';

  @override
  String get settingsLicenses => 'Licences open source';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get excludedTitle => 'Ne pas toucher';

  @override
  String get excludedHint =>
      'Le son de ces apps n\'est ni traité ni coupé (par exemple une app de Coran ou de podcasts).';

  @override
  String get excludedSearch => 'Rechercher une app';

  @override
  String get helpTitle => 'Questions';

  @override
  String get helpHowTitle => 'Comment ça marche ?';

  @override
  String get helpHowBody =>
      'L\'app reçoit le son joué par les autres apps, le fait passer dans un réseau de neurones sur le téléphone (DPDFNet) qui garde les voix humaines et retire tout le reste, puis joue la voix nettoyée. En même temps, elle coupe le son d\'origine de ces apps.';

  @override
  String get help100Title => 'La musique est-elle supprimée à 100 % ?';

  @override
  String get help100Body =>
      'La musique instrumentale est retirée presque entièrement : en test, la musique seule est passée du plein volume au silence (−60 à −100 dB), et la parole sur fond musical reste claire. Le chant est une voix humaine : la voix d\'un chanteur peut rester (les instruments sont retirés).';

  @override
  String get helpAppsTitle => 'Quelles apps fonctionnent ?';

  @override
  String get helpAppsBody =>
      'YouTube, Instagram, Facebook, TikTok, Snapchat et la plupart des apps vidéo. Les apps qui interdisent la capture audio (Netflix, Spotify, certains navigateurs comme Chrome, quelques jeux) restent inchangées — l\'app les affiche comme « bloque le traitement ».';

  @override
  String get helpAdbTitle => 'Pourquoi l\'activation unique ?';

  @override
  String get helpAdbBody =>
      'Android permet de capturer le son des autres apps, mais pas de le couper. L\'activation donne à l\'app le droit de voir quelle app joue du son pour couper son son d\'origine. Sans elle, vous entendriez la musique et la voix nettoyée en même temps.';

  @override
  String get helpDelayTitle => 'Le son est un peu en retard';

  @override
  String get helpDelayBody =>
      'Le nettoyage demande environ 50 ms plus les tampons audio. Choisissez le délai « Bas » dans les réglages. Les écouteurs Bluetooth ajoutent leur propre délai.';

  @override
  String get helpBatteryTitle => 'Batterie';

  @override
  String get helpBatteryBody =>
      'Le modèle ne tourne que pendant la lecture. Quand la vidéo est en pause, le moteur se met en veille. La qualité légère demande environ 4 fois moins de calcul.';

  @override
  String get helpPrivacyTitle => 'Vie privée';

  @override
  String get helpPrivacyBody =>
      'Tout se passe sur le téléphone et l\'app ne peut pas accéder à Internet. Android affiche une icône de partage d\'écran pendant le fonctionnement, car la capture du son des autres apps passe par le même système que le partage d\'écran ; l\'app ne regarde jamais votre écran.';

  @override
  String get helpTroubleTitle => 'J\'entends la musique et la voix ensemble';

  @override
  String get helpTroubleBody =>
      'Vérifiez que l\'activation est faite (Réglages › Configuration). Si l\'app apparaît comme « bloque le traitement », Android interdit de la nettoyer.';

  @override
  String get helpCutTitle => 'Des mots sont coupés ou la voix disparaît';

  @override
  String get helpCutBody =>
      'Quand la musique est aussi forte que la voix, l\'IA peut prendre des bouts de mots pour de la musique. La protection de la voix (Réglages) écoute la parole avec deux détecteurs distincts et garde les mots, tandis que la musique seule reste retirée. Si des mots sont encore coupés, choisissez Forte, ou la qualité Complète si votre téléphone la supporte.';

  @override
  String get helpSilentTitle =>
      'Une app n\'a plus de son après avoir fermé No Mosi9a';

  @override
  String get helpSilentBody =>
      'Si No Mosi9a est arrêtée de force pendant une vidéo, Android peut garder cette vidéo muette. Ouvrez No Mosi9a ou déroulez les réglages rapides : le son revient automatiquement. L\'arrêter avec son propre bouton ne provoque jamais cela.';

  @override
  String get helpSetupAction => 'Ouvrir la configuration';
}

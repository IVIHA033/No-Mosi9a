// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'No Mosi9a';

  @override
  String get tagline => 'شاهد ما تريد، واسمع الأصوات فقط.';

  @override
  String get homeOffTitle => 'إزالة الموسيقى متوقفة';

  @override
  String get homeOffSubtitle => 'اضغط على الزر للتشغيل';

  @override
  String get homeStartingTitle => 'جارٍ التشغيل…';

  @override
  String get homeStartingSubtitle => 'تجهيز نموذج الصوت';

  @override
  String get homeOnTitle => 'إزالة الموسيقى مفعّلة';

  @override
  String get homeOnSubtitle =>
      'افتح يوتيوب أو إنستغرام أو فيسبوك… وشغّل أي فيديو.';

  @override
  String get powerStart => 'تشغيل إزالة الموسيقى';

  @override
  String get powerStop => 'إيقاف إزالة الموسيقى';

  @override
  String get liveTitle => 'مباشر';

  @override
  String get liveVoice => 'تم رصد كلام · الكلمات محمية';

  @override
  String get meterOriginal => 'الصوت الأصلي';

  @override
  String get meterClean => 'ما تسمعه';

  @override
  String get statDelay => 'التأخير';

  @override
  String get statQuality => 'الجودة';

  @override
  String get statCpu => 'المعالج';

  @override
  String delayValue(int ms) {
    return '$ms ملّي ثانية';
  }

  @override
  String percentValue(int value) {
    return '$value٪';
  }

  @override
  String get qualityAuto => 'تلقائي';

  @override
  String get qualityFull => 'كاملة';

  @override
  String get qualityBalanced => 'متوازنة';

  @override
  String get qualityLight => 'خفيفة';

  @override
  String get appsTitle => 'التطبيقات التي يتم تنقيتها';

  @override
  String get appsEmpty => 'لا يوجد تطبيق يشغّل الصوت حالياً.';

  @override
  String get appCleaning => 'تمت إزالة الموسيقى';

  @override
  String get appBlocked => 'هذا التطبيق يمنع المعالجة — يُشغَّل كما هو';

  @override
  String get appNotMuted => 'تعذّر كتم الصوت الأصلي';

  @override
  String get boostTitle => 'تقوية الصوت';

  @override
  String boostValue(int db) {
    return '‎+$db dB';
  }

  @override
  String get boostHint =>
      'إزالة الموسيقى تخفض الصوت العام، يمكنك تقوية صوت الكلام هنا.';

  @override
  String get autoSwitchedNote =>
      'الجودة الأعلى ثقيلة على هذا الهاتف، فانتقل التطبيق إلى جودة أخف.';

  @override
  String get errorProjectionDenied =>
      'لم يسمح أندرويد بالتقاط الصوت. اضغط تشغيل ثم وافق.';

  @override
  String get errorProjectionRevoked =>
      'أوقف أندرويد التقاط الصوت (تم قفل الشاشة أو إيقاف المشاركة).';

  @override
  String get errorSetupMissing => 'التفعيل لمرة واحدة غير موجود أو تمت إزالته.';

  @override
  String get errorEngineFailed =>
      'توقف محرك الصوت بشكل غير متوقع. حاول مرة أخرى.';

  @override
  String get errorCaptureDenied => 'إذن التقاط الصوت غير ممنوح.';

  @override
  String get actionOpenSetup => 'فتح الإعداد';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get tipTileTitle => 'نصيحة: تشغيل بلمسة واحدة';

  @override
  String get tipTileBody =>
      'أضف زر «بلا موسيقى» إلى الإعدادات السريعة لتشغيله أو إيقافه دون مغادرة يوتيوب.';

  @override
  String get setupTitle => 'الإعداد';

  @override
  String get setupIntro => 'دقيقتان ولمرة واحدة فقط. بعدها تكفي لمسة واحدة.';

  @override
  String get setupStatusDone => 'تم';

  @override
  String get setupStatusMissing => 'مطلوب';

  @override
  String get setupStatusOptional => 'مستحسن';

  @override
  String get setupStep1Title => 'السماح بالتقاط الصوت';

  @override
  String get setupStep1Body =>
      'يسمّيه أندرويد «تسجيل الصوت»: يسمح للتطبيق باستقبال صوت التطبيقات الأخرى. لا يتم تسجيل أي شيء أو حفظه أو إرساله.';

  @override
  String get setupStep1Button => 'سماح';

  @override
  String get setupStep2Title => 'تفعيل لمرة واحدة';

  @override
  String get setupStep2Body =>
      'لكتم الصوت الأصلي ليوتيوب وغيره — حتى تسمع الكلام المنقّى فقط — يحتاج أندرويد إلى إذن خاص لا يُمنح إلا مرة واحدة عبر أدوات المطوّر. ويبقى حتى تحذف التطبيق.';

  @override
  String get setupWithPc => 'باستعمال حاسوب (ADB)';

  @override
  String get setupWithPcSteps =>
      '1. في الهاتف: الإعدادات › حول الهاتف › اضغط على «رقم الإصدار» 7 مرات.\n2. الإعدادات › خيارات المطوّر › فعّل «تصحيح أخطاء USB».\n3. أوصل الهاتف بالحاسوب ونفّذ:';

  @override
  String get setupWithoutPc => 'بدون حاسوب (Shizuku)';

  @override
  String get setupShizukuSteps =>
      '1. ثبّت تطبيق Shizuku (مجاني ومفتوح المصدر).\n2. شغّله عبر «تصحيح الأخطاء اللاسلكي» (يشرح Shizuku الطريقة).\n3. عد إلى هنا واضغط على الزر أدناه.';

  @override
  String get setupShizukuButton => 'منح الإذن عبر Shizuku';

  @override
  String get setupShizukuGet => 'تحميل Shizuku';

  @override
  String get setupShizukuNotRunning =>
      'Shizuku غير مشغّل. افتح Shizuku وشغّله أولاً.';

  @override
  String get setupShizukuDenied => 'تم رفض إذن Shizuku.';

  @override
  String get setupShizukuFailed => 'لم يتمكن Shizuku من منح الإذن.';

  @override
  String get setupCheckAgain => 'تحقّق مجدداً';

  @override
  String get setupCopy => 'نسخ';

  @override
  String get setupCopied => 'تم النسخ';

  @override
  String get setupCommandsHint =>
      'الأمر الثاني مستحسن: يتخطى نافذة التأكيد في أندرويد ويُبقي التطبيق يعمل والشاشة مطفأة.';

  @override
  String get setupPermDump => 'كتم التطبيقات الأخرى';

  @override
  String get setupPermProjection => 'موافقة تلقائية والشاشة مطفأة';

  @override
  String get setupStep3Title => 'إبقاؤه يعمل';

  @override
  String get setupStep3Body =>
      'بعض الهواتف تغلق التطبيقات في الخلفية لتوفير البطارية. اسمح لـ No Mosi9a بالعمل دون قيود.';

  @override
  String get setupStep3Button => 'إعدادات البطارية';

  @override
  String get setupFinish => 'ابدأ استعمال التطبيق';

  @override
  String get setupMuteUnsupported =>
      'هذا الهاتف لا يوفّر المؤثر الصوتي اللازم لكتم التطبيقات الأخرى، لذلك لا يمكن للتطبيق العمل عليه.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsQuality => 'جودة الصوت';

  @override
  String get settingsQualityAutoDesc => 'يستعمل أفضل جودة يتحمّلها هاتفك';

  @override
  String get settingsQualityFullDesc =>
      'أوضح وأطبع صوت (48 كيلوهرتز)، يستهلك بطارية أكثر';

  @override
  String get settingsQualityBalancedDesc =>
      'نفس قوة إزالة الموسيقى، بصوت بجودة المكالمات (16 كيلوهرتز)';

  @override
  String get settingsQualityLightDesc =>
      'للهواتف القديمة: أخف، لكنه يزيل موسيقى أقل قليلاً (16 كيلوهرتز)';

  @override
  String get settingsSpeedTest => 'اختبر سرعة هاتفي من جديد';

  @override
  String get settingsSpeedTestDone =>
      'سيُجرى اختبار السرعة عند التشغيل القادم.';

  @override
  String get settingsLatency => 'التأخير';

  @override
  String get settingsLatencyDesc =>
      '«منخفض» يحافظ على تزامن الشفاه. «مستقر» يمنع التقطّع في الهواتف البطيئة.';

  @override
  String get latencyLow => 'منخفض';

  @override
  String get latencyNormal => 'عادي';

  @override
  String get latencyStable => 'مستقر';

  @override
  String get settingsProtection => 'حماية الكلام';

  @override
  String get settingsProtectionDesc =>
      'عندما يتكلم شخص فوق موسيقى عالية، قد يقطع الذكاء الاصطناعي أجزاء من كلماته. حماية الكلام تكتشف الكلام وتحافظ على الكلمات كاملة. أما الموسيقى وحدها فتُحذف دائماً.';

  @override
  String get protectionOff => 'متوقفة';

  @override
  String get protectionNormal => 'عادية';

  @override
  String get protectionStrong => 'قوية';

  @override
  String get protectionOffDesc =>
      'أقصى حذف للموسيقى. قد تنقطع الكلمات عندما تكون الموسيقى عالية.';

  @override
  String get protectionNormalDesc =>
      'موصى بها. تبقى الكلمات كاملة، وقد يبقى أثر خفيف من الموسيقى تحت الصوت أثناء الكلام فقط.';

  @override
  String get protectionStrongDesc =>
      'للموسيقى العالية جداً. تحافظ على أكبر قدر من الكلام، ويبقى قدر أكبر من الموسيقى تحت الصوت أثناء الكلام.';

  @override
  String get settingsExcluded => 'تطبيقات لا تُعالَج';

  @override
  String settingsExcludedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تطبيق',
      many: '$count تطبيقاً',
      few: '$count تطبيقات',
      two: 'تطبيقان',
      one: 'تطبيق واحد',
      zero: 'لا شيء',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة الهاتف';

  @override
  String get settingsBattery => 'تحسين البطارية';

  @override
  String get settingsBatteryDesc => 'السماح بالعمل في الخلفية';

  @override
  String get settingsSetup => 'الإعداد والأذونات';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsPrivacyTitle => 'يعمل بدون إنترنت 100٪';

  @override
  String get settingsPrivacy =>
      'التطبيق لا يملك إذن الإنترنت أصلاً. تتم معالجة الصوت داخل هاتفك ولا يخرج منه أبداً.';

  @override
  String get settingsLicenses => 'تراخيص المصادر المفتوحة';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get excludedTitle => 'تطبيقات لا تُعالَج';

  @override
  String get excludedHint =>
      'صوت هذه التطبيقات لا يُعالَج ولا يُكتم (مثلاً تطبيق القرآن أو البودكاست).';

  @override
  String get excludedSearch => 'ابحث عن تطبيق';

  @override
  String get helpTitle => 'أسئلة';

  @override
  String get helpHowTitle => 'كيف يعمل؟';

  @override
  String get helpHowBody =>
      'يستقبل التطبيق الصوت الذي تشغّله التطبيقات الأخرى، ويمرّره عبر شبكة عصبية داخل الهاتف (DPDFNet) تحتفظ بالأصوات البشرية وتحذف كل ما عداها، ثم يشغّل الكلام المنقّى. وفي الوقت نفسه يكتم الصوت الأصلي لتلك التطبيقات.';

  @override
  String get help100Title => 'هل تُحذف الموسيقى 100٪؟';

  @override
  String get help100Body =>
      'تُحذف الموسيقى الآلية بشكل شبه كامل: في الاختبارات، انتقلت الموسيقى وحدها من الصوت الكامل إلى الصمت (من ‎−60 إلى ‎−100 dB)، ويبقى الكلام فوق الموسيقى واضحاً. أما الغناء فهو صوت بشري، لذلك قد يبقى صوت المغني (مع حذف الآلات).';

  @override
  String get helpAppsTitle => 'ما هي التطبيقات التي تعمل؟';

  @override
  String get helpAppsBody =>
      'يوتيوب، إنستغرام، فيسبوك، تيك توك، سناب شات ومعظم تطبيقات الفيديو. التطبيقات التي تمنع التقاط الصوت (نتفليكس، سبوتيفاي، بعض المتصفحات مثل كروم، وبعض الألعاب) تبقى كما هي — ويظهرها التطبيق بعبارة «يمنع المعالجة».';

  @override
  String get helpAdbTitle => 'لماذا التفعيل لمرة واحدة؟';

  @override
  String get helpAdbBody =>
      'يسمح أندرويد للتطبيقات بالتقاط صوت التطبيقات الأخرى، لكنه لا يسمح بكتمه. التفعيل يمنح التطبيق حق معرفة التطبيق الذي يشغّل الصوت لكي يكتم صوته الأصلي. بدونه ستسمع الموسيقى والكلام المنقّى معاً.';

  @override
  String get helpDelayTitle => 'الصوت متأخر قليلاً';

  @override
  String get helpDelayBody =>
      'التنقية تحتاج حوالي 50 ملّي ثانية إضافة إلى ذاكرة الصوت المؤقتة. اختر تأخيراً «منخفضاً» في الإعدادات. سماعات البلوتوث تضيف تأخيرها الخاص.';

  @override
  String get helpBatteryTitle => 'البطارية';

  @override
  String get helpBatteryBody =>
      'يعمل النموذج فقط أثناء تشغيل الصوت، وعند إيقاف الفيديو مؤقتاً يرتاح المحرك. الجودة الخفيفة تستهلك معالجة أقل بحوالي 4 مرات.';

  @override
  String get helpPrivacyTitle => 'الخصوصية';

  @override
  String get helpPrivacyBody =>
      'كل شيء يتم داخل الهاتف، والتطبيق لا يستطيع الوصول إلى الإنترنت إطلاقاً. قد يُظهر أندرويد أيقونة مشاركة الشاشة أثناء العمل، لأن التقاط صوت التطبيقات الأخرى يمرّ عبر نفس نظام مشاركة الشاشة؛ التطبيق لا ينظر إلى شاشتك أبداً.';

  @override
  String get helpTroubleTitle => 'أسمع الموسيقى والكلام معاً';

  @override
  String get helpTroubleBody =>
      'تأكد من إتمام التفعيل (الإعدادات › الإعداد). إذا ظهر التطبيق بعبارة «يمنع المعالجة» فإن أندرويد لا يسمح بتنقيته.';

  @override
  String get helpCutTitle => 'الكلام يتقطّع أو يختفي';

  @override
  String get helpCutBody =>
      'عندما تكون الموسيقى بقوة الصوت، قد يظن الذكاء الاصطناعي أن أجزاء من الكلمات موسيقى. حماية الكلام (في الإعدادات) تستمع للكلام بكاشفَين منفصلين وتحافظ على الكلمات، مع بقاء الموسيقى وحدها محذوفة. إذا بقي الكلام يتقطّع، اختر «قوية»، أو اختر الجودة «كاملة» إذا كان هاتفك يتحملها.';

  @override
  String get helpSilentTitle => 'تطبيق بدون صوت بعد إغلاق No Mosi9a';

  @override
  String get helpSilentBody =>
      'إذا تم إيقاف No Mosi9a إجبارياً أثناء تشغيل فيديو، قد يُبقي أندرويد ذلك الفيديو مكتوماً. افتح No Mosi9a أو اسحب الإعدادات السريعة: سيُرجع الصوت تلقائياً. الإيقاف بزر التطبيق نفسه لا يسبب هذا أبداً.';

  @override
  String get helpSetupAction => 'فتح الإعداد';
}

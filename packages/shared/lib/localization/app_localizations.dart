import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static const _localizedValues = <String, Map<String, String>>{
    'ar': {
      'appName': 'مدى التعليمية',
      'continue': 'متابعة',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'home': 'الرئيسية',
      'courses': 'الدورات',
      'profile': 'الملف الشخصي',
      'search': 'ابحث عن دورة',
      'featuredCourses': 'دورات مميزة',
      'categories': 'التصنيفات',
      'continueLearning': 'تابع التعلم',
      'subscription': 'الاشتراك',
      'onePlanAll': 'خطة واحدة لجميع الدورات',
      'iqd': 'د.ع',
    },
    'en': {
      'appName': 'Mada Learning',
      'continue': 'Continue',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'home': 'Home',
      'courses': 'Courses',
      'profile': 'Profile',
      'search': 'Search courses',
      'featuredCourses': 'Featured Courses',
      'categories': 'Categories',
      'continueLearning': 'Continue Learning',
      'subscription': 'Subscription',
      'onePlanAll': 'One plan for all courses',
      'iqd': 'IQD',
    },
  };

  String _t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  String get appName => _t('appName');
  String get continueLabel => _t('continue');
  String get login => _t('login');
  String get signup => _t('signup');
  String get email => _t('email');
  String get password => _t('password');
  String get home => _t('home');
  String get courses => _t('courses');
  String get profile => _t('profile');
  String get search => _t('search');
  String get featuredCourses => _t('featuredCourses');
  String get categories => _t('categories');
  String get continueLearning => _t('continueLearning');
  String get subscription => _t('subscription');
  String get onePlanAll => _t('onePlanAll');
  String get iqd => _t('iqd');

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    Intl.defaultLocale = locale.languageCode;
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}


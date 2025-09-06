// lib/app_language.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

enum MapLanguage { system, ko, en, ja, zhCN }

const _kLangKey = 'app.map.language';

/// 앱 전역에서 참조할 언어 상태 (3rd-party 패키지 없이 사용)
final ValueNotifier<MapLanguage> mapLanguageNotifier =
    ValueNotifier<MapLanguage>(MapLanguage.system);

/// 저장된 언어 불러오기 (앱 시작 시 1회 호출)
Future<void> initSavedMapLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kLangKey);
  switch (raw) {
    case 'ko': mapLanguageNotifier.value = MapLanguage.ko; break;
    case 'en': mapLanguageNotifier.value = MapLanguage.en; break;
    case 'ja': mapLanguageNotifier.value = MapLanguage.ja; break;
    case 'zh-CN': mapLanguageNotifier.value = MapLanguage.zhCN; break;
    default: mapLanguageNotifier.value = MapLanguage.system; break;
  }
}

/// 선택된 언어 저장
Future<void> setMapLanguage(MapLanguage lang) async {
  mapLanguageNotifier.value = lang;
  final prefs = await SharedPreferences.getInstance();
  String? raw;
  switch (lang) {
    case MapLanguage.ko: raw = 'ko'; break;
    case MapLanguage.en: raw = 'en'; break;
    case MapLanguage.ja: raw = 'ja'; break;
    case MapLanguage.zhCN: raw = 'zh-CN'; break;
    case MapLanguage.system: raw = null; break;
  }
  if (raw == null) {
    await prefs.remove(_kLangKey);
  } else {
    await prefs.setString(_kLangKey, raw);
  }
}

/// NaverMap에 전달할 언어 (system이면 null → SDK 기본 동작)
Locale? naverLocaleFrom(MapLanguage lang) {
  switch (lang) {
    case MapLanguage.ko:   return const Locale('ko', 'KR');
    case MapLanguage.en:   return const Locale('en', 'US');
    case MapLanguage.ja:   return const Locale('ja', 'JP');
    case MapLanguage.zhCN: return const Locale('zh', 'CN');
    case MapLanguage.system: return null;
  }
}

/// (선택) MaterialApp.locale에 쓰고 싶으면 사용
Locale? flutterLocaleFrom(MapLanguage lang) {
  switch (lang) {
    case MapLanguage.ko:   return const Locale('ko', 'KR');
    case MapLanguage.en:   return const Locale('en', 'US');
    case MapLanguage.ja:   return const Locale('ja', 'JP');
    case MapLanguage.zhCN: return const Locale('zh', 'CN');
    case MapLanguage.system: return null; // 시스템 로케일 사용
  }
}

String papagoCodeFrom(MapLanguage lang, {String fallback = 'ko'}) {
  switch (lang) {
    case MapLanguage.ko:   return 'ko';
    case MapLanguage.en:   return 'en';
    case MapLanguage.ja:   return 'ja';
    case MapLanguage.zhCN: return 'zh-CN';
    case MapLanguage.system:
      return fallback; // 시스템 로케일 쓰거나 기본값
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_language.dart';
import 'secrets.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;


String _toPapago(MapLanguage lang) => papagoCodeFrom(lang);

/// 간단 헬퍼: 현재 언어 설정 기준 번역
String _guessSource(String s) {
  final hasHangul = RegExp(r'[\uac00-\ud7a3]').hasMatch(s);
  final hasLatin  = RegExp(r'[A-Za-z]').hasMatch(s);
  if (hasHangul && !hasLatin) return 'ko';
  if (hasLatin  && !hasHangul) return 'en';
  // 섞여 있거나 알파벳/한글이 없으면 영어로 가정(필요 시 'ko'로 바꿔도 됨)
  return 'en';
}
Future<List<String>> translateMany({
  required List<String> texts,
  String source = 'auto',
  MapLanguage? to,
  bool fallbackToOriginalOnError = true,
}) async {
  if (texts.isEmpty) return const <String>[];

  final target = _toCode(to ?? mapLanguageNotifier.value);
  final src    = (source == 'auto') ? null : source;

  final uri = Uri.https(
    'translation.googleapis.com',
    '/language/translate/v2',
    {'key': googleTranslateApiKey},
  );

  final body = <String, dynamic>{
    'q': texts,                       // 배열로 보냄
    'target': target,
    if (src != null) 'source': src,   // 생략 시 자동감지
    'format': 'text',
    'model': 'nmt',
  };

  try {
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);
      final List list = (json['data']?['translations'] as List? ?? const []);
      return List.generate(texts.length, (i) {
        final raw = (i < list.length ? (list[i]['translatedText'] as String? ?? '') : '');
        final out = raw.isEmpty ? (fallbackToOriginalOnError ? texts[i] : '') : _unescapeHtml(raw);
        return out;
      });
    } else {
      if (kDebugMode) debugPrint('GCT v2 error ${res.statusCode}: ${res.body}');
      return fallbackToOriginalOnError ? texts : List.filled(texts.length, '');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('GCT v2 exception: $e');
    return fallbackToOriginalOnError ? texts : List.filled(texts.length, '');
  }
}
String _toCode(MapLanguage lang) {
  switch (lang) {
    case MapLanguage.ko:
      return 'ko';
    case MapLanguage.en:
      return 'en';
    case MapLanguage.ja:
      return 'ja';
    case MapLanguage.zhCN:
      return 'zh-CN';
    case MapLanguage.system:
    default:
      return 'ko'; // 시스템 기본 한국어로 처리(원하면 변경)
  }
}
String _unescapeHtml(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");
/// 현재 언어 설정 기준 번역 + 원문 자동 감지 지원
/// - source='auto'이면 `_guessSource`로 ko/en 추정
Future<String> translateText(
  String text, {
  String source = 'auto',
  MapLanguage? to,
  bool fallbackToOriginalOnError = true,
}) async {
  final t = text.trim();
  if (t.isEmpty) return text;

  final target = _toCode(to ?? mapLanguageNotifier.value);
  final src    = (source == 'auto') ? null : source; // auto면 null → Google 자동감지

  // src가 null이라면 비교 불가이므로 이 조기반환 조건은 실제로 거의 안 탑니다.
  if (src != null && src == target) return text;

  final uri = Uri.https(
    'translation.googleapis.com',
    '/language/translate/v2',
    {'key': googleTranslateApiKey},
  );

  final body = <String, dynamic>{
    'q': t,
    'target': target,
    if (src != null) 'source': src, // 생략 시 자동감지
    'format': 'text',
    'model': 'nmt',
  };

  try {
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);
      var out = (json['data']?['translations']?[0]?['translatedText'] as String?) ?? '';
      if (out.isEmpty) return fallbackToOriginalOnError ? text : '';
      out = _unescapeHtml(out); // HTML 엔티티 복원
      return out;
    } else {
      if (kDebugMode) debugPrint('GCT v2 error ${res.statusCode}: ${res.body}');
      return fallbackToOriginalOnError ? text : '';
    }
  } catch (e) {
    if (kDebugMode) debugPrint('GCT v2 exception: $e');
    return fallbackToOriginalOnError ? text : '';
  }
}

/// 재사용 가능한 위젯: 번역된 텍스트 보여주기
/// - 언어 변경(mapLanguageNotifier) 시 자동 재번역
/// - 대기 중 원문 유지로 깜빡임을 줄임(옵션)
class TranslatedText extends StatefulWidget {
  const TranslatedText(
    this.original, {
    super.key,
    this.source = 'auto',
    this.style,
    this.maxLines,
    this.overflow,
    this.placeholder,                 // 기본 null: 대기 중에도 원문 유지
    this.textAlign,
    this.strutStyle,
    this.showOriginalWhileLoading = true,
  });

  final String original;
  final String source;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? placeholder;
  final TextAlign? textAlign;
  final StrutStyle? strutStyle;

  /// true면 로딩 중에도 직전 번역/원문을 유지 (기본값 권장)
  final bool showOriginalWhileLoading;

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  late MapLanguage _lang;
  late Future<String> _future;
  String? _lastRendered; // 직전에 렌더한 텍스트(로딩 중 깜빡임 줄이기용)

  @override
  void initState() {
    super.initState();
    _lang = mapLanguageNotifier.value;
    _future = translateText(widget.original, source: widget.source, to: _lang);
    mapLanguageNotifier.addListener(_onLangChanged);
  }

  @override
  void didUpdateWidget(covariant TranslatedText old) {
    super.didUpdateWidget(old);
    // 원문/소스가 바뀌면 다시 번역
    if (old.original != widget.original || old.source != widget.source) {
      _future = translateText(widget.original, source: widget.source, to: _lang);
    }
  }

  void _onLangChanged() {
    final newLang = mapLanguageNotifier.value;
    if (newLang != _lang) {
      _lang = newLang;
      setState(() {
        _future = translateText(widget.original, source: widget.source, to: _lang);
      });
    }
  }

  @override
  void dispose() {
    mapLanguageNotifier.removeListener(_onLangChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (_, snap) {
        String text;
        if (snap.connectionState == ConnectionState.waiting) {
          if (widget.showOriginalWhileLoading) {
            // 직전 번역값 있으면 유지, 없으면 원문
            text = _lastRendered ?? widget.original;
          } else {
            text = widget.placeholder ?? '…';
          }
        } else if (snap.hasError) {
          text = _lastRendered ?? widget.original;
        } else {
          text = snap.data ?? widget.original;
          _lastRendered = text;
        }
        return Text(
          text,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textAlign: widget.textAlign,
          strutStyle: widget.strutStyle,
        );
      },
    );
  }
}

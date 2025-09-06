// lib/localizedtext.dart
import 'package:flutter/material.dart';
import 'app_language.dart';
// 전역 translateText(...) 가 들어있는 파일을 import 하세요.
import 'translation_service.dart' show translateText;

class LocalizedText extends StatefulWidget {
  final String original;          // 하드코딩 원문
  final String sourceLang;        // 원문 언어코드 (ex: 'en')
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextAlign? textAlign;
  final StrutStyle? strutStyle;

  const LocalizedText({
    super.key,
    required this.original,
    this.sourceLang = 'en',
    this.style,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.strutStyle,
  });

  @override
  State<LocalizedText> createState() => _LocalizedTextState();
}

class _LocalizedTextState extends State<LocalizedText> {
  String? _translated;
  late MapLanguage _lastLang;

  @override
  void initState() {
    super.initState();
    _lastLang = mapLanguageNotifier.value;
    _translate();
    mapLanguageNotifier.addListener(_onLangChange);
  }

  @override
  void didUpdateWidget(covariant LocalizedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 원문/소스가 바뀌면 다시 번역
    if (oldWidget.original != widget.original ||
        oldWidget.sourceLang != widget.sourceLang) {
      _translate();
    }
  }

  @override
  void dispose() {
    mapLanguageNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (_lastLang != mapLanguageNotifier.value) {
      _lastLang = mapLanguageNotifier.value;
      _translate();
    }
  }

  Future<void> _translate() async {
    // 빈 문자열이면 그대로
    if (widget.original.trim().isEmpty) {
      if (mounted) setState(() => _translated = widget.original);
      return;
    }

    // 전역 translateText(...) 사용 (Papago 호출은 내부에서 처리됨)
    final out = await translateText(
      widget.original,
      source: widget.sourceLang,
      to: mapLanguageNotifier.value,
    );

    if (mounted) setState(() => _translated = out);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translated ?? widget.original,
      style: widget.style,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      strutStyle: widget.strutStyle,
    );
  }
}

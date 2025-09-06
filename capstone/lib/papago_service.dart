import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ⚠️ 테스트/개발용 전용: 앱에 키를 넣으면 빌드물에서 유출됩니다.
/// 배포용은 반드시 서버/Cloud Functions 프록시를 사용하세요.
class PapagoClient {
  PapagoClient({
    required this.clientId,
    required this.clientSecret,
    http.Client? httpClient,
    this.cacheSize = 200,
  }) : _http = httpClient ?? http.Client();

  final String clientId;     // NCP API Key ID
  final String clientSecret; // NCP API Key (Secret)
  final http.Client _http;
  final int cacheSize;

  static const _endpoint =
      'https://papago.apigw.ntruss.com/nmt/v1/translation';

  /// 간단 LRU 캐시
  final _cache = _LruMap<String, String>();
  String _cacheKey(String text, String source, String target) =>
      '$source|$target|$text';

  List<String> _splitByBytes(String s, {int maxBytes = 4500}) {
    final out = <String>[];
    var cur = StringBuffer();
    for (final codeUnit in s.runes) {
      final ch = String.fromCharCode(codeUnit);
      final next = '${cur.toString()}$ch';
      if (utf8.encode(next).length > maxBytes) {
        out.add(cur.toString());
        cur = StringBuffer()..write(ch);
      } else {
        cur.write(ch);
      }
    }
    if (cur.isNotEmpty) out.add(cur.toString());
    return out;
  }

  Future<String> translate({
    required String text,
    required String source, // 'ko', 'en', 'ja', 'zh-CN'
    required String target,
  }) async {
    if (text.trim().isEmpty || source == target) return text;

    final key = _cacheKey(text, source, target);
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final parts = _splitByBytes(text);
    final out = <String>[];

    for (final p in parts) {
      final res = await _http.post(
        Uri.parse(_endpoint),
        headers: {
          'X-NCP-APIGW-API-KEY-ID': clientId,
          'X-NCP-APIGW-API-KEY': clientSecret,
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: {
          'source': source,
          'target': target,
          'text': p,
        },
      );

      if (res.statusCode != 200) {
        // 실패 시 원문 반환(또는 throw)
        if (kDebugMode) {
          // ignore: avoid_print
          print('Papago error: ${res.statusCode} ${res.body}');
        }
        return text;
      }

      final json = jsonDecode(utf8.decode(res.bodyBytes));
      final t = json?['message']?['result']?['translatedText'] as String?;
      out.add(t ?? p);
      // Papago 레이트리밋 여유 주려면 딜레이
      // await Future.delayed(const Duration(milliseconds: 60));
    }

    final joined = out.join();
    _cache.put(key, joined, maxSize: cacheSize);
    return joined;
  }
}

/// 가장 단순한 LRU Map
class _LruMap<K, V> {
  final _map = LinkedHashMap<K, V>();

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final val = _map.remove(key)!;
    _map[key] = val; // 최근 사용으로 뒤로 이동
    return val;
  }

  void put(K key, V value, {required int maxSize}) {
    if (_map.length >= maxSize && !_map.containsKey(key)) {
      _map.remove(_map.keys.first); // 가장 오래된 항목 제거
    }
    _map[key] = value;
  }
}
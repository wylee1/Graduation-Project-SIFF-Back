import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchDisasterMessages() async {
  final serviceKey = 'WX6MKDO0M27K76GF';

  // 오늘 날짜 계산 (YYYYMMDD)
//  final now = DateTime.now();

  // final today =      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  // 어제 날짜 계산 (필요시 조회범위 확장)
  // final yesterday = now.subtract(const Duration(days: 1));
  // final startDate =      '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';

  // URL 생성 (오늘날짜 데이터만)
  final url = Uri.parse('https://www.safetydata.go.kr/V2/api/DSSP-IF-00247'
      '?serviceKey=$serviceKey'
      '&pageNo=1'
      '&numOfRows=1000'
      '&crtDt=20250101'
      '&rgnNm=서울특별시');

  final response = await http.get(url);

  // 디버깅용 로그
  print('응답 status: ${response.statusCode}');
  final decodedString = utf8.decode(response.bodyBytes);
  print('응답 body (decoded): $decodedString');

  // 정상응답일 때만 파싱
  if (response.statusCode == 200) {
    final data = jsonDecode(decodedString);
    final List bodyList = data['body'] ?? [];
    // 파싱 및 맵 변환
    final parsedMessages = bodyList
        .map<Map<String, dynamic>>((item) => {
              'sender': item['RCPTN_RGN_NM'] ?? 'Unknown',
              'time': item['CRT_DT'] ?? '',
              'content': item['MSG_CN'] ?? '',
            })
        .toList();
    // 최신순 정렬(시간 기준으로 내림차순)
    parsedMessages
        .sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
    return parsedMessages;
  } else {
    print('API 오류: ${response.statusCode}');
    return [];
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedDistrict = 'All'; // 현재 선택된 구
  Map<String, int> crimeStats = {};
  Map<String, List<int>> monthlyTrends = {};
  bool isLoading = true;

  final List<String> districts = [
    'All',
    'Gangnam-gu',
    'Gangdong-gu',
    'Gangbuk-gu',
    'Gangseo-gu',
    'Gwanak-gu',
    'Gwangjin-gu',
    'Guro-gu',
    'Geumcheon-gu',
    'Nowon-gu',
    'Dobong-gu',
    'Dongdaemun-gu',
    'Dongjak-gu',
    'Mapo-gu',
    'Seodaemun-gu',
    'Seocho-gu',
    'Seongdong-gu',
    'Seongbuk-gu',
    'Songpa-gu',
    'Yangcheon-gu',
    'Yeongdeungpo-gu',
    'Yongsan-gu',
    'Eunpyeong-gu',
    'Jongno-gu',
    'Jung-gu',
    'Jungnang-gu'
  ];

  final List<String> crimeTypes = [
    'Arson',
    'Assault',
    'Robbery',
    'Murder',
    'Sexual Violence',
    'Drug'
  ];

  final Map<String, Color> crimeColors = {
    'Arson': Colors.orange,
    'Assault': Colors.blue,
    'Robbery': Colors.green,
    'Murder': Colors.red,
    'Sexual Violence': Colors.purple,
    'Drug': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    loadCrimeStatistics();
  }

  Future<void> loadCrimeStatistics() async {
    setState(() => isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('map_marker').get();

      Map<String, int> stats = {};
      Map<String, List<int>> trends = {};

      // 범죄 유형별 통계 초기화
      for (String type in crimeTypes) {
        stats[type] = 0;
        trends[type] = List.filled(12, 0); // 12개월
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final crimeType = data['Crime Type'] ?? '';
        final location = data['location'] ?? '';
        final timeStr = data['Time'] ?? '';

        // 구 필터링 (selectedDistrict가 'All'이 아닌 경우)
        if (selectedDistrict != 'All' && !location.contains(selectedDistrict)) {
          continue;
        }

        // 범죄 유형별 카운트
        if (crimeTypes.contains(crimeType)) {
          stats[crimeType] = (stats[crimeType] ?? 0) + 1;

          // 월별 추세 (시간 데이터가 있는 경우)
          if (timeStr.isNotEmpty) {
            try {
              final month = _extractMonth(timeStr);
              if (month >= 1 && month <= 12) {
                trends[crimeType]![month - 1]++;
              }
            } catch (e) {
              // 시간 파싱 실패 시 무시
            }
          }
        }
      }

      setState(() {
        crimeStats = stats;
        monthlyTrends = trends;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('통계 로딩 실패: $e');
      setState(() => isLoading = false);
    }
  }

  int _extractMonth(String timeStr) {
    // "2024.08.29. PM 11:03"와 같이 .으로 구분된 날짜에서 월 추출
    try {
      final regex = RegExp(r'(\d{4})\.(\d{2})\.(\d{2})');
      final match = regex.firstMatch(timeStr);
      if (match != null) {
        return int.parse(match.group(2)!);
      }
    } catch (e) {}
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crime Statistics Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // SingleChildScrollView로 감싸기
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 구 선택 드롭다운
                  _buildDistrictSelector(),
                  const SizedBox(height: 24),

                  // 범죄 유형별 통계 카드
                  _buildCrimeStatsCards(),
                  const SizedBox(height: 24),

                  // 월간 추세 막대 그래프
                  _buildMonthlyTrendsChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildDistrictSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Select District: ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: DropdownButton<String>(
                value: selectedDistrict,
                isExpanded: true,
                items: districts.map((district) {
                  return DropdownMenuItem(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedDistrict = value);
                    loadCrimeStatistics();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrimeStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crime Incidents by Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.0, // 2.5에서 2.0으로 변경 (박스를 더 높게)
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: crimeTypes.length,
          itemBuilder: (context, index) {
            final type = crimeTypes[index];
            final count = crimeStats[type] ?? 0;
            final color = crimeColors[type] ?? Colors.grey;

            return Card(
              color: color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(8), // 12에서 8로 줄임
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      // Flexible로 감싸기
                      child: Text(
                        type,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 12, // 폰트 크기 명시적으로 설정
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // 최대 2줄로 제한
                        overflow: TextOverflow.ellipsis, // 넘치면 ... 표시
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      // Flexible로 감싸기
                      child: Text(
                        '$count cases',
                        style: const TextStyle(
                          fontSize: 16, // 18에서 16으로 줄임
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Crime Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxMonthlyCount().toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, // 공간 확보
                        interval: 2, // 2개월 간격으로 표시 (Jan, Mar, May...)
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[value.toInt()],
                                style:
                                    const TextStyle(fontSize: 10), // 폰트 크기 줄임
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _getTotalForMonth(index).toDouble(),
                          color: Colors.blue,
                          width: 16,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxMonthlyCount() {
    int max = 0;
    for (int i = 0; i < 12; i++) {
      final total = _getTotalForMonth(i);
      if (total > max) max = total;
    }
    return max + 1;
  }

  int _getTotalForMonth(int monthIndex) {
    int total = 0;
    for (String type in crimeTypes) {
      final trends = monthlyTrends[type];
      if (trends != null && monthIndex < trends.length) {
        total += trends[monthIndex];
      }
    }
    return total;
  }
}

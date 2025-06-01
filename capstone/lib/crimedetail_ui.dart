import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:url_launcher/url_launcher.dart';

class CrimeDetailPage extends StatelessWidget {
  final String crimeType;
  final String occurrenceLocation;
  final String occurrenceTime;
  final String description;
  final double latitude;
  final double longitude;

  const CrimeDetailPage({
    super.key,
    required this.crimeType,
    required this.occurrenceLocation,
    required this.occurrenceTime,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  // 뉴스 링크 데이터 (예시)
  List<Map<String, String>> get newsLinks {
    return [
      {
        'title': 'Local Crime Report - ${crimeType} in ${occurrenceLocation}',
        'url':
            'https://www.yna.co.kr/search?query=${Uri.encodeComponent(crimeType)}',
        'source': 'Yonhap News'
      },
      {
        'title': 'Safety Alert: Recent ${crimeType} Incidents',
        'url':
            'https://news.naver.com/main/search.naver?query=${Uri.encodeComponent(crimeType + ' ' + occurrenceLocation)}',
        'source': 'Naver News'
      },
      {
        'title': 'Crime Prevention Tips for ${crimeType}',
        'url': 'https://www.police.go.kr/main.do',
        'source': 'Korean National Police'
      },
    ];
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crime Information')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                child: NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(latitude, longitude),
                      zoom: 16, // 확대 레벨 (15~18 정도가 상세)
                    ),
                    minZoom: 10,
                    maxZoom: 18,
                    locationButtonEnable: false,
                  ),
                  onMapReady: (controller) async {
                    // 필요하다면 마커 추가도 가능
                    final marker = NMarker(
                      id: 'detail_marker',
                      position: NLatLng(latitude, longitude),
                    );
                    controller.addOverlay(marker);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('Crime Type'),
                subtitle: Text(crimeType),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Occurrence Location'),
                subtitle: Text(occurrenceLocation),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Occurrence Time'),
                subtitle: Text(occurrenceTime),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('💡AI Description'),
                subtitle: Text(description),
              ),
              const SizedBox(height: 24),

              // 뉴스 링크 섹션 추가
              const Text(
                'Related News & Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),

              // 뉴스 링크 리스트
              ...newsLinks
                  .map((news) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.article, color: Colors.orange),
                          title: Text(
                            news['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            news['source']!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _launchURL(news['url']!),
                        ),
                      ))
                  .toList(),

              const SizedBox(height: 16),

              // 추가 안전 정보 카드
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Safety Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Stay aware of your surroundings\n'
                        '• Report suspicious activities to authorities\n'
                        '• Use well-lit and populated routes\n'
                        '• Keep emergency contacts readily available',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localizedtext.dart';

class CrimeDetailPage extends StatelessWidget {
  final String markerId;
  final String crimeType;
  final String occurrenceLocation;
  final String occurrenceTime;
  final String description;
  final double latitude;
  final double longitude;

  const CrimeDetailPage({
    super.key,
    required this.markerId,
    required this.crimeType,
    required this.occurrenceLocation,
    required this.occurrenceTime,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  // Firebase에서 마커 url 읽기
  Future<String?> fetchMarkerNewsUrl(String markerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('map_marker')
        .doc(markerId)
        .get();
    if (doc.exists) {
      return doc.data()?['url'] as String?;
    }
    return null;
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
      appBar: AppBar(
        title: const LocalizedText(
          original: 'Crime Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
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
                      zoom: 16,
                    ),
                    minZoom: 10,
                    maxZoom: 18,
                    locationButtonEnable: false,
                  ),
                  onMapReady: (controller) async {
                    final marker = NMarker(
                      id: 'detail_marker',
                      position: NLatLng(latitude, longitude),
                    );
                    controller.addOverlay(marker);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const LocalizedText(
                original: 'Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.warning),
                title: const LocalizedText(original: 'Crime Type'),
                subtitle: LocalizedText(original: crimeType),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const LocalizedText(original: 'Occurrence Location'),
                subtitle: LocalizedText(original: occurrenceLocation),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const LocalizedText(original: 'Occurrence Time'),
                subtitle: LocalizedText(original: occurrenceTime),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const LocalizedText(original: '💡AI Description'),
                subtitle: LocalizedText(original: description),
              ),
              const SizedBox(height: 24),
              const LocalizedText(
                original: 'Related News & Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),

              // 뉴스 링크 영역을 Firebase 데이터로!
              FutureBuilder<String?>(
                future: fetchMarkerNewsUrl(markerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    return const Text(
                      '관련 뉴스가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  final newsUrl = snapshot.data!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.article, color: Colors.orange),
                      title: const LocalizedText(
                        original: '해당 사건 관련 뉴스 바로가기',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: LocalizedText(
                        original: newsUrl,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 20),
                      onTap: () => _launchURL(newsUrl),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 안전 정보
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
                          LocalizedText(
                            original: 'Safety Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const LocalizedText(
                        original: '• Stay aware of your surroundings\n'
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

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

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
                title: const Text('Description'),
                subtitle: Text(description),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

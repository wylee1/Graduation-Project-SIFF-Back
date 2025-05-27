import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'crimedetail_ui.dart';

Future<void> Logout() async {
  final googleSignIn = GoogleSignIn();
  try {
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  } catch (error) {
    print("logout failed $error");
  }
}

Future<bool> CheckUID() async {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid == "2jMlIFBtRDN6CrHyXM0rmiyLOiY2";
}

class HomeMapPage extends StatefulWidget {
  final List<String> selectedFilters;
  final NLatLng? initialCameraPosition; // 1. 추가
  final ValueChanged<NLatLng>? onCameraIdle; // 2. 추가

  const HomeMapPage({
    super.key,
    this.selectedFilters = const [],
    this.initialCameraPosition,
    this.onCameraIdle,
  });

  @override
  State<HomeMapPage> createState() => HomeMapPageState();
}

class HomeMapPageState extends State<HomeMapPage> {
  NaverMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NaverMap(
        options: const NaverMapViewOptions(
          indoorEnable: true,
          locationButtonEnable: true, // 반드시 true로!
          consumeSymbolTapEvents: false,
        ),
        onCameraIdle: () async {
          if (mapController != null) {
            final cameraPosition = await mapController!.getCameraPosition();
            widget.onCameraIdle?.call(cameraPosition.target); // 3. 부모에 위치 전달
          }
        },
        onMapReady: (controller) {
          mapController = controller;
          if (widget.initialCameraPosition != null) {
            mapController!.updateCamera(
              NCameraUpdate.scrollAndZoomTo(
                target: widget.initialCameraPosition!,
                zoom: 15,
              ),
            );
          }
          loadMarkers();
        },
      ),
    );
  }

  // 부모 위젯에서 필터가 변경될 때 호출할 수 있도록 함수 제공
  void updateMarkers() {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    if (mapController == null) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('map_marker').get();

      Set<NMarker> markers = {};
      mapController?.clearOverlays();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final loc = data['위치'] as Map<String, dynamic>? ?? {};
        final lat = loc['위도'] ?? 0.0;
        final lng = loc['경도'] ?? 0.0;
        final Type = data['Crime Type'] ?? '유형없음';
        if (widget.selectedFilters.isNotEmpty &&
            !widget.selectedFilters
                .map((e) => e.toLowerCase())
                .contains(Type.toString().toLowerCase())) {
          continue;
        }
        final name = data['name'] ?? '이름없음'; // 최상위에서 읽기
        final Des = data['Description'] ?? '설명없음';
        final OCTime = data['Time'] ?? '시간없음';

        print('Firestore name: $name'); // 값 확인

        final crimeType = data['crimeType'] ?? Type;
        final occurrenceLocation = data['occurrenceLocation'] ?? name;
        final occurrenceTime = data['occurrenceTime'] ?? OCTime;
        final description = data['description'] ?? Des;

        final marker = NMarker(
          id: doc.id,
          position: NLatLng(lat, lng),
        );

        marker.setOnTapListener((NMarker marker) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrimeDetailPage(
                crimeType: crimeType,
                occurrenceLocation: occurrenceLocation,
                occurrenceTime: occurrenceTime,
                description: description,
                latitude: lat,
                longitude: lng,
              ),
            ),
          );
        });

        markers.add(marker);
      }

      // 모든 마커를 한 번에 지도에 추가
      mapController?.addOverlayAll(markers);
    } catch (e) {
      debugPrint("마커 로딩 실패: $e");
    }
  }
}

Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    status = await Permission.location.request();
    if (!status.isGranted) {
      debugPrint("위치 권한이 거부되었습니다.");
    }
  }
}

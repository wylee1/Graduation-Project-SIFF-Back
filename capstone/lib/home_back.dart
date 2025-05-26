import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  late NaverMapController mapController;

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NaverMap(
        options: const NaverMapViewOptions(
          indoorEnable: true,
          locationButtonEnable: true,
          consumeSymbolTapEvents: false,
        ),
        onMapReady: (controller) {
          mapController = controller;
          loadMarkers();
        },
      ),
    );
  }

  Future<void> loadMarkers() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('map_marker')
        .get();

    Set<NMarker> markers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('위치')) continue;

      final loc = data['위치'];
      final lat = loc['위도'];
      final lng = loc['경도'];
      final name = loc['이름'];

      final marker = NMarker(
        id: doc.id,
        position: NLatLng(lat, lng),
      );

      // 마커 클릭 시 InfoWindow에 이름 표시
      marker.setOnTapListener((NMarker marker) {
        final infoWindow = NInfoWindow.onMarker(
          id: marker.info.id,
          text: name, // Firestore에서 읽은 이름
        );
        marker.openInfoWindow(infoWindow);
      });

      markers.add(marker);
    }

    // 모든 마커를 한 번에 지도에 추가
    mapController.addOverlayAll(markers);

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
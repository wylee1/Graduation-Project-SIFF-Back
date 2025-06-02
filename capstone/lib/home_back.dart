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
  Map<String, NOverlayImage> markerIcons = {};
  bool isIconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    try {
      // 검색 결과에 따라 initState에서 아이콘 미리 로딩
      final iconPaths = {
        'murder': 'assets/murder.png',
        'arson': 'assets/arson.png',
        'assault': 'assets/assault.png',
        'robbery': 'assets/robbery.png',
        'sexual violence': 'assets/sexual_violence.png',
        'drug': 'assets/drug.png',
      };

      for (String crimeType in iconPaths.keys) {
        try {
          markerIcons[crimeType] =
              await NOverlayImage.fromAssetImage(iconPaths[crimeType]!);
          debugPrint("$crimeType 마커 아이콘 로딩 성공");
        } catch (e) {
          debugPrint("$crimeType 마커 아이콘 로딩 실패: $e");
        }
      }

      setState(() {
        isIconsLoaded = true;
      });

      // 아이콘 로딩 완료 후 마커 재로딩
      if (mapController != null) {
        loadMarkers();
      }
    } catch (e) {
      debugPrint("마커 아이콘 로딩 실패: $e");
      setState(() {
        isIconsLoaded = true;
      });
    }
  }

  NOverlayImage? getMarkerIcon(String crimeType) {
    return markerIcons[crimeType.toLowerCase()];
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
        onCameraIdle: () async {
          if (mapController != null) {
            final cameraPosition = await mapController!.getCameraPosition();
            widget.onCameraIdle?.call(cameraPosition.target);
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
          // 아이콘이 로딩되었으면 마커 로딩
          if (isIconsLoaded) {
            loadMarkers();
          }
        },
      ),
    );
  }

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
        final latRaw = data['위도'] ?? '0.0';
        final lngRaw = data['경도'] ?? '0.0';

        final lat = double.tryParse(latRaw.toString()) ?? 0.0;
        final lng = double.tryParse(lngRaw.toString()) ?? 0.0;
        final Type = data['Crime Type'] ?? '유형없음';

        if (widget.selectedFilters.isNotEmpty &&
            !widget.selectedFilters
                .map((e) => e.toLowerCase())
                .contains(Type.toString().toLowerCase())) {
          continue;
        }

        final name = data['name'] ?? '이름없음';
        final Des = data['Description'] ?? '설명없음';
        final OCTime = data['Time'] ?? '시간없음';

        print('Firestore name: $name');

        final crimeType = data['crimeType'] ?? Type;
        final occurrenceLocation = data['occurrenceLocation'] ?? name;
        final occurrenceTime = data['occurrenceTime'] ?? OCTime;
        final description = data['description'] ?? Des;

        // 커스텀 아이콘 적용
        final customIcon = getMarkerIcon(Type.toString());

        final marker = NMarker(
          id: doc.id,
          position: NLatLng(lat, lng),
          icon: customIcon, // 커스텀 아이콘 사용 (null이면 기본 마커)
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

      mapController?.addOverlayAll(markers);
      debugPrint("마커 ${markers.length}개 로딩 완료");
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

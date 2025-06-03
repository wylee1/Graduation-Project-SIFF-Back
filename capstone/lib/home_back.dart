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

class MarkerData {
  final String id;
  final double lat;
  final double lng;
  final String crimeType;
  final String name;
  final String description;
  final String time;

  MarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.crimeType,
    required this.name,
    required this.description,
    required this.time,
  });
}

class HomeMapPageState extends State<HomeMapPage> {
  NaverMapController? mapController;
  Map<String, NOverlayImage> markerIcons = {};
  bool isIconsLoaded = false;
  Map<String, List<MarkerData>> markerGroups = {};
  String latLngKey(double lat, double lng) =>
      "${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}";
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
          await FirebaseFirestore.instance.collection('test').get();

      Set<NMarker> markers = {};
      markerGroups.clear(); // 기존 그룹 초기화
      mapController?.clearOverlays();

      // 1단계: 모든 마커 데이터 수집 및 그룹화
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

        final crimeType = data['crimeType'] ?? Type;
        final occurrenceLocation = data['occurrenceLocation'] ?? name;
        final occurrenceTime = data['occurrenceTime'] ?? OCTime;
        final description = data['description'] ?? Des;

        // ✅ 마커 데이터 생성
        final markerData = MarkerData(
          id: doc.id,
          lat: lat,
          lng: lng,
          crimeType: crimeType,
          name: occurrenceLocation,
          description: description,
          time: occurrenceTime,
        );

        // 2단계: 그룹화 (클릭 시 사용)
        final key = latLngKey(lat, lng);
        markerGroups.putIfAbsent(key, () => []);

        // 중복 체크 (동일 ID가 없을 때만 추가)
        if (!markerGroups[key]!.any((existing) => existing.id == doc.id)) {
          markerGroups[key]!.add(markerData);
        }

        // 3단계: 모든 마커 개별 생성
        final customIcon = getMarkerIcon(crimeType);
        final marker = NMarker(
          id: doc.id, // 문서 ID를 고유 식별자로 사용
          position: NLatLng(lat, lng),
          icon: customIcon,
        );

        // 마커 클릭 리스너 (그룹 데이터 사용)
        marker.setOnTapListener((NMarker marker) {
          final key =
              latLngKey(marker.position.latitude, marker.position.longitude);
          final relatedMarkers = markerGroups[key] ?? [];

          if (relatedMarkers.length == 1) {
            // 마커가 하나만 있으면 바로 상세 페이지로 이동
            final data = relatedMarkers.first;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrimeDetailPage(
                  crimeType: data.crimeType,
                  occurrenceLocation: data.name,
                  occurrenceTime: data.time,
                  description: data.description,
                  latitude: data.lat,
                  longitude: data.lng,
                ),
              ),
            );
          } else {
            // 여러 개면 리스트(BottomSheet) 먼저 보여주기
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                color: Colors.white,
                child: ListView(
                  shrinkWrap: true,
                  children: relatedMarkers.map((data) {
                    return ListTile(
                      title: Text(data.crimeType),
                      subtitle: Text("${data.name} / ${data.time}"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrimeDetailPage(
                              crimeType: data.crimeType,
                              occurrenceLocation: data.name,
                              occurrenceTime: data.time,
                              description: data.description,
                              latitude: data.lat,
                              longitude: data.lng,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          }
        });

        markers.add(marker);
      }

      mapController?.addOverlayAll(markers);
      debugPrint("총 마커 ${markers.length}개 표시, 그룹 수: ${markerGroups.length}");
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

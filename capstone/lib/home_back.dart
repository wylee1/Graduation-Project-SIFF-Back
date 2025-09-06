import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'crimedetail_ui.dart';
import 'app_language.dart';
import 'translation_service.dart';

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

  // 같은 좌표의 마커들을 묶어서 보관
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
      body: ValueListenableBuilder<MapLanguage>(
        valueListenable: mapLanguageNotifier,
        builder: (context, lang, _) {
          final nLocale = naverLocaleFrom(lang);
          final naverOptions = (nLocale == null)
              ? const NaverMapViewOptions(
                  indoorEnable: true,
                  locationButtonEnable: true,
                  consumeSymbolTapEvents: false,
                )
              : NaverMapViewOptions(
                  indoorEnable: true,
                  locationButtonEnable: true,
                  consumeSymbolTapEvents: false,
                  locale: nLocale,
                );
          return NaverMap(
            key: ValueKey('navermap-${lang.name}'),
            options: naverOptions,
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

              if (isIconsLoaded) {
                loadMarkers();
              }
            },
          );
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
      markerGroups.clear();
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

        final crimeType = data['crimeType'] ?? Type;
        final occurrenceLocation = data['occurrenceLocation'] ?? name;
        final occurrenceTime = data['occurrenceTime'] ?? OCTime;
        final description = data['description'] ?? Des;

        final markerData = MarkerData(
          id: doc.id,
          lat: lat,
          lng: lng,
          crimeType: crimeType,
          name: occurrenceLocation,
          description: description,
          time: occurrenceTime,
        );

        final key = latLngKey(lat, lng);
        markerGroups.putIfAbsent(key, () => []);
        if (!markerGroups[key]!.any((existing) => existing.id == doc.id)) {
          markerGroups[key]!.add(markerData);
        }

        final customIcon = getMarkerIcon(crimeType);
        final marker = NMarker(
          id: doc.id,
          position: NLatLng(lat, lng),
          icon: customIcon,
        );

        // 👉 별도 핸들러로 분리 (번역 → 시트 출력)
        marker.setOnTapListener((NMarker m) {
          _handleMarkerTap(m);
        });

        markers.add(marker);
      }

      mapController?.addOverlayAll(markers);
      debugPrint("총 마커 ${markers.length}개 표시, 그룹 수: ${markerGroups.length}");
    } catch (e) {
      debugPrint("마커 로딩 실패: $e");
    }
  }

  // ====== 여기서부터: 겹친 마커 번역 + 시트 출력 ======
  Future<void> _handleMarkerTap(NMarker marker) async {
    final key = latLngKey(marker.position.latitude, marker.position.longitude);
    final related = markerGroups[key] ?? [];

    if (related.isEmpty) return;

    if (related.length == 1) {
      final d = related.first;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CrimeDetailPage(
            crimeType: d.crimeType,
            occurrenceLocation: d.name,
            occurrenceTime: d.time,
            description: d.description,
            latitude: d.lat,
            longitude: d.lng,
          ),
        ),
      );
      return;
    }

    // 여러 개면 번역 후 시트로 표시
    await _showOverlappedMarkersSheetTranslated(related);
  }

  Future<void> _showOverlappedMarkersSheetTranslated(List<MarkerData> items) async {
    // 1) 원문 배열 만들기 (제목: crimeType, 부제목: description(or name) + time)
    final titles = <String>[];
    final subs   = <String>[];
    for (final d in items) {
      titles.add(d.crimeType);
      final main = (d.description.isNotEmpty ? d.description : d.name);
      subs.add('$main / ${d.time}');
    }

    // 2) 한 번의 호출로 모두 번역 (성능/요금 절약)
    final outs = await translateMany(
      texts: [...titles, ...subs],
      source: 'auto',
      to: mapLanguageNotifier.value,
    );
    final tTitles = outs.sublist(0, titles.length);
    final tSubs   = outs.sublist(titles.length);

    if (!mounted) return;

    // 3) 번역된 문자열로 바텀시트 출력
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final d = items[i];
          return ListTile(
            title: Text(
              tTitles[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              tSubs[i],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CrimeDetailPage(
                    crimeType: d.crimeType,
                    occurrenceLocation: d.name,
                    occurrenceTime: d.time,
                    description: d.description,
                    latitude: d.lat,
                    longitude: d.lng,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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

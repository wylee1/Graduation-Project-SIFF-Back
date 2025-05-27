import 'package:flutter/material.dart';
import 'home_back.dart'; // HomeMapPage import
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  NLatLng? lastCameraPosition;
  List<String> selectedFilters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지도 테스트')),
      body: HomeMapPage(
        selectedFilters: selectedFilters,
        initialCameraPosition: lastCameraPosition,
        onCameraIdle: (pos) {
          lastCameraPosition = pos;
        },
      ),
      // (필터 UI 등 필요시 추가)
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'home_back.dart';
import 'login_ui.dart'; // LoginScreen을 사용하려면 import가 필요합니다.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화 (권장)z
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NaverMapSdk.instance.initialize(
    clientId: '1bgj4skngh', 
  );
  await requestLocationPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // LoginScreen을 정상적으로 인식할 수 있음
    );
  }
}

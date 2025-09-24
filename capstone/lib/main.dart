import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'home_back.dart';
import 'login_ui.dart'; // LoginScreen을 사용하려면 import가 필요합니다.z
import 'app_language.dart';
import 'translation_service.dart';
import 'chat_bot_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화 (권장)z
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NaverMapSdk.instance.initialize(
    clientId: '1bgj4skngh'  );
  await requestLocationPermission();
  await initSavedMapLanguage();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MapLanguage>(
      valueListenable: mapLanguageNotifier,
      builder: (context, lang, _) {
        final appLocale = flutterLocaleFrom(lang); // null이면 시스템 로케일
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: appLocale, // 원치 않으면 이 줄 삭제
          home: const LoginScreen(),
          routes: {
            '/chat': (_) => const ChatBotScreen(),
          },
        );
      },
    );
  }
}
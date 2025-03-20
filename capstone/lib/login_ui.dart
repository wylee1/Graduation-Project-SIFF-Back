import 'package:flutter/material.dart';
import 'loginpasstest_ui.dart';
import 'login_back.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬 유지
            children: [
              // 자물쇠 아이콘을 중앙 정렬
              Align(
                alignment: Alignment.center,
                child: Image.asset("assets/SIFF_logo.png",
                    width: 200, height: 200, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),

              // "Login" 텍스트와 아이콘을 나란히 배치 (아이콘 변경)
              const Row(
                mainAxisSize: MainAxisSize.min, // 내용 크기에 맞게 조절
                children: [
                  Icon(Icons.login, size: 24, color: Colors.black), // 문 모양 아이콘
                  SizedBox(width: 8), // 아이콘과 텍스트 간격
                  Text(
                    "Login",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    debugPrint("Google Account Login & Sign up");

                    try {
                      await signInWithGoogle();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPassTestPage()),
                      );
                    } catch (e) {
                      debugPrint("로그인 실패: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // 버튼 내 요소 중앙 정렬
                    children: [
                      Image.asset("assets/google.png",
                          width: 24, height: 24), // 구글 로고
                      const SizedBox(width: 10), // 로고와 텍스트 간격
                      const Text("Google Account Login & Sign up"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

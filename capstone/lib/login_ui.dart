import 'package:flutter/material.dart';
import 'loginpasstest_ui.dart';
import 'login_back.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key}); // const 생성자로 변경

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "로그인",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // 구글 로그인 기능 대체
                    debugPrint("구글 계정으로 로그인 버튼 클릭");

                    try {
                      // 구글 로그인 시도
                      await signInWithGoogle();

                      // 로그인 성공 후 LoginPassTestPage로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPassTestPage()),
                      );
                    } catch (e) {
                      // 로그인 실패 시 에러 출력
                      debugPrint("로그인 실패: $e");
                    }
                  },
                  child: const Text("Google 계정으로 로그인"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // 회원가입 페이지로 이동
                  debugPrint("회원가입 페이지로 이동");
                },
                child: const Text(
                  "아직 계정이 없으신가요? 회원가입",
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

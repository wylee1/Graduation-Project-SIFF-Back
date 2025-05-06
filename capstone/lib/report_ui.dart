import 'package:flutter/material.dart';
import 'login_ui.dart'; // 로그아웃 기능을 위해 import
import 'test_ui.dart';
import 'test1_ui.dart';
import 'community_ui.dart';
import 'home_ui.dart';

class ReportUI extends StatefulWidget {
  const ReportUI({Key? key}) : super(key: key);

  @override
  _ReportUIState createState() => _ReportUIState();
}

class _ReportUIState extends State<ReportUI> {
  // 하단 네비게이션 바 상태
  int _selectedIndex = 2; // COMMUNITY 탭 선택 상태로 시작

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Create New Incident Report",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Incident Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField("Crime Type:"),
                  const SizedBox(height: 12),
                  _buildTextField("Occurrence Date:"),
                  const SizedBox(height: 12),
                  _buildTextField("Occurrence Time:"),
                  const SizedBox(height: 12),
                  _buildTextField("Brief Description:"),
                  const SizedBox(height: 12),
                  _buildTextField("Brief Address:"),
                  const SizedBox(height: 20),

                  // 사진 업로드 영역
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Photo Upload Area",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.grey),
                            SizedBox(width: 4),
                            Icon(Icons.circle, size: 8, color: Colors.grey),
                            SizedBox(width: 4),
                            Icon(Icons.circle, size: 8, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 위치 정보 영역
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.grey[200],
                      child: Stack(
                        children: [
                          // 지도 그리드 패턴 표현
                          CustomPaint(
                            size: const Size(double.infinity, 150),
                            painter: GridPainter(),
                          ),
                          // 마커 아이콘
                          const Center(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                          // 위치 정보 텍스트
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: const Center(
                              child: Text(
                                "Location Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 제출 버튼
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        "Sumit Incident Report",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// CheckUID와 Logout 함수 추가 (MainScreen에서 사용하는 함수)
Future<int> CheckUID() async {
  // 여기에 실제 사용자 권한 확인 로직 구현
  // 임시로 1을 반환하도록 설정
  await Future.delayed(Duration(milliseconds: 500)); // 비동기 동작 시뮬레이션
  return 1;
}

Future<void> Logout() async {
  // 로그아웃 로직 구현
  await Future.delayed(Duration(milliseconds: 500)); // 비동기 동작 시뮬레이션
  print("Logged out successfully");
}

// 지도 그리드 패턴을 그리기 위한 CustomPainter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    // 대각선 그리드 그리기
    for (double i = -size.height * 2; i <= size.width * 2; i += 40) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
      canvas.drawLine(
          Offset(i, size.height), Offset(i + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

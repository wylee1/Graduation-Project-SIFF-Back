import 'package:flutter/material.dart';
import 'login_ui.dart';
import 'home_back.dart';
import 'test_ui.dart';
import 'test1_ui.dart';
import 'community_ui.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 기본 홈 화면

  // 각 아이템을 눌렀을 때 표시할 화면
  final List<Widget> _pages = [
    const Center(
        child: Text('Message Page', style: TextStyle(fontSize: 24))), // 메시지 페이지
    const HomeScreen(), // 홈 화면 (지도 UI 포함)
    const CommunityScreen(), // 커뮤니티 화면
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white30,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () async {
            debugPrint("press");
            try {
              if (await CheckUID() == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestScreen1()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestScreen()),
                );
              }
            } catch (e) {
              print("error $e");
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              try {
                await Logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (error) {
                print("logout failed $error");
              }
            },
          ),
        ],
      ),

      // ✅ 선택된 페이지를 표시
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'MESSAGE'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'COMMUNITY'),
        ],
      ),
    );
  }
}

// ✅ HomeScreen: 지도 UI 유지
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          child: const Center(
            child: Text(
              '지도 영역',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 필터 버튼
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {}, // 필터 기능 추가 가능
            child: const Icon(Icons.filter_list, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

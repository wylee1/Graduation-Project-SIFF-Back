import 'package:flutter/material.dart';
import 'login_ui.dart';
import 'home_back.dart';
import 'test_ui.dart';
import 'test1_ui.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // BottomNavigationBar의 선택된 아이템 인덱스

  // 각 아이템을 눌렀을 때 표시할 화면
  final List<Widget> _pages = [
    const Center(child: Text('Message Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Community Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Community Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 설정 (상단 네비게이션 바)
      appBar: AppBar(
        title: null, // 텍스트 제거
        backgroundColor: Colors.white30, // AppBar 색상
        leadingWidth: 56, // 여백 제거 -> 0 이여서 반응이 없어서 56으로 바꿨습니다.
        leading: IconButton(
          icon: const Icon(Icons.menu),
          // 관리자 권한 실행 확인 
          onPressed: () async {
            debugPrint("press");
            try{
              if(await CheckUID() == 1){
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TestScreen1()),
                      );
              }else {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TestScreen()),
                      );
              }
            } catch(e){
              print("error $e");
            }
            // 햄버거 메뉴 클릭 시 수행할 액션 추가
          },
        ),
        actions: [
          // 서치 창 (TextField) 길이 조절
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              width: 250, // 서치 창 너비를 늘림
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0), // 둥근 정도 조정
                    borderSide: BorderSide.none, // 기본 테두리 제거
                  ),
                  filled: true, // 배경색 적용을 위해 필요
                  fillColor: Colors.grey[200], // 배경색 지정 (선택 사항)
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0), // 내부 패딩 조정
                ),
              ),
            ),
          ),
          // 프로필 아이콘 (아이콘 버튼)
          IconButton(
            icon: const Icon(Icons.person),
            // 프로필 클릭 시 위에까지 로그아웃 구현(임시) 버튼 생기면 다른곳으로 이동동
            onPressed: () async {
              try {
                await Logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (error) {
                print("logout failed $error");
              }
              // 프로필 클릭 시 수행할 액션 추가
            },
          ),
        ],
      ),

      // Body 부분 (선택된 페이지를 표시)
      body: _pages[_selectedIndex],

      // BottomNavigationBar 설정 (하단 네비게이션 바)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // 아이템 탭 시 호출되는 함수
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'MESSAGE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'COMMUNITY',
          ),
        ],
      ),
    );
  }
}

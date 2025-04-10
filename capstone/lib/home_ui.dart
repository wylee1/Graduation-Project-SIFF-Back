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
  // 하단 네비게이션 바 상태
  int _selectedIndex = 1;

  // 필터 확장 상태 제어
  bool _isFilterExpanded = false;

  // 아이콘과 함께하는 필터 유형 (색상 추가)
  final List<Map<String, dynamic>> _filterTypes = [
    {'name': '방화', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'name': '폭행', 'icon': Icons.dangerous, 'color': Colors.blue},
    {'name': '강도', 'icon': Icons.monetization_on, 'color': Colors.green},
    {'name': '살인', 'icon': Icons.bloodtype, 'color': Colors.red},
    {'name': '성폭력', 'icon': Icons.warning, 'color': Colors.purple},
    {'name': '마약', 'icon': Icons.medication, 'color': Colors.teal},
  ];

  // 필터 선택 상태
  List<bool> _filterSelected = [];

  // 각 아이템을 눌렀을 때 표시할 화면
  final List<Widget> _pages = [
    const Center(child: Text('Message Page', style: TextStyle(fontSize: 24))),
    const HomeMapPage(),
    const Center(child: Text('Community Page', style: TextStyle(fontSize: 24))),
  ];

  @override
  void initState() {
    super.initState();
    // 필터 선택 상태를 필터 유형 수에 맞게 초기화
    _filterSelected = List.generate(_filterTypes.length, (index) => false);
  }

  void _toggleFilterExpansion() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  void _onFilterSelected(int index) {
    setState(() {
      _filterSelected[index] = !_filterSelected[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar (이전과 동일)
      appBar: AppBar(
        title: null, // 텍스트 제거
        backgroundColor: Colors.white30, // AppBar 색상
        leadingWidth: 56, // 여백 제거 -> 0 이여서 반응이 없어서 56으로 바꿨습니다.
        leading: IconButton(
          icon: const Icon(Icons.menu),
          // 관리자 권한 실행 확인
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
            // 햄버거 메뉴 클릭 시 수행할 액션 추가
          },
        ),
        actions: [
          // 검색 및 프로필 아이콘
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ),
          ),
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

      body: Stack(
        children: [
          // 1. 현재 선택된 페이지를 먼저 그립니다 (배경)
          _pages[_selectedIndex],

          // 2. 그 위에 필터 섹션을 오버레이
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // 메인 필터 버튼
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _toggleFilterExpansion,
                  child: Icon(
                    Icons.filter_list,
                    color: Colors.black,
                  ),
                ),

                // 확장된 필터들 (수평 스크롤 가능)
                if (_isFilterExpanded)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_filterTypes.length, (index) {
                          final filterColor =
                              _filterTypes[index]['color'] as Color?;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FilterChip(
                              avatar: Icon(_filterTypes[index]['icon']),
                              label: Text(_filterTypes[index]['name']),
                              selected: _filterSelected[index],
                              onSelected: (_) => _onFilterSelected(index),
                              selectedColor:
                                  _filterSelected[index] && filterColor != null
                                      ? filterColor.withOpacity(0.2)
                                      : null,
                              checkmarkColor: filterColor,
                              backgroundColor: Colors.grey[200],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

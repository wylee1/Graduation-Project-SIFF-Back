import 'package:flutter/material.dart';

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
        title: null,
        backgroundColor: Colors.white30,
        leadingWidth: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
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
            onPressed: () {},
          ),
        ],
      ),

      body: Stack(
        children: [
          // 지도 플레이스홀더
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Text(
                '지도 영역',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 필터 섹션
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
                          // 각 필터의 색상 가져오기
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
                              // 안전한 색상 처리
                              selectedColor:
                                  _filterSelected[index] && filterColor != null
                                      ? filterColor.withOpacity(0.2)
                                      : null,
                              checkmarkColor: filterColor,
                              // 선택되지 않았을 때의 기본 배경색 설정
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

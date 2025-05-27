import 'package:flutter/material.dart';
import 'home_back.dart';
import 'community_ui.dart';
import 'usersetting_ui.dart';
import 'message_ui.dart';
import 'report_ui.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;
  bool _isFilterExpanded = false;
  NLatLng? lastCameraPosition;

  final GlobalKey<HomeMapPageState> _mapKey = GlobalKey<HomeMapPageState>();

  final List<Map<String, dynamic>> _filterTypes = [
    {
      'name': 'Arson',
      'icon': Icons.local_fire_department,
      'color': Colors.orange
    },
    {'name': 'Assault', 'icon': Icons.dangerous, 'color': Colors.blue},
    {'name': 'Robbery', 'icon': Icons.monetization_on, 'color': Colors.green},
    {'name': 'Murder', 'icon': Icons.bloodtype, 'color': Colors.red},
    {'name': 'Sexual Violence', 'icon': Icons.warning, 'color': Colors.purple},
    {'name': 'Drug', 'icon': Icons.medication, 'color': Colors.teal},
  ];
  late List<bool> _filterSelected;
  List<String> selectedFilters = [];

  @override
  void initState() {
    super.initState();
    _filterSelected = List.filled(_filterTypes.length, false);
  }

  void _toggleFilterExpansion() =>
      setState(() => _isFilterExpanded = !_isFilterExpanded);

  // 필터 선택 함수
  void _onFilterSelected(int idx) {
    setState(() {
      _filterSelected[idx] = !_filterSelected[idx];
      selectedFilters = List.generate(_filterTypes.length, (i) {
        if (_filterSelected[i]) return _filterTypes[i]['name'] as String;
        return null;
      }).whereType<String>().toList();
    });
    // HomeMapPage의 마커 갱신
    _mapKey.currentState?.loadMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white30,
        leadingWidth: 56,
        title: SizedBox(
          width: 340,
          height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSettingScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              MessageScreen(),
              HomeMapPage(
                key: _mapKey, // GlobalKey 연결
                selectedFilters: selectedFilters,
                initialCameraPosition: lastCameraPosition,
                onCameraIdle: (pos) {
                  lastCameraPosition = pos;
                },
              ),
              const CommunityScreen(),
            ],
          ),
          if (_selectedIndex == 1)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _toggleFilterExpansion,
                    child: const Icon(Icons.filter_list, color: Colors.black),
                  ),
                  if (_isFilterExpanded)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filterTypes.length, (i) {
                            final f = _filterTypes[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                avatar: Icon(f['icon'] as IconData),
                                label: Text(f['name'] as String),
                                selected: _filterSelected[i],
                                onSelected: (_) => _onFilterSelected(i),
                                selectedColor: _filterSelected[i]
                                    ? (f['color'] as Color).withOpacity(0.2)
                                    : null,
                                checkmarkColor: f['color'] as Color,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'MESSAGE'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'COMMUNITY'),
        ],
        onTap: (idx) => setState(() => _selectedIndex = idx),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 40),
          _drawerItem('• Home', () {
            setState(() => _selectedIndex = 1);
            Navigator.pop(context);
          }, bold: true),
          _drawerItem('• Emergency Disaster Message', () {
            setState(() => _selectedIndex = 0);
            Navigator.pop(context);
          }),
          _drawerItem('• Community', () {
            setState(() => _selectedIndex = 2);
            Navigator.pop(context);
          }),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _drawerItem('· Incident Report', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportUI()),
              );
            }),
          ),
          _drawerItem('• Settings', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSettingScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, VoidCallback onTap, {bool bold = false}) {
    return ListTile(
      title: Text(
        title,
        style:
            TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      onTap: onTap,
    );
  }
}

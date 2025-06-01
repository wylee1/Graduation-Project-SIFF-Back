import 'package:flutter/material.dart';
import 'login_ui.dart';
import 'home_back.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingScreen extends StatefulWidget {
  const UserSettingScreen({super.key});

  @override
  _UserSettingScreenState createState() => _UserSettingScreenState();
}

class _UserSettingScreenState extends State<UserSettingScreen> {
  // 언어 선택 상태 변수
  int _selectedLanguage = 0;
  final List<String> _languages = ['English', 'Korean', 'Chinese', 'Japanese'];

  // 이름, 이메일 입력 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // 편집 모드 상태 변수
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // 저장된 값 불러오기
    _loadEmailFromFirebase(); // 구글 로그인 정보 이메일 가져오기
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = prefs.getString('user_name_${user.uid}') ?? '';
      });
    }
  }

  Future<void> _saveName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await prefs.setString('user_name_${user.uid}', value);
    }
  }

  // ★ Firebase에서 로그인 이메일 불러오기
  void _loadEmailFromFirebase() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _emailController.text = user?.email ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Profile Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 이름 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        _isEditingName
                            ? TextField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  isDense: true,
                                ),
                                onSubmitted: (value) {
                                  setState(() {
                                    _isEditingName = false;
                                  });
                                  _saveName(value); // 저장
                                },
                                onEditingComplete: () {
                                  setState(() {
                                    _isEditingName = false;
                                  });
                                  _saveName(_nameController.text); // 저장
                                },
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text
                                          : 'No name entered',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _isEditingName = true;
                                      });
                                    },
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              // 이메일 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: Icon(Icons.alternate_email, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _emailController.text.isNotEmpty
                              ? _emailController.text
                              : 'No email entered',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              // 언어 설정 섹션
              Text(
                'Language Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_languages.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(_languages[index]),
                        selected: _selectedLanguage == index,
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: _selectedLanguage == index
                              ? Colors.blue
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
                            _selectedLanguage = index;
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 5),
              Text(
                'currently set to ${_languages[_selectedLanguage]}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // 기타 섹션
              Text(
                'Others',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 데이터 동기화 항목
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: Icon(Icons.sync, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Data Synchronization',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              // 앱 정보 항목
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: Icon(Icons.info, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),

              // 로그아웃 버튼
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: Size(150, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    await Logout(); // back 파일의 함수 호출
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(), // 실제 로그인 위젯명으로 교체
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 50), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}

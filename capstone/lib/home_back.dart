import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> Logout() async {
              final GoogleSignIn googleSignIn = GoogleSignIn();
              try {
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                } catch (error) {
                  print("logout failed $error");
              }
            }

Future<int> CheckUID() async{
  final user = FirebaseAuth.instance.currentUser;
  if(user != null){
    final uid = user.uid;
    if(uid == "2jMlIFBtRDN6CrHyXM0rmiyLOiY2"){
    return 1; 
  }
  }
  return 0;
  
}

class HomeMapPage extends StatelessWidget {
  const HomeMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NaverMap(
        options: NaverMapViewOptions(
          indoorEnable: true,
          locationButtonEnable: true,
          consumeSymbolTapEvents: false,
        ),
      ),
    );
  }
}
Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    status = await Permission.location.request();
    if (!status.isGranted) {
      // 권한 거부됨
      debugPrint("위치 권한이 거부되었습니다.");
    }
  }
}
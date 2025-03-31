import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

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
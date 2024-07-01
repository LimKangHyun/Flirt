import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flirter_dev_page.dart';
import 'privacy_policy_page.dart'; // 개인정보 처리방침 페이지 import

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isNotificationsEnabled = true; // 알림 토글 상태 변수

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  // SharedPreferences에서 알림 설정 불러오기
  Future<void> _loadNotificationPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // 알림 설정 저장
  Future<void> _saveNotificationPreference(bool isEnabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', isEnabled);
  }

  void _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      // 로그아웃 후 로그인/회원가입 페이지로 이동하고 이전 페이지 스택을 모두 삭제합니다.
    } catch (e) {
      // 로그아웃 중 오류가 발생한 경우 처리
      print("로그아웃 중 오류가 발생했습니다: $e");
      // 필요한 경우 오류 처리 코드를 추가할 수 있습니다.
    }
  }

  Future<void> _reauthenticateUser(String email, String password) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        print("재인증 중 오류가 발생했습니다: $e");
      }
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
    User? user = _auth.currentUser;
    final navigator = Navigator.of(context);

    if (user != null) {
      // Firestore에서 사용자 데이터 삭제
      try {
        await _firestore.collection('users').doc(user.uid).delete();
      } catch (e) {
        print("Firestore 데이터 삭제 중 오류가 발생했습니다: $e");
        return;
      }

      // Firebase Authentication에서 사용자 삭제
      try {
        await user.delete();
        // Navigator를 안전하게 호출하기 위해 addPostFrameCallback 사용
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          _showReauthenticateDialog(context);
        } else {
          print("사용자 삭제 중 오류가 발생했습니다: $e");
        }
      }
    }
  }

  void _showReauthenticateDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "재인증 필요",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "계정을 삭제하기 위해 다시 로그인 해주세요.",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "이메일"),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "비밀번호"),
                obscureText: true,
              ),
            ],
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "취소",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "확인",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.red,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _reauthenticateUser(
                  emailController.text,
                  passwordController.text,
                );
                _deleteUser(context); // 재인증 후 계정 삭제 시도
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "회원 탈퇴",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            "정말로 탈퇴하시겠습니까?",
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[700],
            ),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "취소",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "탈퇴하기",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAppInfoSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenAppInfo', false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('앱 정보 본 적이 있는 상태가 초기화되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('설정',
            style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.w700)),
      ),
      backgroundColor: Colors.white, // 배경색을 흰색으로 설정
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // 알림 설정 토글
                  setState(() {
                    _isNotificationsEnabled = !_isNotificationsEnabled;
                  });
                  _saveNotificationPreference(_isNotificationsEnabled);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '알림 설정',
                      style: TextStyle(fontSize: 20),
                    ),
                    Switch(
                      activeColor: Colors.white,
                      activeTrackColor: CupertinoColors.activeBlue,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[200],
                      value: _isNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isNotificationsEnabled = value;
                        });
                        _saveNotificationPreference(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[100], // 버튼 텍스트 색상 설정
                  padding: EdgeInsets.all(16), // 버튼 패딩 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 테두리 반경 설정
                  ),
                ),
                onPressed: () {
                  // 개인정보 처리방침 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PrivacyPolicyPage(), // 개인정보 처리방침 페이지
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '개인정보 처리방침',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[100], // 버튼 텍스트 색상 설정
                  padding: EdgeInsets.all(16), // 버튼 패딩 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 테두리 반경 설정
                  ),
                ),
                onPressed: () {
                  // 개인정보 처리방침 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlirterDevPage(), // 개인정보 처리방침 페이지
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Flirt를 만든 사람들',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[100], // 버튼 텍스트 색상 설정
                  padding: EdgeInsets.all(16), // 버튼 패딩 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 테두리 반경 설정
                  ),
                ),
                onPressed: _resetAppInfoSeen,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '앱 정보 초기화',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(
              thickness: 1.sp,
              color: Colors.grey[300],
              indent: 0,
              endIndent: 0,
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[100], // 버튼 텍스트 색상 설정
                  padding: EdgeInsets.all(16), // 버튼 패딩 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 테두리 반경 설정
                  ),
                ),
                onPressed: () => _logout(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '로그아웃',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.logout, size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.grey[100], // 버튼 텍스트 색상 설정
                  padding: EdgeInsets.all(16), // 버튼 패딩 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 테두리 반경 설정
                  ),
                ),
                onPressed: () => _showDeleteAccountDialog(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '탈퇴하기',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

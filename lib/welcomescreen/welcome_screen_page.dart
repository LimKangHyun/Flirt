import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:logintest/auth/auth_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreenPage extends StatelessWidget {
  const WelcomeScreenPage({Key? key}) : super(key: key);

  Future<void> _setAppInfoSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenAppInfo', true);
  }

  @override
  Widget build(BuildContext context) {
    final List<PageViewModel> pages = [
      PageViewModel(
        titleWidget: Container(), // 제목이 필요 없으면 빈 컨테이너로 설정
        bodyWidget: Column(
          children: [
            Image.asset('assets/juicy-lying-man-playing-on-a-gaming-console.png', height: 250.0),
            SizedBox(height: 70),
            Text(
              '\n\n대학 생활 \n혼자만 지내기엔 심심하지 않아?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      PageViewModel(
        titleWidget: Container(), // 제목이 필요 없으면 빈 컨테이너로 설정
        bodyWidget: Column(
          children: [
            Image.asset('assets/juicy-marketing-tools.png', height: 300.0),
            SizedBox(height: 20),
            Text(
              '\n\n나를 밝히지 않고 투표로\n내 마음을 표현 할 수 있어',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      PageViewModel(
        titleWidget: Container(), // 제목이 필요 없으면 빈 컨테이너로 설정
        bodyWidget: Column(
          children: [
            Image.asset('assets/juicy-young-woman-looking-through-a-magnifying-glass.png', height: 300.0),
            SizedBox(height: 20),
            Text(
              '\n\n누가 널 좋아하는지도 \n알려줄게',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      PageViewModel(
        titleWidget: Container(), // 제목이 필요 없으면 빈 컨테이너로 설정
        bodyWidget: Column(
          children: [
            Image.asset('assets/juicy-heart-pierced-by-an-arrow.png', height: 300.0),
            SizedBox(height: 20),
            Text(
              '\n\n이제 너의 마음을 표현해봐',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ];

    return IntroductionScreen(
      pages: pages,
      onDone: () async {
        await _setAppInfoSeen();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      },
      onSkip: () async {
        await _setAppInfoSeen();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("시작하기"),
      globalBackgroundColor: Colors.white, // 배경색을 흰색으로 설정
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeColor: Colors.black,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}

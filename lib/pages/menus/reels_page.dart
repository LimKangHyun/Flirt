import 'dart:math';
import 'dart:ui';
import 'package:cupertino_text_button/cupertino_text_button.dart';
import 'package:flutter/rendering.dart';
import 'package:logintest/components/fancy_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import '../../reels/hot_polls_page.dart';
import '../../reels/polls_upload_page.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelsPage extends StatefulWidget {
  final String? postId; // postId를 받을 수 있도록 수정

  const ReelsPage({Key? key, this.postId}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late PageController _pageController;
  Map<String, int> _selectedButtonIndexMap = {};
  bool _isAppBarVisible = true;
  int initialPageIndex = 0;
  String currentQueryType = "latest";
  String? userMajor;

  Future<void> fetchUserMajor() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          userMajor = userDoc.data()?['major'];
        });
      }
    }
  }

  Future<bool> hasUserVoted(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userVoteDoc = await firestore.collection('user_polls').doc(currentUser.uid).get();
      if (userVoteDoc.exists) {
        final userVotes = userVoteDoc.data() as Map<String, dynamic>;
        return userVotes.containsKey(postId);
      }
    }
    return false;
  }

  Future<void> recordUserVote(String postId, int buttonIndex) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await firestore.collection('user_polls').doc(currentUser.uid).set({postId: true}, SetOptions(merge: true));
      setState(() {
        _selectedButtonIndexMap[postId] = buttonIndex;
      });
    }
  }

  void updateVoteCount(String postId, int buttonIndex) async {
    if (buttonIndex == 1) {
      await firestore.collection('posts').doc(postId).update({
        'vote_1_count': FieldValue.increment(1),
      });
    } else if (buttonIndex == 2) {
      await firestore.collection('posts').doc(postId).update({
        'vote_2_count': FieldValue.increment(1),
      });
    }
  }

  Widget buildPostWidget(BuildContext context, DocumentSnapshot post) {
    final size = MediaQuery.of(context).size;
    final postId = post.id;
    final imageUrl = post['imageUrl'];
    final caption = post['caption'];
    final postTime = post['timestamp'].toDate();
    final major = post['major'];
    final vote_1 = post['vote_1'];
    final vote_2 = post['vote_2'];
    final vote1Count = post['vote_1_count'];
    final vote2Count = post['vote_2_count'];
    final totalVotes = vote1Count + vote2Count;
    final now = DateTime.now();
    final difference = now.difference(postTime);
    String timeAgoMessage = '';

    if (difference.inSeconds < 60) {
      timeAgoMessage = '${difference.inSeconds}초 전';
    } else if (difference.inMinutes < 60) {
      timeAgoMessage = '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      timeAgoMessage = '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      timeAgoMessage = '${difference.inDays}일 전';
    } else {
      int weeks = (difference.inDays / 7).floor();
      timeAgoMessage = '$weeks주일 전';
    }

    return FutureBuilder<bool>(
      future: hasUserVoted(postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.white);
        }
        final hasVoted = snapshot.data!;
        final selectedButtonIndex = _selectedButtonIndexMap[postId] ?? -1;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              SizedBox(
                width: size.width,
                height: size.height,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => Container(color: Colors.white),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              if (_isAppBarVisible)
                Column(
                  children: [
                    const SizedBox(height: 140),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: size.width * 0.8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF2F1F3),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      ' $caption ',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 300),
                                Container(
                                  width: size.width * 0.95,
                                  constraints: BoxConstraints(maxWidth: size.width * 0.95),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 320.sp,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              major + ' 학생',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: hasVoted ? Colors.black : Colors.black,
                                              ),
                                            ),
                                            Text(
                                              timeAgoMessage,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      VoteButton1(
                                        voteText: post['vote_1'],
                                        onPressed: hasVoted ? null : () async {
                                          if (!hasVoted) {
                                            await recordUserVote(postId, 1);
                                            updateVoteCount(postId, 1);
                                          }
                                        },
                                        showPercentIndicator: hasVoted,
                                        vote1Count: vote1Count,
                                        vote2Count: vote2Count,
                                        totalVotes: totalVotes,
                                        vote_1: vote_1,
                                        isSelected: selectedButtonIndex == 1,
                                      ),
                                      const SizedBox(height: 10),
                                      Stack(
                                        children: [
                                          VoteButton2(
                                            voteText: post['vote_2'],
                                            onPressed: hasVoted ? null : () async {
                                              if (!hasVoted) {
                                                await recordUserVote(postId, 2);
                                                updateVoteCount(postId, 2);
                                              }
                                            },
                                            showPercentIndicator: hasVoted,
                                            vote1Count: vote1Count,
                                            vote2Count: vote2Count,
                                            totalVotes: totalVotes,
                                            vote_2: vote_2,
                                            isSelected: selectedButtonIndex == 2,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        width: 320.sp,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$totalVotes명 투표',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black38,
                                              ),
                                            ),
                                            CupertinoButton(
                                              child: const Icon(
                                                Icons.keyboard_control,
                                                color: Colors.black,
                                              ),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  constraints: const BoxConstraints(
                                                    maxHeight: 100,
                                                  ),
                                                  builder: (context) {
                                                    return Container(
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                      ),
                                                      child: ListView(
                                                        children: [
                                                          const Center(
                                                            child: Padding(
                                                              padding: EdgeInsets.all(3.0),
                                                            ),
                                                          ),
                                                          ListTile(
                                                            title: const Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Text(
                                                                  '신고하기',
                                                                  style: TextStyle(
                                                                      color: Colors.red,
                                                                      fontWeight: FontWeight.bold
                                                                  ),
                                                                ),
                                                                Icon(Icons.wb_twilight_rounded,color: Colors.red,)
                                                              ],
                                                            ),
                                                            onTap: () {
                                                              Navigator.of(context).pop();
                                                              showModalBottomSheet(
                                                                context: context,
                                                                constraints: BoxConstraints(
                                                                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                                                                ),
                                                                builder: (context) {
                                                                  return Container(
                                                                    decoration: const BoxDecoration(
                                                                      color: Colors.white,
                                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                                    ),
                                                                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                                                                    child: ListView(
                                                                      children: [
                                                                        const Text(
                                                                          '신고 사유 선택',
                                                                          style: TextStyle(
                                                                            fontSize: 20,
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                                          textAlign: TextAlign.center,
                                                                        ),
                                                                        ListTile(
                                                                          title: const Text('스팸홍보 또는 도배글', textAlign: TextAlign.left,),
                                                                          onTap: () {
                                                                            Navigator.of(context).pop();
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                  title: const Text('신고 완료'),
                                                                                  content: const Text('신고해 주셔서 감사합니다. \n해당 게시물이 검토될 것입니다.'),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      child: const Text('확인'),
                                                                                      onPressed: () {
                                                                                        Navigator.of(context).pop();
                                                                                      },
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                        ListTile(
                                                                          title: const Text('혐오 발언 또는 심벌'),
                                                                          onTap: () {
                                                                            Navigator.of(context).pop();
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                  title: const Text('신고 완료'),
                                                                                  content: const Text('신고해 주셔서 감사합니다. \n해당 게시물이 검토될 것입니다.'),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      child: const Text('확인'),
                                                                                      onPressed: () {
                                                                                        Navigator.of(context).pop();
                                                                                      },
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                        ListTile(
                                                                          title: const Text('음란물 또는 불법정보 포함'),
                                                                          onTap: () {
                                                                            Navigator.of(context).pop();
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                  title: const Text('신고 완료'),
                                                                                  content: const Text('신고해 주셔서 감사합니다. \n해당 게시물이 검토될 것입니다.'),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      child: const Text('확인'),
                                                                                      onPressed: () {
                                                                                        Navigator.of(context).pop();
                                                                                      },
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchUserMajor();

    if (widget.postId != null) {
      // Initialize with the specific post
      firestore.collection('posts').orderBy('timestamp', descending: true).get().then((querySnapshot) {
        final posts = querySnapshot.docs;
        initialPageIndex = posts.indexWhere((post) => post.id == widget.postId);
        if (initialPageIndex != -1) {
          _pageController = PageController(initialPage: initialPageIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isAppBarVisible
          ? AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: PopupMenuButton<int>(
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          color: Colors.white.withOpacity(0.65),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              child: Text(
                "최신순",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            PopupMenuDivider(
              height: 1,
            ),
            PopupMenuItem(
              value: 1,
              child: Text(
                "랜덤",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            PopupMenuDivider(
              height: 1,
            ),
            PopupMenuItem(
              value: 2,
              child: Text(
                "같은 학과",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
          ],
          onSelected: (value) {
            setState(() {
              if (value == 0) {
                currentQueryType = "latest";
              } else if (value == 1) {
                currentQueryType = "random";
              } else if (value == 2) {
                currentQueryType = "major";
              }
            });
          },
          offset: Offset(-10.sp, 30.sp),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('폴스',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 24),
              SizedBox(
                width: 8,
              ), // 아이콘과 텍스트 사이의 간격 조절을 위한 SizedBox 추가
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HotPollsPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications,
              size: 35,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PollsUploadPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.add_box_rounded,
              size: 35,
              color: Colors.white,
            ),
          ),
        ],
      )
          : null,
      body: GestureDetector(
        onLongPressStart: (_) {
          setState(() {
            _isAppBarVisible = false;
          });
        },
        onLongPressEnd: (_) {
          setState(() {
            _isAppBarVisible = true;
          });
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: getPostStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data!.docs;

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return buildPostWidget(context, post);
              },
            );
          },
        ),
      ),
    );
  }

  Stream<QuerySnapshot> getPostStream() {
    if
    (currentQueryType == "major" && userMajor != null) {
      return firestore
          .collection('posts')
          .where('major', isEqualTo: userMajor)
          .snapshots();
    } else if (currentQueryType == "random") {
      return firestore.collection('posts').orderBy(FieldPath.documentId).snapshots();
    } else if (currentQueryType == "latest") {
      return firestore.collection('posts').orderBy('timestamp', descending: true).snapshots();
    }
    return firestore.collection('posts').orderBy('timestamp', descending: true).snapshots();
  }
}

class VoteButton1 extends StatelessWidget {
  final String voteText;
  final Future<void> Function()? onPressed;
  final bool showPercentIndicator;
  final int vote1Count;
  final int vote2Count;
  final int totalVotes;
  final String vote_1;
  final bool isSelected;

  const VoteButton1({
    Key? key,
    required this.voteText,
    required this.onPressed,
    this.showPercentIndicator = true,
    required this.vote1Count,
    required this.vote2Count,
    required this.totalVotes,
    required this.vote_1,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double vote1Percent = totalVotes == 0 ? 0 : vote1Count / totalVotes;

    return Stack(
      alignment: Alignment.center,
      children: [
        FancyButton(
          text: voteText,
          onPressed: () {
            onPressed?.call();
          },
        ),
        if (showPercentIndicator)
          LayoutBuilder(
            builder: (context, constraints) {
              return LinearPercentIndicator(
                animation: true,
                width: constraints.maxWidth,
                lineHeight: 51.sp,
                percent: vote1Percent,
                backgroundColor: const Color(0xffF2F1F3),
                progressColor: isSelected
                    ? const Color(0xff9F9FA5)
                    : const Color(0xffDADADC),
                barRadius: const Radius.circular(10),
                center: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "    $vote_1",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isSelected ? Colors.black : const Color(0xffABABAA),
                      ),
                    ),
                    Text(
                      "$vote1Count표 (${(vote1Percent * 100).round()}%)    ",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isSelected ? Colors.black : const Color(0xffABABAA),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class VoteButton2 extends StatelessWidget {
  final String voteText;
  final Future<void> Function()? onPressed;
  final bool showPercentIndicator;
  final int vote1Count;
  final int vote2Count;
  final int totalVotes;
  final String vote_2;
  final bool isSelected;

  const VoteButton2({
    Key? key,
    required this.voteText,
    required this.onPressed,
    this.showPercentIndicator = true,
    required this.vote1Count,
    required this.vote2Count,
    required this.totalVotes,
    required this.vote_2,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double vote2Percent = totalVotes == 0 ? 0 : vote2Count / totalVotes;

    return Stack(
      alignment: Alignment.center,
      children: [
        FancyButton(
          text: voteText,
          onPressed: onPressed,
        ),
        if (showPercentIndicator)
          LayoutBuilder(
            builder: (context, constraints) {
              return LinearPercentIndicator(
                animation: true,
                width: constraints.maxWidth,
                lineHeight: 51.sp,
                percent: vote2Percent,
                backgroundColor: const Color(0xffF2F1F3),
                progressColor: isSelected
                    ? const Color(0xff9F9FA5)
                    : const Color(0xffDADADC),
                barRadius: const Radius.circular(10),
                center: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "    $vote_2",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isSelected ? Colors.black : const Color(0xffABABAA),
                      ),
                    ),
                    Text(
                      "$vote2Count표 (${(vote2Percent * 100).round()}%)    ",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isSelected ? Colors.black : const Color(0xffABABAA),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
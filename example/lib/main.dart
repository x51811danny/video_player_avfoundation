// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player_avfoundation/video_player.dart';
import 'package:video_player_avfoundation/video_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: MediaPage(),
  ));
}

class MediaPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MediaPageState();
  }
}

class _MediaPageState extends State<MediaPage> {
  // 记录当前设备是否横屏，后续用到
  GlobalKey<MyVideoState> _videoKey = GlobalKey();

  bool _isVideoViewVisible = false;

  String _errorMsg = "";

  @override
  Widget build(BuildContext context) {
    debugPrint('MediaPageState build');
    bool _isFullScreen = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
        appBar: _isFullScreen
            ? PreferredSize(
                child: SizedBox.shrink(),
                preferredSize: Size(0, 0),
              )
            : AppBar(
                title: Text('Media'),
              ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Visibility(
                visible: !_isVideoViewVisible,
                child: Container(
                  width: double.infinity,
                  height: 204,
                  color: Colors.blueGrey.shade400,
                ),
              ),
              Offstage(
                offstage: !_isVideoViewVisible,
                child: MyVideo(
                  key: _videoKey,
                  url: 'https://watchfree.ylkkl.com/stream/moonstudio_en_d/playlist.m3u8',
//                  url:
//                      'https://video-weaver.tpe01.hls.ttvnw.net/v1/playlist/CoQF1BZVq7Evg-hZxqHFonPAiULoeRTKr8LWziGZuP5BSrALx4I7QhZLpEFBAvuhNLBDsAfVkttQJXW32xgENr5U5qoW7s2aMtxHrro6GcVIraxk_FVrVo9Pvlq779TNmOPVJVQFyjW_IjJfLGSEEllmwyjvnpLb-_unb6Kx8ylH6_y0xn9HFQqfkO3r9fcR4fKs-zJr03HBW7D-kwcwTUHQV3rMEIjDmJZqmQy3t4we8u1zhrqZbAdFD_W39g4ZTPiEkD4VlTkLISvqMBJdv-madLWvh_Pf6j7SaQvMN_Um6ySSgfg9k7ETR18VEhlU01tAEADDZUP984DnRs4VJfCfn9X5-BpKO-YD5eZdk6J1aUxn5WZ12o1FqZ-34ounmOc3v1wmaeUCRmVh06fuD9c3YG37GQz5KEf4hk6KhJbSnV8qx1bjq6idHgKXC7AHtifoFQzdACgpam92uD3TylngXUtSwHJKs_9Groa_LUEUlJAihiwM6bwlC8SKHdYkR3sQqzcSOwAwFrlpSuvucuvfcuC-oqE7tLhionWG9U0M1T4-BsNNo71OAhjkG2Jfv2q8KqS1Z85OAmD9NP5QFH1XwmiroTi2xYHpmNilJ3omi5NcccnKogUBN9U0g5xJPLG2G8NyQ5dGrUVWA8ukBDnhYg2IB1YQwFRiZoZ8NqrNrfayhnMDA68n-wImCOHp6AxpyhqCzBhXHLbRUWwevMTct-9YcospEgutyKc_zyrii57M2V649B0HdJScKmhwAfpPrQru42NfZ-LuqcmdqRSvg84h5PCP4H8jFwOHsvKzNLZ5rjo-pru7ZYUVzleroWSYTkD27Y805nsXmiKwXHUDRYJw-zkSECJ3b8hcCiiMgc2JDgTrAP8aDJ7iqr2hz0jIP8XOAQ.m3u8',
                  width: _isFullScreen ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width,
                  height: _isFullScreen ? MediaQuery.of(context).size.height : 204, // 竖屏时容器为16：9
                  onError: (msg) {
                    setState(() {
                      _errorMsg = msg;
                    });
                  },
                ),
              ),
              ElevatedButton(
                child: FlutterLogo(
                  size: 22,
                ),
                onPressed: () {
                  if (_isVideoViewVisible) {
                    _videoKey.currentState?.release();
                    _errorMsg = '';
                  } else {
                    _videoKey.currentState?.init();
                  }

                  setState(() {
                    _isVideoViewVisible = !_isVideoViewVisible;
                  });
                },
              ),
              Text(
                _errorMsg,
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ));
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  const _PlayPauseOverlay({Key? key, required this.controller}) : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: Duration(milliseconds: 50),
          reverseDuration: Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }
}

class _ButterFlyAssetVideo extends StatefulWidget {
  @override
  _ButterFlyAssetVideoState createState() => _ButterFlyAssetVideoState();
}

class _ButterFlyAssetVideoState extends State<_ButterFlyAssetVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/Butterfly-209.mp4');

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          const Text('With assets mp4'),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _PlayPauseOverlay(controller: _controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerVideoAndPopPage extends StatefulWidget {
  @override
  _PlayerVideoAndPopPageState createState() => _PlayerVideoAndPopPageState();
}

class _PlayerVideoAndPopPageState extends State<_PlayerVideoAndPopPage> {
  late VideoPlayerController _videoPlayerController;
  bool startedPlaying = false;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.asset('assets/Butterfly-209.mp4');
    _videoPlayerController.addListener(() {
      if (startedPlaying && !_videoPlayerController.value.isPlaying) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<bool> started() async {
    await _videoPlayerController.initialize();
    await _videoPlayerController.play();
    startedPlaying = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      child: Center(
        child: FutureBuilder<bool>(
          future: started(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.data == true) {
              return AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              );
            } else {
              return const Text('waiting for video to load');
            }
          },
        ),
      ),
    );
  }
}

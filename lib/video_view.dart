import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'video_player.dart';

class MyVideo extends StatefulWidget {
  MyVideo({
    Key? key,
    required this.url, // 当前需要播放的地址
    required this.width, // 播放器尺寸（大于等于视频播放区域）
    required this.height,
    this.onError,
  }) : super(key: key);

  // 视频地址
  final String url;
  // 视频尺寸比例
  final double width;
  final double height;
  final ValueChanged<String>? onError;

  @override
  State<MyVideo> createState() {
    return MyVideoState();
  }
}

class MyVideoState extends State<MyVideo> {
  // 指示video资源是否加载完成，加载完成后会获得总时长和视频长宽比等信息
  bool _videoInit = false;
  // video控件管理器
  VideoPlayerController? _controller;
  VideoPlayerController? _newController;
  // 记录播放控件ui是否显示(进度条，播放按钮，全屏按钮等等)
  Timer? _timer; // 计时器，用于延迟隐藏控件ui
  bool _hidePlayControl = true; // 控制是否隐藏控件ui
  double _playControlOpacity = 0;

  bool _isLoading = true; // 直撥緩衝中
  // 记录是否全屏
  bool get _isFullScreen => MediaQuery.of(context).orientation == Orientation.landscape;
  VideoFormat get videoFormat {
    if (_newController?.formatHint == VideoFormat.other ?? true) {
      debugPrint('${VideoFormat.hls}');
      return VideoFormat.hls;
    }

    debugPrint('${VideoFormat.other}');
    return VideoFormat.other;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(MyVideo oldWidget) {
    if (oldWidget.url != widget.url) {
      init(); // url变化时重新执行一次url加载
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    debugPrint('_MyVideoState dispose');

    if (_controller != null) {
      // 惯例。组件销毁时清理下
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
    }
    super.dispose();
  }

  void release() {
    if (_controller != null) {
      // 惯例。组件销毁时清理下
      _controller?.removeListener(_videoListener);
      setState(() {
        _controller?.pause(); // TODO
        _controller = null;
      });
    }

    if (_timer != null && _timer!.isActive) {
      _timer?.cancel();
    }
  }

  void init() async {
    if (widget.url == null || widget.url == '') return;
    _newController = VideoPlayerController.network(widget.url, formatHint: videoFormat);

    if (_controller != null) {
      // 如果控制器存在，清理掉重新创建
      if (mounted) setState(() {});
      _controller?.removeListener(_videoListener);
    }

    setState(() {
      // 重置组件参数
      _isLoading = true;
      _hidePlayControl = true;
      _videoInit = false;
    });

    print('***init 0');
    _newController?.addListener(_videoListener);
    await _newController?.initialize();
    print('***init 1');

    final VideoPlayerController? oldController = _controller;
    if (mounted) {
      setState(() {
        // 重置组件参数
        print('***init 2');
//        newController.addListener(_videoListener);

        _videoInit = true;
        _controller = _newController;
      });
    }
    await _newController?.play();
    await oldController?.dispose();
    // 加载network的url，也支持本地文件，自行阅览官方api

//        _controller = VideoPlayerController.network(widget.url, formatHint: videoFormat)
//          //    _controller = VideoPlayerController.asset('assets/Butterfly-209.mp4')
//          ..addListener(_videoListener)
//          ..initialize().then((_) {
//            // 加载资源完成时，监听播放进度，并且标记_videoInit=true加载完成
//            setState(() {
//              _videoInit = true;
//              _controller.play();
//            });
//          });
  }

  void _videoListener() {
    bool isLoading = !(_newController?.value?.isInitialized ?? true);
    debugPrint('${_newController?.value ?? 'controller is null'}');

    if (_newController?.value?.hasError ?? true) {
      if (widget.onError != null) {
        if (_newController != null) {
          // 1. HttpDataSourceException : Unable to connect to ...
          // 2. UnrecognizedInputFormatException : None of the available extractors ...
          // 3. InvalidResponseCodeException: Response code: 404
          widget.onError!(_newController!.value?.errorDescription ?? "");
        }
      }

      if (Platform.isAndroid) {
        if (_newController?.value?.errorDescription?.contains('BehindLiveWindowException') ?? false) {
          init();
        } else if (_newController?.value?.errorDescription?.contains('UnrecognizedInputFormatException') ?? false) {
          init();
        }
      }
    }

    setState(() {
      _isLoading = isLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget _controlUI = Offstage(
      // 控制是否隐藏
      offstage: _hidePlayControl,
      child: AnimatedOpacity(
        // 加入透明度动画
        opacity: _playControlOpacity,
        duration: Duration(milliseconds: 300),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _togglePlayControl();
          },
          child: Container(
            // 底部控件的容器
            width: widget.width,
            height: widget.height,
            color: Color.fromRGBO(4, 7, 10, .5),
            child: _videoInit
                ? Stack(
                    alignment: Alignment.center,
                    // 加载完成时才渲染,flex布局
                    children: <Widget>[
                      IconButton(
                        // 播放按钮
                        padding: EdgeInsets.all(8),
                        iconSize: 60,
                        icon: Icon(
                          // 根据控制器动态变化播放图标还是暂停
                          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xffafb8d6),
                        ),
                        onPressed: () async {
                          if (_hidePlayControl) {
                            _togglePlayControl();
                            return;
                          }

                          if (!_controller!.value.isPlaying) {
                            Duration currentPosition = await _controller?.position ?? Duration.zero;
                            if (Platform.isAndroid) {
                              Duration newPosition = _controller!.value.buffered.first.end;

                              if (currentPosition + Duration(seconds: 3) < newPosition) {
                                _controller!.seekTo(newPosition - Duration(seconds: 3));
                              }
                            } else if (Platform.isIOS) {
                              Duration newPosition = _controller!.value.buffered.first.start;
                              if (currentPosition < newPosition) {
                                _controller!.seekTo(newPosition);
                              }
                            }
                          }

                          _startPlayControlTimer(); // 操作控件后，重置延迟隐藏控件的timer

                          setState(() {
                            // 同样的，点击动态播放或者暂停
                            _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                          });
                        },
                      ),
                      Positioned(
                        right: 12,
                        bottom: 20,
                        child: IconButton(
                          // 全屏/横屏按钮
                          padding: EdgeInsets.zero,
                          iconSize: 30,
                          icon: Icon(
                            // 根据当前屏幕方向切换图标
                            _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: const Color(0xffafb8d6),
                          ),
                          onPressed: () {
                            if (_hidePlayControl) return;
                            // 点击切换是否全屏
                            _toggleFullScreen();
                          },
                        ),
                      ),
                    ],
                  )
                : Container(),
          ),
        ),
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: widget.url != null
            ? Stack(
                children: <Widget>[
                  _videoInit
                      ? GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            // 点击显示 控件ui
                            _togglePlayControl();
                          },
                          child: Center(
                            child: Stack(
                              children: <Widget>[
                                AspectRatio(
                                  // 加载url成功时，根据视频比例渲染播放器
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                ),
                                Offstage(
                                    offstage: !_isLoading,
                                    child: Center(
                                      // 没加载完成时显示转圈圈loading
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          // 没加载完成时显示转圈圈loading
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  _controlUI, // 控件ui下半部
                ],
              )
            : Center(
                // 判断是否传入了url，没有的话显示"暂无视频信息"
                child: Text(
                  '暂无视频信息',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }

  void _togglePlayControl() {
    if (_hidePlayControl) {
      // 如果隐藏则显示
      setState(() {
        _hidePlayControl = false;
        _playControlOpacity = 1;
        _startPlayControlTimer(); // 开始计时器，计时后隐藏
      });
    } else {
      // 如果显示就隐藏
      if (_timer != null) _timer!.cancel(); // 有计时器先移除计时器

      setState(() {
        _playControlOpacity = 0;
      });

      Future.delayed(Duration(milliseconds: 300)).whenComplete(() {
        setState(() {
          _hidePlayControl = true; // 延迟300ms(透明度动画结束)后，隐藏
        });
      });
    }
  }

  void _startPlayControlTimer() {
    // 计时器，用法和前端js的大同小异
    if (_timer != null) _timer!.cancel();
    _timer = Timer(Duration(seconds: 3), () {
      // 延迟3s后隐藏
      if (_controller!.value.isPlaying) {
        setState(() {
          _playControlOpacity = 0;
          Future.delayed(Duration(milliseconds: 300)).whenComplete(() {
            _hidePlayControl = true;
          });
        });
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      if (_isFullScreen) {
//        SystemChrome.setEnabledSystemUIOverlays([]);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
//        SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      }
      _startPlayControlTimer(); // 操作完控件开始计时隐藏
    });
  }
}

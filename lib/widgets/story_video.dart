import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class VideoLoader {
  String url;

  File? videoFile;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (this.videoFile != null) {
      this.state = LoadState.success;
      onComplete();
    }

    final fileStream =
        DefaultCacheManager().getFileStream(this.url, headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (this.videoFile == null) {
          this.state = LoadState.success;
          this.videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;

  StoryVideo(this.videoLoader, {this.storyController, Key? key}) : super(key: key ?? UniqueKey());

  static StoryVideo url(String url, {StoryController? controller, Map<String, dynamic>? requestHeaders, Key? key}) {
    return StoryVideo(
      VideoLoader(url, requestHeaders: requestHeaders),
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  VideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();

    widget.storyController?.pause();

    Future.delayed(Duration(milliseconds: 111)).then((value) async {
      await _initializeVideoPlayer();

      if (widget.storyController != null) {
        _streamSubscription = widget.storyController!.playbackNotifier.listen((playbackState) {
          if (playbackState == PlaybackState.pause || playbackState == PlaybackState.next) {
            playerController?.pause();
          } else if (playbackState == PlaybackState.play) {
            playerController?.play();
          }
        });
      }
    });
  }

  Future<void> _initializeVideoPlayer() async {
    playerController = VideoPlayerController.network(widget.videoLoader.url);
    await playerController?.initialize();
    print("video-initiliazed");
    widget.storyController?.play();
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget getContentView() {
    if (playerController != null && playerController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController!.value.aspectRatio,
          child: VideoPlayer(playerController!),
        ),
      );
    } else {
      return const Center(
        child: SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    if (playerController != null && playerController!.value.isPlaying) {
      playerController?.pause();
    }
    playerController?.dispose();
    _streamSubscription?.pause();
    _streamSubscription?.cancel();
    playerController = null;
    super.dispose();
  }
}

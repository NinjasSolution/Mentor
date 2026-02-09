import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/course_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String courseId;
  final String userId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.courseId,
    required this.userId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  final CourseService _courseService = CourseService();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    try {
      await _controller.initialize();
      
      // Fetch last saved position from Firestore
      final progressDoc = await FirebaseFirestore.instance
          .collection('video_progress')
          .doc('${widget.userId}_${widget.courseId}')
          .get();

      if (progressDoc.exists) {
        double savedProgress = (progressDoc.data()?['progress'] ?? 0.0).toDouble();
        if (savedProgress > 0 && savedProgress < 0.99) {
          final Duration totalDuration = _controller.value.duration;
          final Duration seekTo = totalDuration * savedProgress;
          await _controller.seekTo(seekTo);
        }
      }

      setState(() => _isInitialized = true);
      _controller.play();
      
      // Auto-save progress every 10 seconds
      _controller.addListener(_progressListener);
    } catch (e) {
      debugPrint("Video Init Error: $e");
    }
  }

  void _progressListener() {
    if (_controller.value.isInitialized) {
      final double progress = _controller.value.position.inMilliseconds / 
                             _controller.value.duration.inMilliseconds;
      
      // Update Firestore periodically (throttled logic ideally, but simple for now)
      if (_controller.value.position.inSeconds % 5 == 0) {
        _courseService.updateVideoProgress(widget.userId, widget.courseId, progress);
      }
    }
  }

  @override
  void dispose() {
    // Save final progress before leaving
    if (_isInitialized) {
      final double progress = _controller.value.position.inMilliseconds / 
                             _controller.value.duration.inMilliseconds;
      _courseService.updateVideoProgress(widget.userId, widget.courseId, progress);
    }
    _controller.removeListener(_progressListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    _buildControls(),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildControls() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white.withOpacity(0.5),
            size: 80,
          ),
        ),
      ),
    );
  }
}

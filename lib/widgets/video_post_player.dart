import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPostPlayer extends StatefulWidget {
  final String videoUrl;
  
  const VideoPostPlayer({super.key, required this.videoUrl});

  @override
  State<VideoPostPlayer> createState() => _VideoPostPlayerState();
}

class _VideoPostPlayerState extends State<VideoPostPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _controller.setLooping(true); // Sürekli dönsün
          // Otomatik ses kapalı başlasın (kullanıcı isterse açar)
          // _controller.setVolume(0); 
        });
      }
    } catch (e) {
      print("Video Oynatma Hatası: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. HATA VARSA
    if (_hasError) {
      return Container(
        height: 300,
        color: Colors.black,
        child: const Center(child: Icon(Icons.error, color: Colors.white, size: 40)),
      );
    }

    // 2. YÜKLENMEMİŞSE (LOADING)
    if (!_isInitialized) {
      return Container(
        height: 300,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 3. YÜKLENMİŞSE (PLAYER)
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            
            // Oynat/Durdur İkonu (Sadece dururken veya ilk başta görünsün)
            if (!_controller.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              
            // Ses ikonu (Opsiyonel - Sağ altta)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.volume_up, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
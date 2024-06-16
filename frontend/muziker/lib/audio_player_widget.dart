import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isAsset;

  const AudioPlayerWidget({Key? key, required this.url, this.isAsset = false}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadAudio();
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _audioPlayer.stop();
            setState(() {
              position = duration;
              isCompleted = true;
              isPlaying = false;
            });
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    try {
      if (widget.isAsset) {
        final ByteData data = await rootBundle.load(widget.url);
        final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        final file = File('${(await getTemporaryDirectory()).path}/temp.mp3');
        await file.writeAsBytes(bytes);
        await _audioPlayer.setSourceDeviceFile(file.path);
      } else {
        await _audioPlayer.setSourceUrl(widget.url);
      }
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _seekAudio(double value) {
    final newPosition = Duration(seconds: value.toInt());
    _audioPlayer.seek(newPosition);
  }

  void _togglePlayPause() {
    if (isPlaying) {
      _audioPlayer.pause();
    } else {
      if (position >= duration || isCompleted) {
        _audioPlayer.seek(Duration.zero);
        setState(() {
          isCompleted = false;
        });
      }
      _audioPlayer.resume();
    }
  }

  Future<void> _replayAudio() async {
    await _audioPlayer.stop();
    _initializeAudioPlayer();
    await _loadAudio();
    await _audioPlayer.resume();
    if (mounted) {
      setState(() {
        isCompleted = false;
        position = Duration.zero;
        isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          min: 0,
          max: duration.inSeconds.toDouble(),
          value: position.inSeconds.toDouble(),
          onChanged: (value) {
            if (mounted) {
              setState(() {
                position = Duration(seconds: value.toInt());
              });
            }
          },
          onChangeEnd: _seekAudio,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
            ),
            IconButton(
              icon: Icon(Icons.replay),
              onPressed: _replayAudio,
            ),
            Text(
              '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
            Text(' / '),
            Text(
              '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ],
    );
  }
}

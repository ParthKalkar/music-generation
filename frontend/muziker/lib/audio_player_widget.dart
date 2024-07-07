import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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
  String _downloadPath = '';

  // Simulate receiving the mp3 bytes from the chatbot

  Future<Uint8List> _getMp3Bytes() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load mp3 bytes');
      }
    } catch (e) {
      throw Exception('Failed to load mp3 bytes: $e');
    }
  }

  Future<void> _downloadMp3() async {
    try {
      Uint8List mp3Bytes = await _getMp3Bytes();
      String path = await saveMp3File(mp3Bytes, 'output.mp3');
      setState(() {
        _downloadPath = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("File downloaded to $path"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to download file: $e"),
      ));
    }
  }

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

  Future<String> saveMp3File(Uint8List mp3Bytes, String fileName) async {
    // Request storage permissions
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception("Storage permission not granted");
    }

    // Get the directory to save the file
    Directory directory = (await getExternalStorageDirectory())!;
    // Generate a unique file name
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String path = "${directory.path}/output_$timestamp.mp3";
    File file = File(path);
    // Write the file
    await file.writeAsBytes(mp3Bytes);
    return path;
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: _replayAudio,
                ),
  /*              IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed:
                ),*/
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: _downloadMp3,
                ),
              ],
            ),
            Expanded(
              child: Container(), // This pushes the time to the right
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6.0), // Adjust this value to shift left
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  Text(' / '),
                  Text(
                    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ],
        ),


        /*        Row(
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
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _downloadMp3,
            ),
            Text(
              '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
            Text(' / '),
            Text(
              '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
          ],
        ),*/

      ],
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyrics Demo',
      home: MusicPlayerPage(),
    );
  }
}

class MusicPlayerPage extends StatefulWidget {
  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration();
  Duration position = Duration();
  List<xml.XmlElement> lyrics = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    audioPlayer = AudioPlayer();
    audioPlayer.onDurationChanged.listen((Duration dur) {
      setState(() {
        duration = dur;
      });
    });

    audioPlayer.onPositionChanged.listen((Duration pos) {
      setState(() {
        position = pos;
        _scrollToPosition(pos);
      });
    });

    // fetchData khi initState
    fetchData().then((response) async {
      final document = xml.XmlDocument.parse(response.body);
      lyrics = document.findAllElements('param').toList();

      // Sau khi có dữ liệu lyrics, bạn có thể bắt đầu phát nhạc ở đây
      await audioPlayer.play(UrlSource(
          "https://storage.googleapis.com/ikara-storage/tmp/beat.mp3"));
      setState(() {
        audioPlayer.pause();
      });
    }).catchError((error) {
      print('Error fetching data: $error');
    });
  }

  void _scrollToPosition(Duration pos) {
    double currentPositionInSeconds = pos.inMilliseconds / 1000.0;
    double totalHeight = 0.0;
    double listViewHeight = _scrollController.position.viewportDimension;
    double endPositionThreshold = 2.0; // Adjust this threshold as needed

    for (int i = 0; i < lyrics.length; i++) {
      double timeInSeconds = double.parse(
        lyrics[i].findElements('i').first.getAttribute('va') ?? "0",
      );
      if (currentPositionInSeconds < timeInSeconds) {
        break;
      }
      totalHeight += 45; // Height of ListTile, you may adjust based on your UI
    }

    double targetScrollOffset = totalHeight - (listViewHeight / 3);

    if (targetScrollOffset > endPositionThreshold &&
        targetScrollOffset < _scrollController.position.maxScrollExtent) {
      _scrollController.animateTo(
        targetScrollOffset,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player with Lyrics'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                "https://i.pinimg.com/originals/73/f0/2f/73f02fa0f38b187a3eac7add63690a71.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 250,
              child: Align(
                alignment: Alignment.center,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    // final children = lyrics[index]
                    //     .findElements('i')
                    //     .map((e) => utf8.decode(e.text.codeUnits))
                    //     .toList();
                    final listTime = [];
                    final listLyric = [];
                    List<Map<String, String>> combinedList = [];
                    for (final item in lyrics[index].findElements("i")) {
                      listLyric.add(utf8.decode(item.text.codeUnits));
                      listTime.add(
                        item.getAttribute('va') ?? "0",
                      );
                    }
                    for (int i = 0; i < listLyric.length; i++) {
                      combinedList.add({
                        'lyric': listLyric[i],
                        'time': listTime.length > i ? listTime[i] : "0",
                      });
                    }

                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      child: Row(
                        children: combinedList.map((e) {
                          final lyric = e['lyric'].toString();
                          final time = double.parse(e['time'].toString());
                          final isHighlighted =
                              position.inSeconds * 1000 >= time * 1000;
                          return AnimatedOpacity(
                            opacity: isHighlighted ? 1.0 : 0.4,
                            duration: Duration(milliseconds: 1000),
                            child: Text(
                              lyric,
                              style: TextStyle(
                                fontSize: 16,
                                foreground: Paint()
                                  ..shader = isHighlighted
                                      ? const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.transparent
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ).createShader(
                                          Rect.fromLTWH(100.0, 100.0, 200.0, 70.0))
                                      : const LinearGradient(
                                          colors: [Colors.white, Colors.white],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ).createShader(
                                          Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Spacer(),
                  Text(
                    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
            Slider(
              value: position.inSeconds.toDouble(),
              min: 0.0,
              max: duration.inSeconds.toDouble(),
              onChanged: (double value) {
                setState(() {
                  audioPlayer.seek(Duration(seconds: value.toInt()));
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (isPlaying) {
                  audioPlayer.pause();
                } else {
                  audioPlayer.play(UrlSource(
                      "https://storage.googleapis.com/ikara-storage/tmp/beat.mp3"));
                }
                setState(() {
                  isPlaying = !isPlaying;
                });
              },
              child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }

  Future<http.Response> fetchData() {
    return http.get(Uri.parse(
        'https://storage.googleapis.com/ikara-storage/ikara/lyrics.xml'));
  }
}

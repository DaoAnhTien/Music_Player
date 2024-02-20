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
      totalHeight += 60.0; // Height of ListTile, you may adjust based on your UI
    }

    double targetScrollOffset = totalHeight - (listViewHeight / 1);

    if (targetScrollOffset > endPositionThreshold &&
        targetScrollOffset < _scrollController.position.maxScrollExtent - endPositionThreshold) {
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
                "https://anhcuoiviet.vn/wp-content/uploads/2022/11/background-dep-0.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 200,
              child: Align(
                alignment: Alignment.center,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final children = lyrics[index]
                        .findElements('i')
                        .map((e) => utf8.decode(e.text.codeUnits))
                        .toList();
                    double timeInSeconds = double.parse(
                      lyrics[index].findElements('i').first.getAttribute('va') ?? "0",
                    );
                    bool isHighlighted =
                        position.inMilliseconds >= timeInSeconds * 1000;
                    final textSpans = <TextSpan>[];
                    for (int i = 0; i < children.length; i++) {
                      textSpans.add(
                        TextSpan(
                          text: children[i],
                          style: TextStyle(
                            color: (position.inMilliseconds >= timeInSeconds * 1000)
                                ? Colors.orange
                                : Colors.white,
                          ),
                        ),
                      );
                    }
                    return ListTile(
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: textSpans,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ), Padding(
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

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart' as rx;
// import 'package:template/view/screen/final_exam/final_exam_controller.dart';
// import 'package:template/view/screen/final_exam/widget/seekbar.dart';
//
// class QuestionExamAudio extends StatefulWidget {
//   const QuestionExamAudio({
//     Key? key,
//     required this.audio,
//   }) : super(key: key);
//   final AudioPlayer audio;
//
//   @override
//   State<QuestionExamAudio> createState() => _QuestionExamAudioState();
// }
//
// class _QuestionExamAudioState extends State<QuestionExamAudio>
//     with WidgetsBindingObserver {
//   late final AudioPlayer _player = widget.audio;
//
//   Stream<PositionData> get _positionDataStream =>
//       rx.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
//           _player.positionStream,
//           _player.bufferedPositionStream,
//           _player.durationStream,
//               (position, bufferedPosition, duration) => PositionData(
//               position, bufferedPosition, duration ?? Duration.zero));
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: StreamBuilder(
//                     stream: widget.audio.playerStateStream,
//                     builder: (BuildContext context, AsyncSnapshot snapshot) {
//                       if (snapshot.hasData) {
//                         PlayerState state = snapshot.data as PlayerState;
//                         if (state.playing) {
//                           Get.put(FinalExamController())
//                               .countDownController
//                               .resume();
//                         }
//                       }
//                       return StreamBuilder<PositionData>(
//                         stream: _positionDataStream,
//                         builder: (context, snapshot) {
//                           final positionData = snapshot.data;
//                           return SeekBar(
//                             duration: positionData?.duration ?? Duration.zero,
//                             position: positionData?.position ?? Duration.zero,
//                             bufferedPosition:
//                             positionData?.bufferedPosition ?? Duration.zero,
//                             onChangeEnd: _player.seek,
//                             player: _player,
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

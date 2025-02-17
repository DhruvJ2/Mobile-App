import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsec_app/models/student_model/student_model.dart';
import 'package:tsec_app/provider/auth_provider.dart';
import 'package:tsec_app/screens/main_screen/widget/schedule_card.dart';

import 'package:tsec_app/utils/faculty_details.dart';
import '../../../models/timetable_model/timetable_model.dart';
import '../../../provider/timetable_provider.dart';
import '../../../utils/timetable_util.dart';

final dayProvider = StateProvider.autoDispose<String>((ref) {
  String day = getweekday(DateTime.now().weekday);
  return day;
});

class CardDisplay extends ConsumerStatefulWidget {
  const CardDisplay({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CardDisplayState();
}

class _CardDisplayState extends ConsumerState<CardDisplay> {
  static const colorList = [Colors.red, Colors.teal];
  static const opacityList = [
    Color.fromRGBO(255, 0, 0, 0.2),
    Color.fromARGB(51, 0, 255, 225),
  ];

  Future<String> getFacultyImageUrl(String facultyName) async {
    final ref =
        FirebaseStorage.instance.ref().child("faculty/comps/$facultyName.jpg");
    String url = (await ref.getDownloadURL()).toString();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(weekTimetableProvider);
    String day = ref.watch(dayProvider);

    return data.when(
        data: ((data) {
          if (data![day] == null) {
            return const SliverToBoxAdapter(
              child: Center(child: Text("No lectures Today ! ")),
            );
          } else {
            List<TimetableModel> timeTableDay = getTimetablebyDay(data, day);
            if (timeTableDay.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: Text("No lectures Today ! ")),
              );
            } else {
              return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 2.0,
                  ),
                  sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                    childCount: timeTableDay.length,
                    (context, index) {
                      bool labs = checkLabs(timeTableDay[index].lectureName);
                      final color = labs ? colorList[1] : colorList[0];
                      final opacity = labs ? opacityList[1] : opacityList[0];
                      final lectureFacultyname =
                          timeTableDay[index].lectureFacultyName;
                      return ScheduleCard(
                        color,
                        opacity,
                        lectureEndTime: timeTableDay[index].lectureEndTime,
                        lectureName: timeTableDay[index].lectureName,
                        lectureStartTime: timeTableDay[index].lectureStartTime,
                        facultyImageurl:
                            getFacultyImagebyName(lectureFacultyname),
                        facultyName: !checkTimetable(lectureFacultyname)
                            ? "---------"
                            : lectureFacultyname,
                        lectureBatch: timeTableDay[index].lectureBatch,
                      );
                    },
                  )));
            }
          }
        }),
        error: ((error, stackTrace) {
          return SliverToBoxAdapter(
            child: Center(child: Text(error.toString())),
          );
        }),
        loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ));
  }

  List<TimetableModel> getTimetablebyDay(
      Map<String, dynamic> data, String day) {
    List<TimetableModel> timeTableDay = [];
    final daylist = data[day];
    for (final item in daylist) {
      StudentModel? studentModel = ref.watch(studentModelProvider);
      if (item['lectureBatch'] == studentModel!.batch.toString() ||
          item['lectureBatch'] == 'All')
        timeTableDay.add(TimetableModel.fromJson(item));
    }
    return timeTableDay;
  }

  bool checkLabs(String lectureName) {
    if (lectureName.toLowerCase().endsWith('labs') ||
        lectureName.toLowerCase().endsWith('lab')) {
      return true;
    }
    return false;
  }

  bool checkTimetable(String lectureFacultyName) {
    if (lectureFacultyName.isEmpty || lectureFacultyName == " ") return true;
    return true;
  }
}

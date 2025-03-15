import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_mobile/screens/sub_plan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:quran_mobile/widgets/planner_dialog.dart';

String formatDate(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

String formatDateRange(DateTime start, DateTime end) {
  return "${formatDate(start)} to ${formatDate(end)}";
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  double progress = 0.0;
  bool isBehind = true;
  bool isLoading = true;
  List<Map<String, dynamic>> surahList = [];

  DateTime? startDate;
  DateTime? endDate;

  int? fromSurahIndex = 0;
  int? toSurahIndex = 0;
  int? fromAyah = 1;
  int? toAyah = 1;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchSurahs();
  }

  Future<void> fetchSurahs() async {
    try {
      final response =
          await http.get(Uri.parse("https://equran.id/api/v2/surat"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["data"] is List) {
          setState(() {
            surahList = List<Map<String, dynamic>>.from(data["data"]);
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load Surahs");
      }
    } catch (e) {
      print("Error fetching Surahs: $e");
      setState(() => isLoading = false);
    }
  }

  Stream<QuerySnapshot> fetchPlanners() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        .collection("planner")
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  String getSurahName(int surahNumber) {
    if (surahList.isEmpty ||
        surahNumber < 1 ||
        surahNumber > surahList.length) {
      return "Unknown";
    }
    return surahList[surahNumber - 1]["namaLatin"];
  }

  int calculateAyahCount(int fromSurah, int fromAyah, int toSurah, int toAyah) {
    int count = 0;

    if (surahList.isEmpty) return count;

    for (int i = fromSurah; i <= toSurah; i++) {
      int ayahCount = surahList[i - 1]["jumlahAyat"];

      if (i == fromSurah) {
        count += (ayahCount - fromAyah + 1);
      } else if (i == toSurah) {
        count += toAyah;
      } else {
        count += ayahCount;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "Planner",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fetchPlanners(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No data available"),
                  );
                }

                var planners = snapshot.data!.docs;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            var planner =
                                planners[index].data() as Map<String, dynamic>;

                            String name = planner["name"] ?? "Untitled";
                            Timestamp startTimestamp = planner["start_date"];
                            Timestamp endTimestamp = planner["end_date"];
                            int dailyGoal = planner["daily_goal"] ?? 0;
                            double progress =
                                (planner["progress"] ?? 0.0).toDouble();

                            int fromSurah = planner["from_surah"] ?? 1;
                            int toSurah = planner["to_surah"] ?? 1;
                            int fromAyah = planner["from_ayah"] ?? 1;
                            int toAyah = planner["to_ayah"] ?? 1;

                            String startDate = DateFormat.yMMMd()
                                .format(startTimestamp.toDate());
                            String endDate = DateFormat.yMMMd()
                                .format(endTimestamp.toDate());

                            String fromSurahName = getSurahName(fromSurah);
                            String toSurahName = getSurahName(toSurah);

                            int ayahCount = calculateAyahCount(
                                fromSurah, fromAyah, toSurah, toAyah);

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.green[50],
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (planner["remind_time"] != null)
                                          Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              CupertinoIcons.bell_fill,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.book,
                                            size: 18, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text(
                                            "$fromSurahName $fromAyah : $toSurahName $toAyah"),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.calendar_today,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                            "From $startDate to $endDate ($dailyGoal days)"),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.time,
                                            size: 18, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text("Goal: $ayahCount Ayahs"),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                        "${(progress * 100).toInt()}% Completed"),
                                    SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {
                                          String plannerId = planners[index].id;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SubPlannerScreen(
                                                      plannerId: plannerId),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.green[700],
                                        ),
                                        child: Text("Details"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: planners.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton(
          onPressed: () {
            showPlannerDialog(
              context: context,
              refreshParent: () => setState(() {}),
            );
          },
          backgroundColor: Colors.green,
          child: Icon(CupertinoIcons.add, color: Colors.white),
        ),
      ),
    );
  }
}

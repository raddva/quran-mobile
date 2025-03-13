import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  void savePlanner(
      String name,
      int fromSurah,
      int fromAyah,
      int toSurah,
      int toAyah,
      int days,
      bool notificationEnabled,
      TimeOfDay notificationTime,
      DateTime startDate,
      DateTime endDate) async {
    if (user == null) return;

    try {
      final plannerRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .collection("planner");

      final notificationTimeFormatted = notificationEnabled
          ? "${notificationTime.hour}:${notificationTime.minute}"
          : null;

      await plannerRef.add({
        "name": name,
        "start_date": Timestamp.fromDate(startDate),
        "end_date": Timestamp.fromDate(endDate),
        "remind_time": notificationTimeFormatted,
        "daily_goal": days,
        "progress": 0.0,
        "from_surah": fromSurah + 1,
        "from_ayah": fromAyah,
        "to_surah": toSurah + 1,
        "to_ayah": toAyah,
        "created_at": FieldValue.serverTimestamp(),
        "user_id": user?.uid,
      });

      showSuccessAlert(context, "Planner saved Successfully!");
    } catch (e) {
      print("Error saving planner: $e");
    }
  }

  void _showSurahAyahPicker(bool isFrom, Function updateParentState) {
    int? tempSurahIndex = isFrom ? fromSurahIndex : toSurahIndex;
    int? tempAyah = isFrom ? fromAyah : toAyah;
    List<int> tempAyahList = List.generate(
        surahList[tempSurahIndex ?? 0]["jumlahAyat"], (i) => i + 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(16),
              height: 350,
              child: Column(
                children: [
                  Text(
                    isFrom ? "Select Start" : "Select End",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Surah Picker
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            physics: FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempSurahIndex = index;
                                tempAyahList = List.generate(
                                    surahList[index]["jumlahAyat"],
                                    (i) => i + 1);
                                tempAyah = 1;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: surahList.length,
                              builder: (context, index) {
                                return Center(
                                  child: Text(
                                    "${surahList[index]["namaLatin"]}",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Ayah Picker
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            physics: FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempAyah = tempAyahList[index];
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: tempAyahList.length,
                              builder: (context, index) {
                                return Center(
                                  child: Text(
                                    "${tempAyahList[index]}",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (isFrom) {
                          fromSurahIndex = tempSurahIndex;
                          fromAyah = tempAyah;
                        } else {
                          toSurahIndex = tempSurahIndex;
                          toAyah = tempAyah;
                        }
                      });

                      updateParentState();
                      Navigator.pop(context);
                    },
                    child: Text("DONE"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPlannerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String plannerName = "";
        bool notificationEnabled = false;
        TimeOfDay notificationTime = TimeOfDay(hour: 12, minute: 30);
        DateTime? startDate;
        DateTime? endDate;

        return StatefulBuilder(builder: (context, setState) {
          int days = (startDate != null && endDate != null)
              ? endDate!.difference(startDate!).inDays + 1
              : 0;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    "Add Planner",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    plannerName = value;
                  },
                ),
                SizedBox(height: 16),
                Text("Select Range",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                _buildSurahSelector("From", true, setState),
                SizedBox(height: 12),
                _buildSurahSelector("To", false, setState),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Date",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                      child: Text(
                        startDate == null || endDate == null
                            ? "Pick Date"
                            : "${formatDate(startDate!)} to ${formatDate(endDate!)}",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Number of Days",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("$days days",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Notification", style: TextStyle(fontSize: 16)),
                    Switch(
                      value: notificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
                if (notificationEnabled)
                  GestureDetector(
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: notificationTime,
                      );
                      if (picked != null) {
                        setState(() {
                          notificationTime = picked;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Notification Time",
                              style: TextStyle(fontSize: 16)),
                          Text("${notificationTime.format(context)}",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (fromSurahIndex == null || toSurahIndex == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Please select a valid Surah & Ayah range")),
                          );
                          return;
                        }

                        if (startDate == null || endDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Please select a start and end date")),
                          );
                          return;
                        }

                        savePlanner(
                          plannerName,
                          fromSurahIndex!,
                          fromAyah!,
                          toSurahIndex!,
                          toAyah!,
                          days,
                          notificationEnabled,
                          notificationTime,
                          startDate!,
                          endDate!,
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        minimumSize: Size(120, 48),
                      ),
                      child: Text("Add", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildSurahSelector(String label, bool isFrom, Function setState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        GestureDetector(
          onTap: () => _showSurahAyahPicker(isFrom, () {
            setState(() {});
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (isFrom ? fromSurahIndex != null : toSurahIndex != null) &&
                          surahList.isNotEmpty
                      ? "${surahList[isFrom ? fromSurahIndex! : toSurahIndex!]["namaLatin"]} - Ayah ${isFrom ? fromAyah : toAyah}"
                      : "Select $label Surah & Ayah",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 8),
                Icon(CupertinoIcons.chevron_down,
                    color: Colors.black, size: 12),
              ],
            ),
          ),
        ),
      ],
    );
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
                if (!snapshot.hasData ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
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
                                    SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {},
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
            _showAddPlannerDialog();
          },
          backgroundColor: Colors.green,
          child: Icon(CupertinoIcons.add, color: Colors.white),
        ),
      ),
    );
  }
}

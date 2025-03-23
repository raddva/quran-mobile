import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:quran_mobile/widgets/alert_dialog.dart';

String formatDate(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

void showPlannerDialog({
  required BuildContext context,
  String? existingPlannerId,
  String? initialName,
  int? initialFromSurah,
  int? initialFromAyah,
  int? initialToSurah,
  int? initialToAyah,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  bool initialNotificationEnabled = false,
  TimeOfDay? initialNotificationTime,
  double? initialProgress,
  required Function() refreshParent,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return _PlannerDialogContent(
        existingPlannerId: existingPlannerId,
        initialName: initialName,
        initialFromSurah: initialFromSurah,
        initialFromAyah: initialFromAyah,
        initialToSurah: initialToSurah,
        initialToAyah: initialToAyah,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        initialNotificationEnabled: initialNotificationEnabled,
        initialNotificationTime: initialNotificationTime,
        initialProgress: initialProgress,
        refreshParent: refreshParent,
      );
    },
  );
}

class _PlannerDialogContent extends StatefulWidget {
  final String? existingPlannerId;
  final String? initialName;
  final int? initialFromSurah;
  final int? initialFromAyah;
  final int? initialToSurah;
  final int? initialToAyah;
  final double? initialProgress;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool initialNotificationEnabled;
  final TimeOfDay? initialNotificationTime;
  final Function() refreshParent;

  const _PlannerDialogContent({
    Key? key,
    this.existingPlannerId,
    this.initialName,
    this.initialFromSurah,
    this.initialFromAyah,
    this.initialToSurah,
    this.initialToAyah,
    this.initialProgress,
    this.initialStartDate,
    this.initialEndDate,
    this.initialNotificationEnabled = false,
    this.initialNotificationTime,
    required this.refreshParent,
  }) : super(key: key);

  @override
  State<_PlannerDialogContent> createState() => _PlannerDialogContentState();
}

class _PlannerDialogContentState extends State<_PlannerDialogContent> {
  late TextEditingController nameController;

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
  String plannerName = "";
  int? fromSurah;
  int? toSurah;
  int? days;
  bool notificationEnabled = false;
  TimeOfDay notificationTime = TimeOfDay(hour: 12, minute: 30);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? "");
    plannerName = nameController.text;

    fromSurahIndex =
        (widget.initialFromSurah != null) ? widget.initialFromSurah! - 1 : 0;
    toSurahIndex =
        (widget.initialToSurah != null) ? widget.initialToSurah! - 1 : 0;

    fromAyah = widget.initialFromAyah ?? 1;
    toAyah = widget.initialToAyah ?? 1;

    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;

    notificationEnabled = widget.initialNotificationEnabled;
    notificationTime =
        widget.initialNotificationTime ?? TimeOfDay(hour: 12, minute: 30);

    progress = widget.initialProgress ?? 0.0;
    fetchSurahs();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> fetchSurahs() async {
    try {
      final response =
          await http.get(Uri.parse("https://equran.id/api/v2/surat"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["data"] is List) {
          final list = List<Map<String, dynamic>>.from(data["data"]);

          int? tempFromSurahIndex = widget.initialFromSurah != null
              ? widget.initialFromSurah! - 1
              : 0;
          int? tempToSurahIndex =
              widget.initialToSurah != null ? widget.initialToSurah! - 1 : 0;

          setState(() {
            surahList = list;
            fromSurahIndex = tempFromSurahIndex;
            toSurahIndex = tempToSurahIndex;
            fromAyah = widget.initialFromAyah ?? 1;
            toAyah = widget.initialToAyah ?? 1;
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

  void saveOrUpdatePlanner() async {
    if (user == null) return;

    final plannerRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        .collection("planner");

    final notificationTimeFormatted = notificationEnabled
        ? "${notificationTime.hour}:${notificationTime.minute}"
        : null;

    int calculatedDays = endDate!.difference(startDate!).inDays + 1;

    Map<String, dynamic> plannerData = {
      "name": nameController.text.trim(),
      "start_date": Timestamp.fromDate(startDate!),
      "end_date": Timestamp.fromDate(endDate!),
      "remind_time": notificationTimeFormatted,
      "daily_goal": calculatedDays,
      "progress": progress,
      "from_surah": (fromSurahIndex ?? 0) + 1,
      "from_ayah": fromAyah ?? 1,
      "to_surah": (toSurahIndex ?? 0) + 1,
      "to_ayah": toAyah ?? 1,
      "created_at": FieldValue.serverTimestamp(),
      "user_id": user?.uid,
    };

    try {
      if (widget.existingPlannerId == null) {
        await plannerRef.add(plannerData);
      } else {
        await plannerRef.doc(widget.existingPlannerId).update(plannerData);
      }

      Navigator.pop(context);
      widget.refreshParent();

      if (widget.existingPlannerId == null) {
        showSuccessAlert(context, "Planner added Successfully!");
      } else {
        showSuccessAlert(context, "Planner updated Successfully!");
      }
    } catch (e) {
      print("Error saving/updating planner: $e");
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
                  Text(isFrom ? "Select Start" : "Select End",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Surah Picker
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(
                                initialItem: tempSurahIndex ?? 0),
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
                                      style: TextStyle(fontSize: 16)),
                                );
                              },
                            ),
                          ),
                        ),
                        // Ayah Picker
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(
                                initialItem: (tempAyah ?? 1) - 1),
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
                                  child: Text("${tempAyahList[index]}",
                                      style: TextStyle(fontSize: 16)),
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
                          fromSurahIndex = tempSurahIndex ?? 0;
                          fromAyah = tempAyah ?? 1;
                        } else {
                          toSurahIndex = tempSurahIndex ?? 0;
                          toAyah = tempAyah ?? 1;
                        }
                      });
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
              widget.existingPlannerId == null
                  ? "Add Planner"
                  : "Update Planner",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Name",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) {
              plannerName = value;
            },
          ),
          SizedBox(height: 16),
          Text("Select Range", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          _buildSurahSelector("From", true, setState),
          SizedBox(height: 12),
          _buildSurahSelector("To", false, setState),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select Date",
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              Text("$days days", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text("Notification", style: TextStyle(fontSize: 16)),
          //     Switch(
          //       value: notificationEnabled,
          //       onChanged: (value) {
          //         setState(() {
          //           notificationEnabled = value;
          //         });
          //       },
          //     ),
          //   ],
          // ),
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
                    Text("Notification Time", style: TextStyle(fontSize: 16)),
                    Text("${notificationTime.format(context)}",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: saveOrUpdatePlanner,
            child: Text(widget.existingPlannerId == null
                ? "Add Planner"
                : "Update Planner"),
          ),
        ],
      ),
    );
  }
}

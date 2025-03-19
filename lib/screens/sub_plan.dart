import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_mobile/screens/sub_home.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';
import 'package:quran_mobile/widgets/planner_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubPlannerScreen extends StatefulWidget {
  final String plannerId;

  const SubPlannerScreen({super.key, required this.plannerId});

  @override
  State<SubPlannerScreen> createState() => _SubPlannerScreenState();
}

class _SubPlannerScreenState extends State<SubPlannerScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  Map<String, dynamic>? plannerData;
  List<Map<String, dynamic>> subPlannerData = [];
  Map<int, String> surahNames = {};
  int? latestSurahNumber;
  int? latestAyahNumber;

  @override
  void initState() {
    super.initState();
    fetchSurahNames();
  }

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> fetchSurahNames() async {
    final response =
        await http.get(Uri.parse('https://equran.id/api/v2/surat'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      for (var surah in data['data']) {
        surahNames[surah['nomor']] = surah['namaLatin'];
      }
      fetchPlannerData();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchPlannerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .collection("planner")
          .doc(widget.plannerId)
          .get();

      if (doc.exists) {
        plannerData = doc.data();
      }

      final subDocs = await FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .collection("tracker")
          .where("planner_id", isEqualTo: widget.plannerId)
          .where("status", isEqualTo: "planner")
          .get();

      Map<int, List<Map<String, dynamic>>> grouped = {};

      for (var doc in subDocs.docs) {
        final data = doc.data();
        int? surahId = data["surah_id"];
        int? ayahId = data["ayah_id"];

        if (surahId == null || ayahId == null) continue;

        grouped.putIfAbsent(surahId, () => []).add(data);
      }

      List<Map<String, dynamic>> trackerList = [];

      grouped.forEach((surahId, items) {
        List<int> ayahIds = items
            .map((e) => e["ayah_id"] as int)
            .whereType<int>()
            .toList()
          ..sort();

        if (ayahIds.isEmpty) return;

        String ayahRange = ayahIds.length == 1
            ? "${ayahIds.first}"
            : "${ayahIds.first}-${ayahIds.last}";

        Timestamp? latestTimestamp = items
            .map((e) => e["completed_at"])
            .whereType<Timestamp>()
            .fold<Timestamp?>(null, (prev, curr) {
          if (prev == null) return curr;
          return curr.toDate().isAfter(prev.toDate()) ? curr : prev;
        });

        trackerList.add({
          "surah": surahNames[surahId] ?? "Surah $surahId",
          "ayah_range": ayahRange,
          "completed_at": latestTimestamp,
        });
      });

      List<Map<String, int>> fullAyahList = [];
      if (plannerData != null) {
        int fromSurah = plannerData!["from_surah"];
        int fromAyah = plannerData!["from_ayah"];
        int toSurah = plannerData!["to_surah"];
        int toAyah = plannerData!["to_ayah"];

        for (int surah = fromSurah; surah <= toSurah; surah++) {
          final response = await http
              .get(Uri.parse('https://equran.id/api/v2/surat/$surah'));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            int totalAyah = data['data']['jumlahAyat'];

            int startAyah = (surah == fromSurah) ? fromAyah : 1;
            int endAyah = (surah == toSurah) ? toAyah : totalAyah;

            for (int ayah = startAyah; ayah <= endAyah; ayah++) {
              fullAyahList.add({"surah": surah, "ayah": ayah});
            }
          }
        }
      }

      final completedSet = subDocs.docs
          .map((doc) => doc.data())
          .where((data) => data["surah_id"] != null && data["ayah_id"] != null)
          .map((data) => "${data["surah_id"]}:${data["ayah_id"]}")
          .toSet();

      Map<String, int>? nextAyah;
      for (var item in fullAyahList) {
        final key = "${item["surah"]}:${item["ayah"]}";
        if (!completedSet.contains(key)) {
          nextAyah = item;
          break;
        }
      }

      if (nextAyah != null) {
        latestSurahNumber = nextAyah["surah"];
        latestAyahNumber = nextAyah["ayah"];
      } else if (fullAyahList.isNotEmpty) {
        latestSurahNumber = fullAyahList.last["surah"];
        latestAyahNumber = fullAyahList.last["ayah"];
      }

      setState(() {
        subPlannerData = trackerList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching planner data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        subPlannerData.isEmpty ? 0.0 : (plannerData?["progress"] ?? 0.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text(
          "Plan Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                Icon(CupertinoIcons.arrow_up_right_square, color: Colors.white),
            tooltip: "Read",
            onPressed: (latestSurahNumber == null)
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubHomeScreen(
                          surahNumber: latestSurahNumber!,
                          ayahNumber: latestAyahNumber,
                          plannerId: widget.plannerId,
                        ),
                      ),
                    );

                    setState(() => isLoading = true);
                    fetchPlannerData();
                  },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      plannerData?["name"] ?? "Unnamed Plan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      "${surahNames[plannerData?["from_surah"]] ?? 'Surah ${plannerData?["from_surah"]}'} "
                      "Ayah ${plannerData?["from_ayah"]} → "
                      "${surahNames[plannerData?["to_surah"]] ?? 'Surah ${plannerData?["to_surah"]}'} "
                      "Ayah ${plannerData?["to_ayah"]}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Progress",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 14,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${progress.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Completion History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.delete, color: Colors.red),
                        tooltip: "Delete Plan",
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Delete Planner"),
                              content: Text(
                                  "Are you sure you want to delete this planner and its history?"),
                              actions: [
                                TextButton(
                                  child: Text("Cancel"),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              final uid = user?.uid;
                              final firestore = FirebaseFirestore.instance;

                              await firestore
                                  .collection("users")
                                  .doc(uid)
                                  .collection("planner")
                                  .doc(widget.plannerId)
                                  .delete();

                              final trackerSnapshot = await firestore
                                  .collection("users")
                                  .doc(uid)
                                  .collection("tracker")
                                  .where("planner_id",
                                      isEqualTo: widget.plannerId)
                                  .get();

                              for (var doc in trackerSnapshot.docs) {
                                await doc.reference.delete();
                              }
                              Navigator.pop(context);
                              showSuccessAlert(
                                  context, "Planner and history deleted.");
                            } catch (e) {
                              showCustomAlertDialog(context,
                                  "Failed to delete planner", e.toString());
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: subPlannerData.isEmpty
                        ? Center(
                            child: Text(
                              "No history available",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.green.shade100),
                              dataRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.grey.shade50),
                              columnSpacing: 12,
                              columns: const [
                                DataColumn(
                                    label: Text("No",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Surah",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Ayah",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text("Completed",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows:
                                  List.generate(subPlannerData.length, (index) {
                                final item = subPlannerData[index];
                                return DataRow(
                                  cells: [
                                    DataCell(Text("${index + 1}")),
                                    DataCell(Text(item["surah"] ?? "Unknown")),
                                    DataCell(Text(item["ayah_range"] ?? "N/A")),
                                    DataCell(
                                      Text(
                                        item["completed_at"] is Timestamp
                                            ? formatTimestamp(
                                                item["completed_at"])
                                            : (item["completed_at"]
                                                    ?.toString() ??
                                                "N/A"),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                  )
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (plannerData == null) return;

          showPlannerDialog(
            context: context,
            existingPlannerId: widget.plannerId,
            initialName: plannerData?["name"],
            initialFromSurah: (plannerData?["from_surah"] ?? 1),
            initialFromAyah: plannerData?["from_ayah"],
            initialToSurah: (plannerData?["to_surah"] ?? 1),
            initialToAyah: plannerData?["to_ayah"],
            initialStartDate:
                (plannerData?["start_date"] as Timestamp).toDate(),
            initialProgress: plannerData?["progress"],
            initialEndDate: (plannerData?["end_date"] as Timestamp).toDate(),
            initialNotificationEnabled: plannerData?["remind_time"] != null,
            initialNotificationTime: plannerData?["remind_time"] != null
                ? TimeOfDay(
                    hour: int.parse(plannerData!["remind_time"].split(":")[0]),
                    minute:
                        int.parse(plannerData!["remind_time"].split(":")[1]),
                  )
                : null,
            refreshParent: () => fetchPlannerData(),
          );
        },
        backgroundColor: Colors.green,
        child: Icon(CupertinoIcons.pencil, color: Colors.white),
      ),
    );
  }
}

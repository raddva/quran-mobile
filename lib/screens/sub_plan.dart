import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_mobile/widgets/planner_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    fetchPlannerData();
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

      setState(() {
        subPlannerData = subDocs.docs.map((e) => e.data()).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
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
            onPressed: () => {},
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: progress * 100,
                                  color: Colors.green,
                                  radius: 40,
                                  title: "${(progress * 100).toInt()}%",
                                  titleStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 100 - (progress * 100),
                                  color: Colors.grey[300]!,
                                  radius: 40,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.green.shade100),
                      columns: [
                        DataColumn(
                            label: Text("No",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("Surah",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("Ayah",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("Completed",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: subPlannerData.isEmpty
                          ? [
                              DataRow(cells: [
                                DataCell(SizedBox.shrink()),
                                DataCell(
                                  Center(
                                    child: Text(
                                      "No history available",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ),
                                DataCell(SizedBox.shrink()),
                                DataCell(SizedBox.shrink()),
                              ]),
                            ]
                          : List.generate(subPlannerData.length, (index) {
                              final item = subPlannerData[index];

                              return DataRow(cells: [
                                DataCell(Text("${index + 1}")),
                                DataCell(Text(item["surah"] ?? "Unknown")),
                                DataCell(Text(item["ayah_range"] ?? "N/A")),
                                DataCell(Text(item["completed_at"] ?? "N/A")),
                              ]);
                            }),
                    ),
                  ),
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

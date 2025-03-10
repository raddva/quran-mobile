import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String selectedMonth = "All";
  bool isLoading = true;

  final int totalAyahs = 6236;
  List<Map<String, dynamic>> trackerData = [];
  Map<int, String> surahNames = {};
  double overallProgressPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    fetchSurahNames();
  }

  Future<void> fetchSurahNames() async {
    final response =
        await http.get(Uri.parse('https://equran.id/api/v2/surat'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      for (var surah in data['data']) {
        surahNames[surah['nomor']] = surah['namaLatin'];
      }
      fetchTrackerData();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTrackerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("tracker")
          .orderBy("completed_at", descending: true)
          .get();

      Map<int, Map<String, List<int>>> groupedData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        int? ayah = data["ayah_id"];
        int? surahId = data["surah_id"];

        if (ayah == null || surahId == null) {
          continue;
        }

        DateTime? completedDate = data["completed_at"] != null
            ? (data["completed_at"] as Timestamp).toDate()
            : null;

        if (completedDate == null) continue;

        String formattedDate = completedDate.toIso8601String().split("T")[0];
        String month = DateFormat("MMMM").format(completedDate);

        if (!groupedData.containsKey(surahId)) {
          groupedData[surahId] = {};
        }
        if (!groupedData[surahId]!.containsKey(formattedDate)) {
          groupedData[surahId]![formattedDate] = [];
        }

        groupedData[surahId]![formattedDate]!.add(ayah);
      }

      List<Map<String, dynamic>> tempData = [];
      groupedData.forEach((surahId, dateMap) {
        String surahName = surahNames[surahId] ?? "Unknown";

        dateMap.forEach((date, ayahs) {
          ayahs.sort();

          String ayahRange =
              ayahs.isNotEmpty ? "${ayahs.first}-${ayahs.last}" : "N/A";

          tempData.add({
            "surah": surahName,
            "ayah_range": ayahRange,
            "completed_at": date,
            "month": date.substring(0, 7),
          });
        });
      });

      setState(() {
        trackerData = tempData;
        overallProgressPercent =
            (getCompletedAyahs() / totalAyahs).clamp(0.0, 1.0);
      });
    } catch (e) {
      print("Error fetching tracker data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  int getCompletedAyahs() {
    int count = 0;
    for (var entry in trackerData) {
      if (entry["ayah_range"] != "N/A") {
        List<String> range = entry["ayah_range"].split("-");
        if (range.length == 2) {
          count += (int.parse(range[1]) - int.parse(range[0]) + 1);
        } else {
          count += 1;
        }
      }
    }
    return count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> monthCounts = {};
    for (var entry in trackerData) {
      monthCounts[entry["month"]] = (monthCounts[entry["month"]] ?? 0) + 1;
    }

    List<Map<String, dynamic>> filteredData = selectedMonth == "All"
        ? trackerData
        : trackerData.where((item) => item["month"] == selectedMonth).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 50,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Tracker",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 16,
                ),
              ),
              centerTitle: true,
            ),
          ),
          if (isLoading)
            SliverFillRemaining(
              child:
                  Center(child: CircularProgressIndicator(color: Colors.green)),
            ),
          if (!isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Select Month:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                          value: selectedMonth,
                          items: ["All", ...monthCounts.keys]
                              .map((month) => DropdownMenuItem(
                                    value: month,
                                    child: Text(month == "All"
                                        ? "All"
                                        : DateFormat("MMMM").format(
                                            DateTime.parse("$month-01"))),
                                  ))
                              .toList(),
                          onChanged: (newMonth) {
                            setState(() {
                              selectedMonth = newMonth!;
                              _controller.forward(
                                  from: 0.0); // Restart animation on update
                            });
                          }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildPieChart(monthCounts)),
                  const SizedBox(height: 16),
                  const Text("Quran Completion Progress:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  LinearProgressIndicator(value: overallProgressPercent),
                  Text(
                      "${(overallProgressPercent * 100).toStringAsFixed(1)}% completed"),
                  const SizedBox(height: 24),
                  const Text("History",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  _buildHistoryTable(filteredData),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  int touchedIndex = -1;
  Widget _buildPieChart(Map<String, int> monthCounts) {
    List<Color> greenShades = [
      Colors.green[900]!,
      Colors.green[800]!,
      Colors.green[700]!,
      Colors.green[600]!,
      Colors.green[500]!,
      Colors.green[400]!,
    ];

    Map<String, int> filteredCounts = selectedMonth == "All"
        ? monthCounts
        : {selectedMonth: monthCounts[selectedMonth] ?? 0};

    bool hasData = filteredCounts.values.any((count) => count > 0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return PieChart(
          PieChartData(
            sections: hasData
                ? filteredCounts.entries.map((entry) {
                    int index =
                        filteredCounts.keys.toList().indexOf(entry.key) %
                            greenShades.length;
                    return PieChartSectionData(
                      value: entry.value.toDouble() * value,
                      title: touchedIndex == index
                          ? DateFormat("MMMM yyyy")
                              .format(DateTime.parse("${entry.key}-01"))
                          : "",
                      color: greenShades[index],
                      radius: touchedIndex == index ? 60 : 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList()
                : [
                    PieChartSectionData(
                      value: 1,
                      title: "",
                      color: Colors.grey.shade300,
                      radius: 50,
                    ),
                  ],
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (event is FlTapUpEvent || event is FlLongPressMoveUpdate) {
                    touchedIndex =
                        pieTouchResponse?.touchedSection?.touchedSectionIndex ??
                            -1;
                  } else if (event is FlPanEndEvent ||
                      event is FlLongPressEnd) {
                    touchedIndex = -1;
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "No data available",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.green.shade100),
            columns: const [
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
            rows: List.generate(data.length, (index) {
              final item = data[index];

              return DataRow(cells: [
                DataCell(Text("${index + 1}")),
                DataCell(Text(item["surah"] ?? "Unknown")),
                DataCell(Text(item["ayah_range"] ?? "N/A")),
                DataCell(Text(item["completed_at"] ?? "N/A")),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

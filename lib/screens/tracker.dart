import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String selectedMonth = "All";

  final List<Map<String, dynamic>> trackerData = [
    {
      "month": "March",
      "surah": "Al-Baqarah",
      "ayah_range": "1-5",
      "completed_at": "2025-03-04"
    },
    {
      "month": "March",
      "surah": "Al-Baqarah",
      "ayah_range": "6-10",
      "completed_at": "2025-03-05"
    },
    {
      "month": "February",
      "surah": "Al-Fatiha",
      "ayah_range": "1-7",
      "completed_at": "2025-02-06"
    },
    {
      "month": "January",
      "surah": "Al-Imran",
      "ayah_range": "1-5",
      "completed_at": "2025-01-07"
    },
  ];

  final int totalAyahs = 6236;
  final int totalSurahs = 114;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredData = selectedMonth == "All"
        ? trackerData
        : trackerData.where((item) => item["month"] == selectedMonth).toList();

    int completedAyahs = trackerData.fold(0, (sum, entry) {
      List<String> rangeParts = entry["ayah_range"].split("-");
      int start = int.parse(rangeParts[0]);
      int end = int.parse(rangeParts[1]);
      return sum + (end - start + 1);
    });

    double overallProgressPercent =
        (completedAyahs / totalAyahs).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          "Tracker",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Month:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedMonth,
                  items: ["All", "January", "February", "March"]
                      .map((month) =>
                          DropdownMenuItem(value: month, child: Text(month)))
                      .toList(),
                  onChanged: (newMonth) {
                    setState(() {
                      selectedMonth = newMonth!;
                      _controller.forward(from: 0.0);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_controller.value * 0.1),
                  child: SizedBox(height: 200, child: _buildPieChart()),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text("Quran Completion Progress:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            LinearProgressIndicator(value: overallProgressPercent),
            Text(
                "${(overallProgressPercent * 100).toStringAsFixed(1)}% completed"),
            const SizedBox(height: 24),
            const Text("History",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildHistoryTable(filteredData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    Map<String, double> monthData = {
      "January": 1,
      "February": 3,
      "March": 6,
    };

    return PieChart(
      PieChartData(
        sections: monthData.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            title: entry.key,
            color: entry.key == selectedMonth ? Colors.blue : Colors.grey,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
      ),
    );
  }

  Widget _buildHistoryTable(List<Map<String, dynamic>> data) {
    return Container(
      width: double.infinity, // Ensures full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: DataTable(
        columnSpacing: 20,
        headingRowColor:
            MaterialStateColor.resolveWith((states) => Colors.green.shade100),
        columns: const [
          DataColumn(
              label: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text("Surah", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text("Ayah", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text("Completed",
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: List.generate(data.length, (index) {
          final item = data[index];
          return DataRow(
            color: MaterialStateProperty.resolveWith((states) => Colors.white),
            cells: [
              DataCell(Text("${index + 1}")),
              DataCell(Text(item["surah"])),
              DataCell(Text(item["ayah_range"])),
              DataCell(Text(item["completed_at"])),
            ],
          );
        }),
      ),
    );
  }
}

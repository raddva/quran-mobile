import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  double progress = 0.0;
  bool isBehind = true;

  List<Map<String, dynamic>> surahList = [];
  List<int> fromAyahList = [];
  List<int> toAyahList = [];

  int? fromSurahIndex;
  int? toSurahIndex;
  int? fromAyah = 1;
  int? toAyah = 1;

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
            if (surahList.isNotEmpty) {
              fromSurahIndex = 0;
              toSurahIndex = 0;
              fromAyahList =
                  List.generate(surahList[0]["jumlahAyat"], (i) => i + 1);
              toAyahList = fromAyahList;
            }
          });
        }
      } else {
        throw Exception("Failed to load Surahs");
      }
    } catch (e) {
      print("Error fetching Surahs: $e");
    }
  }

  void _showSurahAyahPicker(bool isFrom) {
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
                    isFrom
                        ? "Select From Surah & Ayah"
                        : "Select To Surah & Ayah",
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
        int days = 1;
        bool notificationEnabled = false;
        TimeOfDay notificationTime = TimeOfDay(hour: 12, minute: 30);

        return StatefulBuilder(builder: (context, setState) {
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
                  decoration: InputDecoration(labelText: "Name"),
                  onChanged: (value) {
                    plannerName = value;
                  },
                ),
                SizedBox(height: 12),
                Text("Select Range",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("From", style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () => _showSurahAyahPicker(true),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (fromSurahIndex != null && surahList.isNotEmpty)
                                  ? "${surahList[fromSurahIndex!]["namaLatin"]} - Ayah $fromAyah"
                                  : "Select From Surah & Ayah",
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.chevron_down,
                              color: Colors.black,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("To", style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () => _showSurahAyahPicker(false),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (fromSurahIndex != null && surahList.isNotEmpty)
                                  ? "${surahList[fromSurahIndex!]["namaLatin"]} - Ayah $fromAyah"
                                  : "Select To Surah & Ayah",
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.chevron_down,
                              color: Colors.black,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Number of Days"),
                  onChanged: (value) {
                    days = int.tryParse(value) ?? 1;
                  },
                ),
                SizedBox(height: 12),
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
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (fromSurahIndex! > toSurahIndex! ||
                            (fromSurahIndex == toSurahIndex &&
                                fromAyah! > toAyah!)) {
                          Future.delayed(Duration.zero, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "From Surah cannot be greater than To Surah!"),
                              ),
                            );
                          });
                          return;
                        }
                        Navigator.pop(context);
                      },
                      child: Text("Add"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Planner"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Test Planner",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.amber),
                        SizedBox(width: 8),
                        Text("Al-Fatihah 1:1 to Al-Baqarah 2:5"),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.book, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Page no. 1 - 2"),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Juz no. 1"),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye,
                            size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Currently at Al-Fatihah 1:1"),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Ends in Feb 17, 2025 (in 0 days)"),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text("${(progress * 100).toInt()}% Completed"),
                    SizedBox(height: 12),
                    if (isBehind)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.brown),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  "You are behind 1 session. You can do it!"),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.menu_book, color: Colors.green),
                          label: Text("Read"),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("View Details"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _showAddPlannerDialog,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text("Add Planner"),
            ),
          ],
        ),
      ),
    );
  }
}

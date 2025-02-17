import 'package:flutter/material.dart';
import 'package:quran_mobile/models/surah_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quran_mobile/screens/sub_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Surah> surahList = [];
  List<Surah> filteredSurahList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSurahs();
  }

  Future<void> fetchSurahs() async {
    final response =
        await http.get(Uri.parse('https://equran.id/api/v2/surat'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> surahData = data['data'];

      setState(() {
        surahList = surahData.map((json) => Surah.fromJson(json)).toList();
        filteredSurahList = surahList;
      });
    } else {
      throw Exception('Failed to load Surahs');
    }
  }

  void filterSurahs(String query) {
    setState(() {
      filteredSurahList = surahList
          .where(
              (surah) => surah.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search Surah...',
                prefixIcon: Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: filterSurahs,
            ),
          ),
          Expanded(
            child: filteredSurahList.isEmpty
                ? Center(child: CircularProgressIndicator(color: Colors.green))
                : ListView.builder(
                    itemCount: filteredSurahList.length,
                    itemBuilder: (context, index) {
                      final surah = filteredSurahList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12.0),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: Text(
                                '${surah.number}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800]),
                              ),
                            ),
                            title: Text(
                              surah.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  surah.translation,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                                SizedBox(width: 5),
                                Image.asset(
                                  surah.tempatTurun == "Mekah"
                                      ? 'assets/Icons/mecca.png'
                                      : 'assets/Icons/madina.png',
                                  width: 15,
                                  height: 15,
                                ),
                              ],
                            ),
                            trailing: Text(
                              surah.arabic,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Amiri',
                                  color: Colors.green[900]),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SubHomeScreen(surahNumber: surah.number),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

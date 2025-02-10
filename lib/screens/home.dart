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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search Surah...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: filterSurahs,
            ),
          ),
          Expanded(
            child: filteredSurahList.isEmpty
                ? Center(child: LinearProgressIndicator())
                : ListView.builder(
                    itemCount: filteredSurahList.length,
                    itemBuilder: (context, index) {
                      final surah = filteredSurahList[index];
                      return ListTile(
                        leading: Text('${surah.number}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        title: Text(surah.name,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Row(
                          children: [
                            Text(
                              surah.translation,
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SubHomeScreen(surahNumber: surah.number),
                            ),
                          );
                        },
                        trailing: Text(surah.arabic,
                            style:
                                TextStyle(fontSize: 20, fontFamily: 'Amiri')),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

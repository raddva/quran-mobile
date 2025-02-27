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

  String convertToArabicNumber(int number) {
    final arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicDigits[int.parse(digit)])
        .join();
  }

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
      filteredSurahList = surahList.where((surah) {
        final name = surah.name.toLowerCase();
        final translation = surah.translation.toLowerCase();
        final arabic = surah.arabic.toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            translation.contains(searchQuery) ||
            arabic.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              titlePadding: EdgeInsets.zero,
              title: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.2),
                    hintText: 'Search Surah',
                    prefixIcon: Icon(Icons.search, color: Colors.green),
                    // focusColor: Colors.green,
                    // hoverColor: Colors.green[500],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: Colors.green,
                      ),
                    ),
                  ),
                  style: TextStyle(color: Colors.green),
                  onChanged: filterSurahs,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final surah = filteredSurahList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [Colors.green[100]!, Colors.green[300]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 5,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[700],
                          child: Text(
                            '${convertToArabicNumber(surah.number)}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        title: Text(
                          surah.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              surah.translation,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.white70),
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
                              color: Colors.white),
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
                childCount: filteredSurahList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

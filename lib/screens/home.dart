import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/models/surah_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quran_mobile/screens/sub_home.dart';
import 'package:quran_mobile/utils/functions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Surah> surahList = [];
  List<Surah> filteredSurahList = [];
  List<Map<String, dynamic>> quotes = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSurahs();
    fetchQuotes();
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

  void fetchQuotes() async {
    try {
      const String adminUid = '981uVvxeVLevNybG75VB4VJuzmJ3';
      final snapshot = await FirebaseFirestore.instance
          .collection("admin")
          .doc(adminUid)
          .collection("quotes")
          .get();
      final docs = snapshot.docs;

      setState(() {
        quotes = docs.map((doc) {
          final data = doc.data();
          return {
            'quote': data['quote'] ?? '',
            'subtitle': data['subtitle'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Failed to fetch quotes: $e');
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
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(CupertinoIcons.search, color: Colors.green),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.green, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          BorderSide(color: Colors.green.shade700, width: 2.0),
                    ),
                  ),
                  style: TextStyle(color: Colors.green),
                  onChanged: filterSurahs,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0),
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: quotes.length,
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.green[200]!, Colors.green[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote['quote']!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quote['subtitle']!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                            convertToArabicNumber(surah.number),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              surah.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                            SizedBox(width: 2),
                            Image.asset(
                              surah.tempatTurun == "Mekah"
                                  ? 'assets/Icons/mecca-white.png'
                                  : 'assets/Icons/madina-white.png',
                              width: 15,
                              height: 15,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          surah.translation.length > 18
                              ? '${surah.translation.substring(0, 18)}...'
                              : surah.translation,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
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

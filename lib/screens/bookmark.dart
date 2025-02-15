import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_mobile/screens/sub_home.dart';
import 'dart:convert';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> bookmarks = [];
  List<Map<String, dynamic>> notes = [];
  Map<int, String> surahNames = {};
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchBookmarksAndNotes();
  }

  Future<void> fetchBookmarksAndNotes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookmarkRef =
        _firestore.collection("users").doc(user.uid).collection("bookmarks");

    final notesRef =
        _firestore.collection("users").doc(user.uid).collection("notes");

    final bookmarkSnapshot = await bookmarkRef.get();
    final notesSnapshot = await notesRef.get();

    List<Map<String, dynamic>> fetchedBookmarks = bookmarkSnapshot.docs
        .map((doc) => {
              "surah": doc['surah'],
              "ayah": doc['ayah'],
              "id": doc.id,
            })
        .toList();

    List<Map<String, dynamic>> fetchedNotes = notesSnapshot.docs
        .map((doc) => {
              "surah": doc['surah'],
              "ayah": doc['ayah'],
              "note": doc['note'],
              "id": doc.id,
            })
        .toList();

    setState(() {
      bookmarks = fetchedBookmarks;
      notes = fetchedNotes;
    });

    await fetchSurahNames();
  }

  Future<void> fetchSurahNames() async {
    for (var bookmark in bookmarks) {
      int surahNumber = bookmark['surah'];
      if (!surahNames.containsKey(surahNumber)) {
        final response = await http.get(
          Uri.parse('https://equran.id/api/v2/surat/$surahNumber'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            surahNames[surahNumber] = data['data']['namaLatin'];
          });
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void deleteBookmark(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("bookmarks")
        .doc(id)
        .delete();

    setState(() {
      bookmarks.removeWhere((bookmark) => bookmark["id"] == id);
    });
  }

  void deleteNote(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("notes")
        .doc(id)
        .delete();

    setState(() {
      notes.removeWhere((note) => note["id"] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookmarks & Notes"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.bookmark), text: "Bookmarks"),
            Tab(icon: Icon(Icons.note), text: "Notes"),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                bookmarks.isEmpty
                    ? Center(child: Text("No bookmarks saved."))
                    : ListView.builder(
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          String surahName =
                              surahNames[bookmark['surah']] ?? "Loading...";
                          int surahNumber = bookmark['surah'];
                          int ayahNumber = bookmark['ayah'];

                          return ListTile(
                            title: Text("$surahName $surahNumber:$ayahNumber"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteBookmark(bookmark["id"]),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SubHomeScreen(surahNumber: surahNumber),
                                ),
                              );
                            },
                          );
                        },
                      ),
                notes.isEmpty
                    ? Center(child: Text("No notes saved."))
                    : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          String surahName =
                              surahNames[note['surah']] ?? "Loading...";
                          int surahNumber = note['surah'];
                          int ayahNumber = note['ayah'];
                          return ListTile(
                            title: Text("$surahName $surahNumber:$ayahNumber"),
                            subtitle: Text(note['note']),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteNote(note["id"]),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SubHomeScreen(surahNumber: surahNumber),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
    );
  }
}

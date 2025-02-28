import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_mobile/screens/sub_home.dart';
import 'dart:convert';

import 'package:quran_mobile/widgets/alert_dialog.dart';

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
    _tabController.addListener(() {
      setState(() {});
    });
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
    Set<int> allSurahNumbers = {};

    for (var bookmark in bookmarks) {
      allSurahNumbers.add(bookmark['surah']);
    }

    for (var note in notes) {
      allSurahNumbers.add(note['surah']);
    }

    for (int surahNumber in allSurahNumbers) {
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

  void deleteBookmark(BuildContext context, String id) {
    showCustomAlertDialog(
      context,
      "Confirm Deletion",
      "Are you sure you want to delete this bookmark?",
      onConfirm: () async {
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

        showSuccessAlert(context, "Bookmark has been deleted.");
      },
    );
  }

  void deleteNote(BuildContext context, String id) {
    showCustomAlertDialog(
      context,
      "Confirm Deletion",
      "Are you sure you want to delete this note?",
      onConfirm: () async {
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

        showSuccessAlert(context, "Note has been deleted.");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: 100,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            title: Text(
              "Bookmarks & Notes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                fontSize: 16,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.green,
                  labelColor: Colors.green,
                  tabs: const [
                    Tab(text: "Bookmarks"),
                    Tab(text: "Notes"),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            SliverFillRemaining(
              child:
                  Center(child: CircularProgressIndicator(color: Colors.green)),
            )
          else
            _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return _tabController.index == 0
        ? _buildSliverBookmarkList()
        : _buildSliverNotesList();
  }

  Widget _buildSliverBookmarkList() {
    return bookmarks.isEmpty
        ? SliverFillRemaining(
            child: Center(child: Text("No bookmarks saved.")),
          )
        : SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bookmark = bookmarks[index];
                  String surahName = surahNames[bookmark['surah']] ?? "-";
                  int surahNumber = bookmark['surah'];
                  int ayahNumber = bookmark['ayah'];

                  return _buildTranslucentCard(
                    title: "$surahName $surahNumber:$ayahNumber",
                    onDelete: () => deleteBookmark(context, bookmark["id"]),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubHomeScreen(
                            surahNumber: surahNumber,
                            ayahNumber: ayahNumber,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: bookmarks.length,
              ),
            ),
          );
  }

  Widget _buildSliverNotesList() {
    return notes.isEmpty
        ? SliverFillRemaining(
            child: Center(child: Text("No notes saved.")),
          )
        : SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = notes[index];
                  String surahName = surahNames[note['surah']] ?? "-";
                  int surahNumber = note['surah'];
                  int ayahNumber = note['ayah'];

                  return _buildTranslucentCard(
                    title: "$surahName $surahNumber:$ayahNumber",
                    subtitle: note['note'],
                    onDelete: () => deleteNote(context, note["id"]),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubHomeScreen(
                            surahNumber: surahNumber,
                            ayahNumber: ayahNumber,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: notes.length,
              ),
            ),
          );
  }

  Widget _buildTranslucentCard({
    required String title,
    String? subtitle,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green[300]!, Colors.green[100]!],
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
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: subtitle != null && subtitle.isNotEmpty
              ? Row(
                  children: [
                    Icon(
                      CupertinoIcons.news,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : null,
          trailing: IconButton(
            icon: Icon(CupertinoIcons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

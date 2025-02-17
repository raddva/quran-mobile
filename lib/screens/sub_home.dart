import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class SubHomeScreen extends StatefulWidget {
  final int surahNumber;

  const SubHomeScreen({super.key, required this.surahNumber});

  @override
  State<SubHomeScreen> createState() => _SubHomeScreenState();
}

class _SubHomeScreenState extends State<SubHomeScreen> {
  Map<String, dynamic>? surahDetail;
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Set<int> bookmarkedAyahs = {};
  Map<int, String> ayahNotes = {};

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    fetchSurahDetails();
    fetchBookmarks();
    fetchNotes();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchSurahDetails() async {
    final response = await http
        .get(Uri.parse('https://equran.id/api/v2/surat/${widget.surahNumber}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        surahDetail = data['data'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load Surah details');
    }
  }

  void playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.resume();
    } catch (e) {
      print("Error playing audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing audio")),
      );
    }
  }

  Future<void> fetchBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookmarkRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("bookmarks");

    final querySnapshot =
        await bookmarkRef.where("surah", isEqualTo: widget.surahNumber).get();

    setState(() {
      bookmarkedAyahs =
          querySnapshot.docs.map((doc) => doc['ayah'] as int).toSet();
    });
  }

  Future<void> fetchNotes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notesRef =
        _firestore.collection("users").doc(user.uid).collection("notes");

    final querySnapshot =
        await notesRef.where("surah", isEqualTo: widget.surahNumber).get();

    setState(() {
      ayahNotes = {
        for (var doc in querySnapshot.docs)
          doc['ayah'] as int: doc['note'] as String
      };
    });
  }

  void toggleBookmark(int ayahNumber) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookmarkRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("bookmarks")
        .where("surah", isEqualTo: widget.surahNumber)
        .where("ayah", isEqualTo: ayahNumber);

    final querySnapshot = await bookmarkRef.get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("bookmarks")
          .doc(docId)
          .delete();

      setState(() {
        bookmarkedAyahs.remove(ayahNumber);
      });
    } else {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("bookmarks")
          .add({
        "surah": widget.surahNumber,
        "ayah": ayahNumber,
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() {
        bookmarkedAyahs.add(ayahNumber);
      });
    }
  }

  Future<void> addNotes(int ayahNumber) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String existingNote = ayahNotes[ayahNumber] ?? "";
    TextEditingController noteController =
        TextEditingController(text: existingNote);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add/Edit Note"),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(hintText: "Enter your note"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final notesRef = _firestore
                  .collection("users")
                  .doc(user.uid)
                  .collection("notes")
                  .where("surah", isEqualTo: widget.surahNumber)
                  .where("ayah", isEqualTo: ayahNumber);

              final querySnapshot = await notesRef.get();

              if (querySnapshot.docs.isNotEmpty) {
                final docId = querySnapshot.docs.first.id;

                if (noteController.text.isEmpty) {
                  await _firestore
                      .collection("users")
                      .doc(user.uid)
                      .collection("notes")
                      .doc(docId)
                      .delete();

                  setState(() {
                    ayahNotes.remove(ayahNumber);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Note removed for Ayah $ayahNumber")));
                } else {
                  await _firestore
                      .collection("users")
                      .doc(user.uid)
                      .collection("notes")
                      .doc(docId)
                      .update({
                    "note": noteController.text,
                    "timestamp": FieldValue.serverTimestamp(),
                  });

                  setState(() {
                    ayahNotes[ayahNumber] = noteController.text;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Note updated for Ayah $ayahNumber")));
                }
              } else {
                if (noteController.text.isNotEmpty) {
                  await _firestore
                      .collection("users")
                      .doc(user.uid)
                      .collection("notes")
                      .add({
                    "surah": widget.surahNumber,
                    "ayah": ayahNumber,
                    "note": noteController.text,
                    "timestamp": FieldValue.serverTimestamp(),
                  });

                  setState(() {
                    ayahNotes[ayahNumber] = noteController.text;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Note added for Ayah $ayahNumber")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text("Note cannot be empty for Ayah $ayahNumber")));
                }
              }

              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[50],
        title: Text(
          surahDetail?['namaLatin'] ?? 'Loading...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.info),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.0)),
                ),
                backgroundColor: Colors.white,
                isScrollControlled: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Text(
                            "${surahDetail?['namaLatin']} - ${surahDetail?['arti']}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 5),
                          Text(
                            "(${surahDetail?['jumlahAyat']} Ayat)",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Divider(),
                          SizedBox(height: 10),
                          Html(
                            data: surahDetail?['deskripsi'] ??
                                "No description available.",
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '${surahDetail?['nama']}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: surahDetail?['ayat']?.length ?? 0,
                      itemBuilder: (context, index) {
                        var ayat = surahDetail?['ayat'][index];
                        int ayahNumber = ayat['nomorAyat'];

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${ayat['teksArab']}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Amiri',
                                    color: Colors.green[800],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  ayat['teksLatin'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  ayat['teksIndonesia'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // IconButton(
                                        //   icon: Icon(Icons.play_arrow,
                                        //       color: Colors.green),
                                        //   onPressed: () {
                                        //     String? audioUrl =
                                        //         ayat['audio']['01'];
                                        //     if (audioUrl != null &&
                                        //         audioUrl.isNotEmpty) {
                                        //       playAudio(audioUrl);
                                        //     } else {
                                        //       ScaffoldMessenger.of(context)
                                        //           .showSnackBar(
                                        //         SnackBar(
                                        //           content: Text(
                                        //               "Audio not available for this Ayah"),
                                        //         ),
                                        //       );
                                        //     }
                                        //   },
                                        // ),
                                        IconButton(
                                          icon: Icon(
                                            bookmarkedAyahs.contains(ayahNumber)
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: bookmarkedAyahs
                                                    .contains(ayahNumber)
                                                ? Colors.green
                                                : null,
                                          ),
                                          onPressed: () {
                                            // Toggle Bookmark Function
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_note,
                                              color: Colors.green),
                                          onPressed: () {
                                            // Add Note Function
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

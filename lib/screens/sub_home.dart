import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    fetchSurahDetails();
    fetchBookmarks();
    fetchNotes();
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
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> fetchBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookmarkRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("bookmarks");

    final querySnapshot = await bookmarkRef.get();

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

    final querySnapshot = await notesRef.get();

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
        .doc('$ayahNumber');

    final doc = await bookmarkRef.get();

    if (doc.exists) {
      await bookmarkRef.delete();
      bookmarkedAyahs.remove(ayahNumber);
    } else {
      await bookmarkRef.set({
        "surah": widget.surahNumber,
        "ayah": ayahNumber,
        "timestamp": FieldValue.serverTimestamp(),
      });
      bookmarkedAyahs.add(ayahNumber);
    }

    setState(() {});
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
                  .doc('$ayahNumber');

              if (noteController.text.isEmpty) {
                await notesRef.delete();
                ayahNotes.remove(ayahNumber);
              } else {
                await notesRef.set({
                  "surah": widget.surahNumber,
                  "ayah": ayahNumber,
                  "note": noteController.text,
                  "timestamp": FieldValue.serverTimestamp(),
                });
                ayahNotes[ayahNumber] = noteController.text;
              }

              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Note saved for Ayah $ayahNumber")));
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
      appBar: AppBar(title: Text(surahDetail?['namaLatin'] ?? 'Loading...')),
      body: isLoading
          ? Center(child: LinearProgressIndicator())
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
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      '${surahDetail?['namaLatin']} - ${surahDetail?['arti']} (${surahDetail?['jumlahAyat']})',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(height: 10),
                  Html(
                    data: surahDetail?['deskripsi'] ??
                        "No description available.",
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: surahDetail?['ayat']?.length ?? 0,
                      itemBuilder: (context, index) {
                        var ayat = surahDetail?['ayat'][index];
                        int ayahNumber = ayat['nomorAyat'];

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$ayahNumber. ${ayat['teksArab']}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Amiri',
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
                                        IconButton(
                                          icon: Icon(Icons.play_arrow),
                                          onPressed: () {
                                            playAudio(ayat['audio']['01']);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            bookmarkedAyahs.contains(ayahNumber)
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: bookmarkedAyahs
                                                    .contains(ayahNumber)
                                                ? Colors.blue
                                                : null,
                                          ),
                                          onPressed: () {
                                            toggleBookmark(ayahNumber);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_note),
                                          onPressed: () {
                                            addNotes(ayahNumber);
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

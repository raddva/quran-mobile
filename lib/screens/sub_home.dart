import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:expandable/expandable.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';

class SubHomeScreen extends StatefulWidget {
  final int surahNumber;
  final int? ayahNumber;

  const SubHomeScreen({super.key, required this.surahNumber, this.ayahNumber});

  @override
  State<SubHomeScreen> createState() => _SubHomeScreenState();
}

class _SubHomeScreenState extends State<SubHomeScreen> {
  Map<String, dynamic>? surahDetail;
  bool isLoading = true;

  final AudioPlayer _audioPlayer = AudioPlayer();

  final ScrollController _scrollController = ScrollController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? playingAyahNumber;
  PlayerState _playerState = PlayerState.stopped;

  Set<int> bookmarkedAyahs = {};
  Map<int, String> ayahNotes = {};
  Map<int, GlobalKey> ayahKeys = {};

  String convertToArabicNumber(int number) {
    final arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicDigits[int.parse(digit)])
        .join();
  }

  void playAudio(String url, int ayahNumber) async {
    if (kIsWeb) {
      html.AudioElement audioElement = html.AudioElement(url);
      audioElement.play();
      setState(() {
        playingAyahNumber = ayahNumber;
        _playerState = PlayerState.playing;
      });

      audioElement.onEnded.listen((event) {
        setState(() {
          playingAyahNumber = null;
          _playerState = PlayerState.stopped;
        });
      });
    } else {
      if (playingAyahNumber == ayahNumber &&
          _playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setSourceUrl(url);
        await _audioPlayer.resume();
        setState(() {
          playingAyahNumber = ayahNumber;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSurahDetails().then((_) {
      if (widget.ayahNumber != null) {
        Future.delayed(Duration(milliseconds: 100), () {
          navigateToAyah(widget.ayahNumber!);
        });
      }
    });
    fetchBookmarks();
    fetchNotes();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _playerState = state;
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          playingAyahNumber = null;
        }
      });
    });
  }

  void navigateToAyah(int ayahNumber) {
    if (surahDetail == null || surahDetail!['ayat'] == null) return;

    int newPage = ((ayahNumber - 1) ~/ itemsPerPage) + 1;

    setState(() {
      currentPage = newPage;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToAyah(ayahNumber);
      });
    });
  }

  void scrollToAyah(int ayahNumber) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (!ayahKeys.containsKey(ayahNumber)) return;
      final key = ayahKeys[ayahNumber];

      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      } else {
        debugPrint("Ayah key $ayahNumber not found");
      }
    });
  }

  @override
  void dispose() {
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

      showSuccessAlert(context, "Bookmark removed successfully");
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

      showSuccessAlert(context, "Bookmark added successfully");
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
              String message = "";

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

                  message = "Note removed for Ayah $ayahNumber";
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

                  message = "Note updated for Ayah $ayahNumber";
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

                  message = "Note added for Ayah $ayahNumber";
                } else {
                  showCustomAlertDialog(
                      context, "Failed", "Note can't be empty");
                  return;
                }
              }
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  int currentPage = 1;
  final int itemsPerPage = 5;
  final int maxVisiblePages = 5;

  List<dynamic> getCurrentAyahs() {
    if (surahDetail == null || surahDetail!['ayat'] == null) return [];
    int startAyah = (currentPage - 1) * itemsPerPage + 1;
    int endAyah = startAyah + itemsPerPage;
    return surahDetail!['ayat']
        .where((ayat) =>
            ayat['nomorAyat'] >= startAyah && ayat['nomorAyat'] < endAyah)
        .toList();
  }

  void changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = ((surahDetail?['jumlahAyat'] ?? 1) / itemsPerPage).ceil();
    int startPage = (currentPage - 1) ~/ maxVisiblePages * maxVisiblePages + 1;
    int endPage = (startPage + maxVisiblePages - 1).clamp(1, totalPages);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text(
          surahDetail?['namaLatin'] ?? 'Loading...',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.info, color: Colors.white),
            tooltip: "Details",
            onPressed: () => showSurahDetails(),
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
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: getCurrentAyahs().length,
                      itemBuilder: (context, index) {
                        var ayat = getCurrentAyahs()[index];
                        int ayahNumber = ayat['nomorAyat'];
                        ayahKeys[ayahNumber] = GlobalKey();
                        String? audioUrl = ayat['audio']['01'];

                        return Card(
                          key: ayahKeys[ayahNumber],
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    '${ayat['teksArab']} (${convertToArabicNumber(ayahNumber)})',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontFamily: 'Amiri',
                                      color: Colors.green[900],
                                      height: 1.8,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  ayat['teksLatin'],
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 10),
                                ExpandablePanel(
                                  header: Text("Terjemahan:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  collapsed: Text(
                                    ayat['teksIndonesia'],
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  expanded: Text(
                                    ayat['teksIndonesia'],
                                    softWrap: true,
                                  ),
                                  theme: ExpandableThemeData(
                                    tapHeaderToExpand: true,
                                    tapBodyToCollapse: true,
                                    headerAlignment:
                                        ExpandablePanelHeaderAlignment.center,
                                    hasIcon: true,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            (playingAyahNumber == ayahNumber &&
                                                    _playerState ==
                                                        PlayerState.playing)
                                                ? CupertinoIcons.pause_fill
                                                : CupertinoIcons.play_fill,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            if (audioUrl != null &&
                                                audioUrl.isNotEmpty) {
                                              playAudio(audioUrl, ayahNumber);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        "Audio unavailable")),
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            bookmarkedAyahs.contains(ayahNumber)
                                                ? CupertinoIcons.bookmark_fill
                                                : CupertinoIcons.bookmark,
                                            color: bookmarkedAyahs
                                                    .contains(ayahNumber)
                                                ? Colors.green
                                                : null,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            toggleBookmark(ayahNumber);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            CupertinoIcons.square_pencil_fill,
                                            color: Colors.green,
                                            size: 20,
                                          ),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (startPage > 1)
                          IconButton(
                            onPressed: () => changePage(startPage - 1),
                            icon: Icon(CupertinoIcons.chevron_back),
                            color: Colors.green,
                          ),
                        ...List.generate(endPage - startPage + 1, (index) {
                          int pageNumber = startPage + index;
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            child: ElevatedButton(
                              onPressed: () => changePage(pageNumber),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (currentPage == pageNumber)
                                    ? Colors.green
                                    : Colors.white,
                                foregroundColor: (currentPage == pageNumber)
                                    ? Colors.white
                                    : Colors.green,
                                shape: const CircleBorder(),
                              ),
                              child: Text("$pageNumber"),
                            ),
                          );
                        }),
                        if (endPage < totalPages)
                          IconButton(
                            onPressed: () => changePage(endPage + 1),
                            icon: Icon(CupertinoIcons.chevron_forward),
                            color: Colors.green,
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  void showSurahDetails() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      backgroundColor: Colors.white,
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
                  data:
                      surahDetail?['deskripsi'] ?? "No description available.",
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

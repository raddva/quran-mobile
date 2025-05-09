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
import 'package:quran_mobile/utils/functions.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';

html.AudioElement? _webAudioElement;

class SubHomeScreen extends StatefulWidget {
  final int surahNumber;
  final int? ayahNumber;
  final String? plannerId;

  const SubHomeScreen({
    super.key,
    required this.surahNumber,
    this.ayahNumber,
    this.plannerId,
  });

  @override
  State<SubHomeScreen> createState() => _SubHomeScreenState();
}

class _SubHomeScreenState extends State<SubHomeScreen> {
  Map<String, dynamic>? surahDetail;
  bool isLoading = true;
  Map<String, dynamic>? plannerData;
  List<Map<String, dynamic>> surahList = [];

  final AudioPlayer _audioPlayer = AudioPlayer();

  final ScrollController _scrollController = ScrollController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? playingAyahNumber;
  PlayerState _playerState = PlayerState.stopped;

  Set<int> bookmarkedAyahs = {};
  Map<int, String> ayahNotes = {};
  Map<int, GlobalKey> ayahKeys = {};

  void playAudio(String url, int ayahNumber) async {
    if (kIsWeb) {
      if (_webAudioElement != null) {
        _webAudioElement!.pause();
        _webAudioElement!.src = "";
        _webAudioElement = null;
      }

      if (playingAyahNumber == ayahNumber) {
        setState(() {
          playingAyahNumber = null;
          _playerState = PlayerState.stopped;
        });
        return;
      }

      _webAudioElement = html.AudioElement(url)
        ..play()
        ..onEnded.listen((event) {
          setState(() {
            playingAyahNumber = null;
            _playerState = PlayerState.stopped;
            _webAudioElement = null;
          });
        });

      setState(() {
        playingAyahNumber = ayahNumber;
        _playerState = PlayerState.playing;
      });
    } else {
      if (playingAyahNumber == ayahNumber) {
        if (_playerState == PlayerState.playing) {
          await _audioPlayer.pause();
          setState(() => _playerState = PlayerState.paused);
        } else {
          await _audioPlayer.resume();
          setState(() => _playerState = PlayerState.playing);
        }
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.resume();

      setState(() {
        playingAyahNumber = ayahNumber;
        _playerState = PlayerState.playing;
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          playingAyahNumber = null;
          _playerState = PlayerState.stopped;
        });
      });
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
    fetchSurahs();

    fetchBookmarks();
    fetchNotes();
    fetchPlannerData();

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

  Future<void> fetchSurahs() async {
    try {
      final response =
          await http.get(Uri.parse("https://equran.id/api/v2/surat"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["data"] is List) {
          setState(() {
            surahList = List<Map<String, dynamic>>.from(data["data"]);
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load Surahs");
      }
    } catch (e) {
      print("Error fetching Surahs: $e");
      setState(() => isLoading = false);
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

  Future<void> fetchPlannerData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("planner")
          .doc(widget.plannerId)
          .get();

      if (doc.exists) {
        plannerData = doc.data();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
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

  Future<void> logTracker(
      List<dynamic> ayahs, String status, String? plannerId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    bool allLogged = true;

    try {
      for (var ayah in ayahs) {
        int ayahNumber = ayah['nomorAyat'];

        var query = _firestore
            .collection("users")
            .doc(user.uid)
            .collection("tracker")
            .where("surah_id", isEqualTo: widget.surahNumber)
            .where("ayah_id", isEqualTo: ayahNumber)
            .where("status", isEqualTo: status);

        if (plannerId != null) {
          query = query.where("planner_id", isEqualTo: plannerId);
        } else {
          query = query.where("planner_id", isNull: true);
        }

        var existingAyah = await query.get();

        if (existingAyah.docs.isNotEmpty) {
          continue;
        }

        allLogged = false;

        Map<String, dynamic> trackerData = {
          "user_id": user.uid,
          "surah_id": widget.surahNumber,
          "ayah_id": ayahNumber,
          "completed_at": FieldValue.serverTimestamp(),
          "status": status,
        };

        if (plannerId != null) {
          trackerData["planner_id"] = plannerId;
        }

        await _firestore
            .collection("users")
            .doc(user.uid)
            .collection("tracker")
            .add(trackerData);
      }

      if (allLogged) {
        showCustomAlertDialog(context, "Info", "This page is already logged.");
        return;
      }

      if (status == "planner" && plannerId != null) {
        await updatePlannerProgress(plannerId);
      }

      showSuccessAlert(context, "Saved Successfully!");
    } catch (e) {
      showCustomAlertDialog(context, "Error", "Failed to log ayahs: $e");
    }
  }

  Future<void> updatePlannerProgress(String plannerId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final plannerDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("planner")
          .doc(plannerId)
          .get();

      if (!plannerDoc.exists) return;

      final plannerData = plannerDoc.data();
      if (plannerData == null) return;

      int fromSurah = plannerData["from_surah"];
      int fromAyah = plannerData["from_ayah"];
      int toSurah = plannerData["to_surah"];
      int toAyah = plannerData["to_ayah"];

      int totalAyahs = calculateAyahCount(fromSurah, fromAyah, toSurah, toAyah);

      final trackerSnap = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("tracker")
          .where("planner_id", isEqualTo: plannerId)
          .where("status", isEqualTo: "planner")
          .get();

      int completedCount = trackerSnap.docs.length;
      double progress = (completedCount / totalAyahs * 100);

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("planner")
          .doc(plannerId)
          .update({"progress": progress});
    } catch (e) {
      print("Error updating planner progress: $e");
    }
  }

  int calculateAyahCount(int fromSurah, int fromAyah, int toSurah, int toAyah) {
    int count = 0;

    if (surahList.isEmpty) return count;

    if (fromSurah == toSurah) {
      return toAyah - fromAyah + 1;
    }

    for (int i = fromSurah; i <= toSurah; i++) {
      int ayahCount = surahList[i - 1]["jumlahAyat"];

      if (i == fromSurah) {
        count += (ayahCount - fromAyah + 1);
      } else if (i == toSurah) {
        count += toAyah;
      } else {
        count += ayahCount;
      }
    }

    return count;
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

  List<Map<String, dynamic>> getCurrentPlannerPageAyahs() {
    if (surahDetail == null || plannerData == null) return [];

    int plannerFrom = plannerData!['from_ayah'];
    int plannerTo = plannerData!['to_ayah'];

    int pageFrom = (currentPage - 1) * itemsPerPage + 1;
    int pageTo = pageFrom + itemsPerPage - 1;

    final List<Map<String, dynamic>> ayatList =
        List<Map<String, dynamic>>.from(surahDetail!['ayat']);

    return ayatList.where((ayat) {
      int ayahNum = ayat['nomorAyat'];
      return ayahNum >= plannerFrom &&
          ayahNum <= plannerTo &&
          ayahNum >= pageFrom &&
          ayahNum <= pageTo;
    }).toList();
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                surahDetail?['namaLatin'] ?? 'Loading...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                CupertinoIcons.checkmark_alt_circle,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => logTracker(getCurrentAyahs(), "tracker", null),
              tooltip: "Mark Page as Completed",
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.plannerId != null)
            IconButton(
              icon: Icon(
                CupertinoIcons.text_badge_checkmark,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () => logTracker(
                  getCurrentPlannerPageAyahs(), "planner", widget.plannerId),
              tooltip: "Log to Planner",
            ),
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

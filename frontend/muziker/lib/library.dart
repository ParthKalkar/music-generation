import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'audio_player_widget.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String searchQuery = "";
  List<Map<String, dynamic>> musicList = [];
  bool showLikedOnly = false;
  User? _firebaseUser = FirebaseAuth.instance.currentUser;
  AudioPlayerWidget? _audioPlayerWidget;

  @override
  void initState() {
    super.initState();
    fetchMusicList();
  }

  Future<void> fetchMusicList() async {
    if (_firebaseUser != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('musics')
          .where('uid', isEqualTo: _firebaseUser!.uid)
          .get();

      setState(() {
        musicList = querySnapshot.docs
            .map((doc) => {
          'id': doc.id,
          'name': doc['name'],
          'uri': doc['uri'],
          'isLiked': doc['isLiked'] ?? false,
        })
            .toList();
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  List<Map<String, dynamic>> get filteredMusicList {
    var list = musicList;
    if (searchQuery.isNotEmpty) {
      list = list
          .where((music) =>
          music['name'].toLowerCase().contains(searchQuery))
          .toList();
    }
    if (showLikedOnly) {
      list = list.where((music) => music['isLiked'] == true).toList();
    }
    return list;
  }

  void _onMusicTap(String uri) {
    setState(() {
      _audioPlayerWidget = AudioPlayerWidget(url: uri);
    });
  }

  void _toggleLike(String id, bool isLiked) async {
    await FirebaseFirestore.instance.collection('musics').doc(id).update({
      'isLiked': !isLiked,
    });
    fetchMusicList();
  }

  void _toggleFilter() {
    setState(() {
      showLikedOnly = !showLikedOnly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
        actions: [
          IconButton(
            icon: Icon(showLikedOnly ? Icons.favorite : Icons.menu),
            onPressed: _toggleFilter, // Toggle filter for liked musics
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "What kind of music will you make?",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMusicList.length,
              itemBuilder: (context, index) {
                final music = filteredMusicList[index];
                return ListTile(
                  leading: Icon(Icons.music_note, color: Colors.purpleAccent),
                  title: Text(music['name'],
                      style: TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: Icon(
                      music['isLiked']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.purpleAccent,
                    ),
                    onPressed: () => _toggleLike(music['id'], music['isLiked']),
                  ),
                  onTap: () => _onMusicTap(music['uri']),
                );
              },
            ),
          ),
          if (_audioPlayerWidget != null)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF240046),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: _audioPlayerWidget!,
            ),
        ],
      ),
    );
  }
}

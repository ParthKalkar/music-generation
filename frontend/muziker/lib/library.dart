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
          'name': doc['name'],
          'uri': doc['uri'],
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
    if (searchQuery.isEmpty) {
      return musicList;
    } else {
      return musicList
          .where((music) =>
          music['name'].toLowerCase().contains(searchQuery))
          .toList();
    }
  }

  void _onMusicTap(String uri) {
    setState(() {
      _audioPlayerWidget = AudioPlayerWidget(url: uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search your music:",
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
            child: filteredMusicList.length > 0 ? ListView.builder(
              itemCount: filteredMusicList.length,
              itemBuilder: (context, index) {
                final music = filteredMusicList[index];
                return ListTile(
                  leading: Icon(Icons.music_note, color: Colors.purpleAccent),
                  title: Text(music['name'],
                      style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.favorite_border,
                      color: Colors.purpleAccent),
                  onTap: () => _onMusicTap(music['uri']),
                );
              },
            ):
            const Center(child: Text("You haven't created anything yet!"),)
          ),
          if (_audioPlayerWidget != null)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF240046), // Slightly lighter background for the player controls
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

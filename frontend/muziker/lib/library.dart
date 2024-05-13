import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(// Dark background from the theme
      appBar: AppBar(
        title: Text('Library'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {}, // Placeholder for menu button action
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
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.music_note, color: Colors.purpleAccent),
                  title: Text('Sunset Vibes, Latin', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.favorite_border, color: Colors.purpleAccent),
                ),
                ListTile(
                  leading: Icon(Icons.music_note, color: Colors.purpleAccent),
                  title: Text('More Drums', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.favorite_border, color: Colors.purpleAccent),
                ),
                ListTile(
                  leading: Icon(Icons.music_note, color: Colors.purpleAccent),
                  title: Text('Smoother, more synths', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.favorite_border, color: Colors.purpleAccent),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF240046), // Slightly lighter background for the player controls
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.skip_previous, color: Colors.purpleAccent, size: 36),
                Icon(Icons.play_arrow, color: Colors.purpleAccent, size: 36),
                Icon(Icons.skip_next, color: Colors.purpleAccent, size: 36),
                // Include a custom icon for music wave here
                Container(
                  height: 50,
                  width: 50,
                  child: Image.asset('assets/music_wave_icon.png'), // Your icon file
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

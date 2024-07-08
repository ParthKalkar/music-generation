import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'chat.dart';
import 'settings.dart';
import 'library.dart';
import 'login.dart'; // Assuming this is the login page file

class HomePage extends StatelessWidget {
  final bool isOffline;

  const HomePage({Key? key, this.isOffline = false}) : super(key: key);

  final double buttonWidth = 200.0;  // Define a standard width for all buttons
  final double buttonHeight = 80.0;  // Define a standard height for all buttons

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.95;
    return Scaffold(
      body: Stack(
        children: [
          // Add the background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/music_notes_pattern.jpg', // Add your pattern image asset
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image.asset('assets/logo.png', height: 200),  // Adjust size as necessary
                ),
                if (!isOffline)
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                      },
                      child: const Text(
                        'Generate',
                        style: TextStyle(fontSize: 16),  // Larger text size
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4D057A),  // Set uniform color
                        foregroundColor: Colors.white,  // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),  // Rounded corners
                        ),
                        elevation: 10,  // Shadow elevation
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryPage()));
                    },
                    child: const Text(
                      'Library',
                      style: TextStyle(fontSize: 16),  // Larger text size
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4D057A),  // Set uniform color
                      foregroundColor: Colors.white,  // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),  // Rounded corners
                      ),
                      elevation: 10,  // Shadow elevation
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(isOffline: isOffline)));
                    },
                    icon: Icon(Icons.settings, size: 20),  // Larger icon size
                    label: const Text(''),  // No text
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4D057A),  // Set uniform color
                      foregroundColor: Colors.white,  // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),  // Rounded corners
                      ),
                      elevation: 10,  // Shadow elevation
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color to make it stand out
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, // Shadow color
                    blurRadius: 10.0, // Softening the shadow
                    spreadRadius: 1.0, // Extending the shadow
                    offset: Offset(0.0, 5.0), // Moving the shadow
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.logout, color: Colors.red, size: 30), // Use a visible color
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'chat.dart';
import 'settings.dart';
import 'library.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  final double buttonWidth = 200.0;  // Define a standard width for all buttons
  final double buttonHeight = 80.0;  // Define a standard height for all buttons

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.95 ;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Image.asset('assets/logo.png', height: 200),  // Adjust size as necessary
            ),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
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
    );
  }
}

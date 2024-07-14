import 'package:firebase_auth/firebase_auth.dart';
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
      appBar: AppBar(title: const Text("Home"),
      actions: <Widget>[
        //logout
                IconButton(
                  onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.logout)),

        //settings
                IconButton(onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(isOffline: isOffline,)));               
                  }, 
                  
                icon: const Icon(Icons.settings)),
              ],
      ),
      body: Stack(
        children: [
          // Add the background pattern
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image.asset('assets/Muziker_dark.png', height: 200),  // Adjust size as necessary
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
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}

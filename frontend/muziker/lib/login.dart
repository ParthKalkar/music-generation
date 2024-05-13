import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
const IconData signal_wifi_connected_no_internet_4_rounded = IconData(0xf0187, fontFamily: 'MaterialIcons');
class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  void _goOffline() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        color: Color(0xA6E0AAFF),  // Set a light blue background color
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(height: 40),
            Image.asset('assets/logo.png'),
            SizedBox(height: 20),
            SignInButton(
              Buttons.Google,
              text: "Sign in with Google",
              onPressed: _handleSignIn,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(signal_wifi_connected_no_internet_4_rounded),
              label: Text('Go Offline'),
              onPressed: _goOffline,
            ),
          ],
        ),
      ),
    );
  }
}

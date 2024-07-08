import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'user_login.dart';
import 'register.dart';
import 'home.dart';

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(isOffline: false)));
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  void _goOffline() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(isOffline: true)));
  }

  void _goToUserLogin() {
    Navigator.pushNamed(context, '/userlogin');
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xA6E0AAFF),
              image: DecorationImage(
                image: AssetImage('assets/wave_pattern.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), // Adjust the opacity
                  BlendMode.dstATop,
                ),
              ),
            ),
            width: double.infinity,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 40),
                Image.asset('assets/logo.png'),
                Column(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: SignInButton(
                        Buttons.Google,
                        text: "Sign in with Google",
                        onPressed: _handleSignIn,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 5.0,
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _goToUserLogin,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          textStyle: TextStyle(fontSize: 16),
                          elevation: 5.0,
                        ),
                        child: Text('Login'),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _goToRegister,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          textStyle: TextStyle(fontSize: 16),
                          elevation: 5.0,
                        ),
                        child: Text('Register'),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(signal_wifi_connected_no_internet_4_rounded),
                    label: Text('Go Offline'),
                    onPressed: _goOffline,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      textStyle: TextStyle(fontSize: 16),
                      elevation: 5.0,
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

import 'package:beer_counter/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Sign in stuff
final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

// TODO: silent sign in
Future<FirebaseUser> _handleSignIn() async {
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
  print("signed in " + user.displayName);
  return user;
}

void main() {
  runApp(BeerCounter());
}

class BeerCounter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SignInPage(
        title: "Sign In",
      ),
    );
  }
}

class SignInPage extends StatelessWidget {
  final String title;

  SignInPage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlineButton(
              child: Text('Sign In With Google'),
              onPressed: () => {
                // sign in user and open profile page
                _handleSignIn()
                    .then((FirebaseUser user) =>
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<Null>(
                            builder: (BuildContext context) =>
                                // open [ProfilePage] for given user
                                ProfilePage(user: user),
                          ),
                        ))
                    .catchError((e) => print(e))
              },
            )
          ],
        ),
      ),
    );
  }
}

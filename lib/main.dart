import 'package:beer_counter/firebase/firebase_helper.dart';
import 'package:beer_counter/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseSignInHelper helper = FirebaseSignInHelper();
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
                helper
                    .handleSignIn()
                    .then((FirebaseUser user) => openProfilePage(context, user))
                    .catchError((e) => print(e))
              },
            )
          ],
        ),
      ),
    );
  }
}

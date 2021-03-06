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
        primaryColor: Colors.grey[900],
        accentColor: Colors.amberAccent,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.amberAccent,
          textTheme: ButtonTextTheme.primary,
        ),
        brightness: Brightness.dark,
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

  Future<void> _checkIfSignedIn(context) async {
    FirebaseUser user = await helper.isSignedIn();
    if (user != null) {
      openProfilePage(context, user);
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkIfSignedIn(context);
    final theme = Theme.of(context);
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
              textColor: theme.accentColor,
              color: theme.accentColor,
              highlightedBorderColor: theme.accentColor,
              onPressed: () => {
                // sign in user and open profile page
                helper
                    .handleSignIn()
                    .then((user) => openProfilePage(context, user))
                    .catchError((e) => print(e))
              },
            )
          ],
        ),
      ),
    );
  }
}

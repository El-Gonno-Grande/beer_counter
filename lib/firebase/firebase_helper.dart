import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models.dart';

/// wraps most Firebase interactions into one class
class FirebaseHelper {
  /// database stuff
  DatabaseReference _eventsRef, _beersRef, _usersRef;
  StreamSubscription<Event> _eventsSubscription,
      _beersSubscription,
      _usersSubscription;

  final FirebaseHelperCallback callback;

  FirebaseHelper({this.callback});

  /// should be called in initState()
  void initState() {
    // init and read event
    _eventsRef = FirebaseDatabase.instance.reference().child('events');
    _eventsRef.keepSynced(true);
    _eventsSubscription = _eventsRef.onValue.listen((Event e) =>
        callback.eventsChanged(BeerEvent.fromJsonToList(e.snapshot.value)));
    // init and read beers
    _beersRef = FirebaseDatabase.instance.reference().child('beers');
    _beersRef.keepSynced(true);
    _beersSubscription = _beersRef.onValue.listen((Event e) =>
        callback.beersChanged(Beer.fromJsonToList(e.snapshot.value)));
    // init and read users
    _usersRef = FirebaseDatabase.instance.reference().child('users');
    _usersRef.keepSynced(true);
    _usersSubscription = _usersRef.onValue.listen((Event e) =>
        callback.usersChanged(User.fromJsonToList(e.snapshot.value)));
  }

  /// should be called in dispose()
  void dispose() {
    _eventsSubscription.cancel();
    _beersSubscription.cancel();
    _usersSubscription.cancel();
  }

  /// create a new beer event in database
  Future<void> addBeerEvent(BeerEvent event) async {
    // add event to events in transaction.
    await _addItemToListTransaction(event.toJson(), _eventsRef);
  }

  /// add a new beer to the database
  Future<void> addBeer(Beer beer) async {
    // add beer to beers in transaction.
    await _addItemToListTransaction(beer.toJson(), _beersRef);
  }

  /// remove a beer from the database
  Future<void> removeBeer(Beer beer) async {
    final TransactionResult result =
    await _beersRef.runTransaction((MutableData data) async {
      data.value = data.value != null ? List.from(data.value) : [];
      data.value.removeWhere((e) => beer == Beer.fromJson(e));
      return data;
    });

    if (result.committed) {
      print('Transaction committed.');
    } else {
      print('Transaction not committed.');
      if (result.error != null) {
        print(result.error.message);
      }
    }
  }

  /// add user to participants/drinkers list of an event
  Future<void> joinBeerEvent(String uid, int eventIdx) async {
    _addItemToListTransaction(uid, _eventsRef.child('$eventIdx/drinkers'));
  }

  /// abstract method to append a new item to a list in the database
  static Future<void> _addItemToListTransaction(
      dynamic item, DatabaseReference ref) async {
    // add beer to beers in transaction.
    final TransactionResult result =
        await ref.runTransaction((MutableData data) async {
      data.value = data.value != null ? List.from(data.value) : [];
      data.value.add(item);
      return data;
    });

    if (result.committed) {
      print('Transaction committed.');
    } else {
      print('Transaction not committed.');
      if (result.error != null) {
        print(result.error.message);
      }
    }
  }

  /// abstract method to append a new item to a list in the database
  static Future<void> _removeItemFromListTransaction(
      dynamic item, DatabaseReference ref) async {
    final TransactionResult result =
        await ref.runTransaction((MutableData data) async {
      data.value = data.value != null ? List.from(data.value) : [];
      data.value.remove(item);
      return data;
    });

    if (result.committed) {
      print('Transaction committed.');
    } else {
      print('Transaction not committed.');
      if (result.error != null) {
        print(result.error.message);
      }
    }
  }
}

abstract class FirebaseHelperCallback {
  /// called when events list was changed
  void eventsChanged(List<BeerEvent> events);

  /// called when beers list was changed
  void beersChanged(List<Beer> beers);

  /// called when users list was changed
  void usersChanged(List<User> users);
}

class FirebaseSignInHelper {
  /// sign in stuff
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TODO: silent sign in
  Future<FirebaseUser> handleSignIn() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    print("signed in " + user.displayName);
    // store user in users list
    DatabaseReference usersRef =
        FirebaseDatabase.instance.reference().child('users');
    DataSnapshot data = await usersRef.once();
    List<User> users = User.fromJsonToList(data.value);
    if (users.where((e) => e.uid == user.uid).length == 0) {
      // create new user
      FirebaseHelper._addItemToListTransaction(
          User(uid: user.uid, name: user.displayName).toJson(), usersRef);
    }

    return user;
  }
}

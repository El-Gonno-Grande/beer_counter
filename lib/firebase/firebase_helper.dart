import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models.dart';

/// wraps most Firebase interactions into one class
class FirebaseHelper {
  /// database stuff
  DatabaseReference _eventsRef, _beersRef;
  StreamSubscription<Event> _eventsSubscription, _beersSubscription;

  final FirebaseCallback callback;

  FirebaseHelper({this.callback});

  /// should be called in initState()
  void initState() {
    // init and read event
    _eventsRef = FirebaseDatabase.instance.reference().child('events');
    _eventsRef.keepSynced(true);
    _eventsSubscription = _eventsRef.onValue.listen((Event e) {
      List<BeerEvent> events = e.snapshot.value == null
          ? []
          : List<BeerEvent>.from(
              e.snapshot.value.map((b) => BeerEvent.fromJson(b)));
      callback.eventsChanged(events);
    });
    // init and read beers
    _beersRef = FirebaseDatabase.instance.reference().child('beers');
    _beersRef.keepSynced(true);
    _beersSubscription = _beersRef.onValue.listen((Event e) {
      List<Beer> beers = e.snapshot.value == null
          ? []
          : List<Beer>.from(e.snapshot.value.map((b) => Beer.fromJson(b)));
      callback.beersChanged(beers);
    });
  }

  /// should be called in dispose()
  void dispose() {
    _eventsSubscription.cancel();
    _beersSubscription.cancel();
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
    // TODO: fix _removeItemFromListTransaction
    // await _removeItemFromListTransaction(beer.toJson(), _beersRef);
  }

  /// add user to participants/drinkers list of an event
  Future<void> joinBeerEvent(String uid, int eventIdx) async {
    _addItemToListTransaction(uid, _eventsRef.child('$eventIdx/drinkers'));
  }

  /// abstract method to append a new item to a list in the database
  Future<void> _addItemToListTransaction(
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
  Future<void> _removeItemFromListTransaction(
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

abstract class FirebaseCallback {
  /// called when events list was changed
  void eventsChanged(List<BeerEvent> events);

  /// called when beers list was changed
  void beersChanged(List<Beer> beers);
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
    return user;
  }
}

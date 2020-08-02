import 'dart:async';

import 'package:beer_counter/beers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class ProfilePage extends StatefulWidget {
  final FirebaseUser user;

  ProfilePage({this.user});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DatabaseReference _eventsRef, _beersRef;
  StreamSubscription<Event> _eventsSubscription, _beersSubscription;

  List<BeerEvent> _events = [];
  List<Beer> _beers = [];

  @override
  void initState() {
    super.initState();
    // init and read event
    _eventsRef = FirebaseDatabase.instance.reference().child('events');
    _eventsRef.keepSynced(true);
    _eventsSubscription = _eventsRef.onValue.listen((Event e) {
      setState(() {
        _events = e.snapshot.value == null
            ? []
            : List<BeerEvent>.from(
                e.snapshot.value.map((b) => BeerEvent.fromJson(b)));
      });
    });
    // init and read beers
    _beersRef = FirebaseDatabase.instance.reference().child('beers');
    _beersRef.keepSynced(true);
    _beersSubscription = _beersRef.onValue.listen((Event e) {
      setState(() {
        _beers = e.snapshot.value == null
            ? []
            : List<Beer>.from(e.snapshot.value.map((b) => Beer.fromJson(b)));
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _eventsSubscription.cancel();
    _beersSubscription.cancel();
  }

  void _createBeerEvent() async {
    // TODO: get Event name with dialog
    String name = 'Test';
    BeerEvent e = BeerEvent(
      name: name,
      participants: [widget.user.uid],
    );

    // add event to events in transaction.
    addItemToListTransaction(e.toJson(), _eventsRef);
  }

  void _addBeer() async {
    // TODO: ask for associated event
    BeerEvent e;
    // TODO: get location
    int lat = 0, lon = 0;
    int timeStamp = new DateTime.now().millisecondsSinceEpoch;
    // TODO: verify beer
    bool verified = false;
    Beer b = Beer(
      uid: widget.user.uid,
      event: e,
      lat: lat,
      lon: lon,
      timeStamp: timeStamp,
      verified: verified,
    );

    // add beer to beers in transaction.
    addItemToListTransaction(b.toJson(), _beersRef);
  }

  void addItemToListTransaction(item, ref) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundImage: NetworkImage(widget.user.photoUrl),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(widget.user.displayName),
              ),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                top: 16,
                right: 8,
                bottom: 8,
              ),
              child: InkWell(
                child: Text(
                  'Total Beer Count: ${_beers.where((b) => b.uid == widget.user.uid).length}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<Null>(
                      builder: (BuildContext context) => BeerPage()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: OutlineButton(
                child: Text('Add Beer'),
                onPressed: _addBeer,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlineButton(
                    child: Text('Create Event'),
                    onPressed: _createBeerEvent,
                  ),
                ),
              ],
            ),
            Flexible(
              child: ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  itemCount: _events.length,
                  itemBuilder: (BuildContext context, int idx) {
                    return Container(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(_events[idx].getName(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                            Visibility(
                              child: OutlineButton(
                                  child: Text('Join'),
                                  onPressed: () => {
                                        // TODO: implement join
                                      }),
                              visible: !_events[idx]
                                  .participants
                                  .contains(widget.user.uid),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ));
  }
}

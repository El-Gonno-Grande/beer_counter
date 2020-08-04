import 'dart:async';

import 'package:beer_counter/beers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:geolocator/geolocator.dart';

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

  /// ask user via a dialog for an event name
  Future<String> _askForBeerEventName() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Beer Event'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  autofocus: true,
                  controller: controller,
                  decoration: InputDecoration(labelText: 'Event Name'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            FlatButton(
                child: const Text('CREATE'),
                onPressed: () {
                  Navigator.pop(context, controller.text);
                })
          ],
        );
      },
    );
  }

  /// create a new beer event in database
  Future<void> _createBeerEvent() async {
    String name = await _askForBeerEventName();
    if (name == null) {
      return;
    }
    BeerEvent e = BeerEvent(
      id: (widget.user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .hashCode
          .toString(),
      name: name,
      drinkers: [], // widget.user.uid
    );

    // add event to events in transaction.
    _addItemToListTransaction(e.toJson(), _eventsRef);
  }

  /// displays dialog to select the beer event to be associated to a new beer
  Future<BeerEvent> _askForBeerEvent() async {
    // find all events where the user is participating/drinking in
    // + (option to not add this beer under an event)
    List<BeerEvent> participatingEvents = [BeerEvent(name: 'No Event')];
    participatingEvents
        .addAll(_events.where((e) => e.drinkers.contains(widget.user.uid)));
    // use Completer to return final selection
    Completer<BeerEvent> completer = Completer<BeerEvent>();
    Picker(
        adapter: PickerDataAdapter<String>(
          pickerdata: participatingEvents.map((e) => e.getName()).toList(),
        ),
        hideHeader: true,
        title: new Text("Please Pick a Beer Event"),
        onCancel: () {
          completer.completeError(null);
        },
        onConfirm: (Picker picker, List<int> value) {
          completer.complete(participatingEvents[value[0]]);
        }).showDialog(context);
    return completer.future;
  }

  /// add a new beer to the database
  Future<void> _addBeer() async {
    // TODO: ask for associated event
    BeerEvent event = await _askForBeerEvent();
    if (event == null) {
      return;
    }
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    // TODO: verify beer
    bool verified = false;
    Beer b = Beer(
      uid: widget.user.uid,
      eventId: event.getId(),
      lat: position.latitude,
      lon: position.longitude,
      timeStamp: timeStamp,
      verified: verified,
    );

    // add beer to beers in transaction.
    _addItemToListTransaction(b.toJson(), _beersRef);
  }

  /// add user to participants/drinkers list of an event
  Future<void> _joinBeerEvent(BeerEvent event) async {
    int idx = _events.indexOf(event);
    _addItemToListTransaction(
        widget.user.uid, _eventsRef.child('$idx/drinkers'));
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
                      builder: (BuildContext context) => BeerPage(
                            beers:
                                _beers.where((e) => e.uid == widget.user.uid).toList(),
                          )),
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
                                  onPressed: () =>
                                      {_joinBeerEvent(_events[idx])}),
                              visible: !_events[idx]
                                  .drinkers
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

import 'dart:async';

import 'package:beer_counter/beers.dart';
import 'package:beer_counter/events.dart';
import 'package:beer_counter/firebase/firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'models.dart';

void openProfilePage(context, user) =>
    Navigator.of(context).pushReplacement(MaterialPageRoute<Null>(
        builder: (BuildContext context) => ProfilePage(user: user)));

class ProfilePage extends StatefulWidget {
  final FirebaseUser user;

  ProfilePage({this.user});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    implements FirebaseHelperCallback {
  List<BeerEvent> events = [];
  List<Beer> beers = [];

  FirebaseHelper helper;

  _ProfilePageState() {
    helper = FirebaseHelper(callback: this);
  }

  @override
  void eventsChanged(List<BeerEvent> events) =>
      setState(() => {this.events = events});

  @override
  void beersChanged(List<Beer> beers) => setState(() => {this.beers = beers});

  @override
  void usersChanged(List<User> users) {}

  @override
  void initState() {
    super.initState();
    helper.initState();
  }

  @override
  void dispose() {
    super.dispose();
    helper.dispose();
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
    BeerEvent event = BeerEvent(
      id: (widget.user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .hashCode
          .toString(),
      name: name,
      drinkers: [widget.user.uid],
    );
    helper.addBeerEvent(event);
  }

  /// displays dialog to select the beer event to be associated to a new beer
  Future<BeerEvent> _askForBeerEvent() async {
    // find all events where the user is participating/drinking in
    // + (option to not add this beer under an event)
    List<BeerEvent> participatingEvents = [BeerEvent(name: 'No Event')];
    participatingEvents
        .addAll(events.where((e) => e.drinkers.contains(widget.user.uid)));
    // use Completer to return final selection
    Completer<BeerEvent> completer = Completer<BeerEvent>();
    Picker(
        adapter: PickerDataAdapter<String>(
          pickerdata: participatingEvents.map((e) => e.name).toList(),
        ),
        hideHeader: true,
        title: new Text("Please Pick a Beer Event"),
        onCancel: () {
          completer.completeError(BeerEvent());
        },
        onConfirm: (Picker picker, List<int> value) {
          completer.complete(participatingEvents[value[0]]);
        }).showDialog(context);
    return completer.future;
  }

  Future<void> _addBeer() async {
    BeerEvent event = await _askForBeerEvent();
    if (event.id == null) {
      return;
    }
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    // TODO: verify beer
    bool verified = false;
    Beer beer = Beer(
      uid: widget.user.uid,
      eventId: event.id,
      lat: position.latitude,
      lon: position.longitude,
      timeStamp: timeStamp,
      verified: verified,
    );
    helper.addBeer(beer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  'Beer Count: ${beers.where((b) => b.uid == widget.user.uid).length}',
                  style: theme.textTheme.headline3,
                ),
                onTap: () => openBeersPage(context, widget.user),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: RaisedButton(
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
                    style: theme.textTheme.headline6
                        .apply(color: theme.accentColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlineButton(
                    child: Text('Create Event'),
                    onPressed: _createBeerEvent,
                    textColor: theme.accentColor,
                    color: theme.accentColor,
                    highlightedBorderColor: theme.accentColor,
                  ),
                ),
              ],
            ),
            Flexible(
              child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int idx) {
                    return Container(
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, top: 8, right: 16, bottom: 8),
                          child: Row(
                            children: <Widget>[
                              Container(
                                child: CircleAvatar(
                                  child: Icon(Icons.group),
                                ),
                                margin: EdgeInsets.only(right: 16.0),
                              ),
                              Text(
                                events[idx].name,
                                style: theme.textTheme.headline6,
                              )
                            ],
                          ),
                        ),
                        onTap: () =>
                            openEventPage(context, widget.user, events[idx]),
                      ),
                    );
                  }),
            ),
          ],
        ));
  }
}

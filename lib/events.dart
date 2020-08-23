import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'beermap.dart';
import 'firebase/firebase_helper.dart';
import 'models.dart';

void openEventPage(context, FirebaseUser user, BeerEvent event) =>
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) =>
            EventPage(user: user, beerEventId: event.id)));

class EventPage extends StatefulWidget {
  final FirebaseUser user;
  final String beerEventId;

  EventPage({this.user, this.beerEventId});

  @override
  State<StatefulWidget> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>
    implements FirebaseHelperCallback {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  BeerEvent event = BeerEvent();

  List<BeerEvent> events = [];
  List<Beer> beers = [];
  List<User> users = [];

  FirebaseHelper helper;

  _EventPageState() {
    helper = FirebaseHelper(callback: this);
  }

  void _sortDrinkers() =>
      event.drinkers.sort((d1, d2) => _getBeerCount(d1) - _getBeerCount(d2));

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

  @override
  void eventsChanged(List<BeerEvent> events) => setState(() {
        this.events = events;
        this.event = events.firstWhere((e) => e.id == widget.beerEventId);
      });

  @override
  void beersChanged(List<Beer> beers) {
    _sortDrinkers();
    setState(() => {
          this.beers =
              beers.where((e) => e.eventId == widget.beerEventId).toList()
        });
  }

  @override
  void usersChanged(List<User> users) => setState(() => {this.users = users});

  Future<void> _showPasswordDialog() async => showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Password'),
            content: Text(
                'The password to join ${event.name} is: ${widget.beerEventId}'),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );

  String _getPhotoUrl(uid) {
    List<User> _user = users.where((e) => e.uid == uid).toList();
    return _user.isNotEmpty ? _user.first.photoUrl : '';
  }

  String _getUserName(uid) {
    List<User> _user = users.where((e) => e.uid == uid).toList();
    return _user.isNotEmpty ? _user.first.name : '';
  }

  int _getBeerCount(uid) => beers.where((e) => e.uid == uid).length;

  Future<void> _askForBeerEventPassword() async {
    int idx = events.indexOf(event);
    TextEditingController controller = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Please ask a someone for the password to join ${event.name}.'),
                TextField(
                  autofocus: true,
                  controller: controller,
                  decoration: InputDecoration(labelText: 'Password'),
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
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  SnackBar snackBar;
                  if (controller.text == widget.beerEventId) {
                    // password correct
                    helper.joinBeerEvent(widget.user.uid, idx);
                    snackBar = SnackBar(content: Text('Password correct!'));
                  } else {
                    snackBar = SnackBar(content: Text('Password incorrect!'));
                  }
                  _scaffoldKey.currentState..showSnackBar(snackBar);
                })
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDrinker = event.drinkers.contains(widget.user.uid);
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(event.name),
          actions: <Widget>[
            Center(
              child: Visibility(
                child: OutlineButton(
                  child: Text('Join'),
                  onPressed: () => _askForBeerEventPassword(),
                  textColor: theme.accentColor,
                  color: theme.accentColor,
                  highlightedBorderColor: theme.accentColor,
                ),
                visible: !isDrinker,
              ),
            ),
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () => openBeerMap(context, beers),
            ),
            PopupMenuButton<String>(
              onSelected: (String s) {
                switch (s) {
                  case 'pwd':
                    _showPasswordDialog();
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'pwd',
                  child: Text('Show Password'),
                )
              ],
            ),
          ],
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
                  'Total Beer Count: ${beers.length}',
                  style: theme.textTheme.headline4,
                ),
                onTap: () => {},
              ),
            ),
            Flexible(
              child: ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  itemCount: event.drinkers.length,
                  itemBuilder: (BuildContext context, int idx) {
                    String uid = event.drinkers[idx];
                    return Container(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  child: CircleAvatar(
                                    backgroundImage:
                                    NetworkImage(_getPhotoUrl(uid)),
                                  ),
                                  margin: EdgeInsets.only(right: 16.0),
                                ),
                                Text(
                                  _getUserName(uid),
                                  style: theme.textTheme.headline6,
                                ),
                              ],
                            ),
                            Text(
                              '${_getBeerCount(uid).toString()} Beers',
                              style: theme.textTheme.headline6
                                  .apply(color: theme.accentColor),
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'beermap.dart';
import 'firebase/firebase_helper.dart';
import 'models.dart';

void openEventPage(context, event) =>
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) => EventPage(event: event)));

class EventPage extends StatefulWidget {
  final BeerEvent event;

  EventPage({this.event});

  @override
  State<StatefulWidget> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>
    implements FirebaseHelperCallback {
  List<Beer> beers = [];
  List<User> users = [];

  FirebaseHelper helper;

  _EventPageState() {
    helper = FirebaseHelper(callback: this);
  }

  void _sortDrinkers() {
    widget.event.drinkers
        .sort((d1, d2) => _getBeerCount(d1) - _getBeerCount(d2));
  }

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
  void eventsChanged(List<BeerEvent> events) {}

  @override
  void beersChanged(List<Beer> beers) {
    _sortDrinkers();
    setState(() => {
          this.beers = beers.where((e) => e.eventId == widget.event.id).toList()
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
                'The password to join ${widget.event.name} is: ${widget.event.id}'),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );

  String _getUserName(uid) {
    List<User> _user = users.where((e) => e.uid == uid).toList();
    return _user.isNotEmpty ? _user.first.name : '';
  }

  int _getBeerCount(uid) => beers.where((e) => e.uid == uid).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.event.name),
          actions: <Widget>[
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
                  itemCount: widget.event.drinkers.length,
                  itemBuilder: (BuildContext context, int idx) {
                    String uid = widget.event.drinkers[idx];
                    return Container(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              _getUserName(uid),
                              style: theme.textTheme.subtitle1,
                            ),
                            Text(
                              _getBeerCount(uid).toString(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.accentColor,
                              ),
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

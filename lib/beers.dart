import 'package:beer_counter/beermap.dart';
import 'package:beer_counter/firebase/firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';

void openBeersPage(context, user) =>
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) => BeersPage(user: user)));

class BeersPage extends StatefulWidget {
  final FirebaseUser user;

  BeersPage({this.user});

  @override
  State<StatefulWidget> createState() => _BeersPageState();
}

class _BeersPageState extends State<BeersPage>
    implements FirebaseHelperCallback {
  List<Beer> beers = [];
  List<BeerEvent> events = [];

  FirebaseHelper helper;

  _BeersPageState() {
    helper = FirebaseHelper(callback: this);
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
  void eventsChanged(List<BeerEvent> events) =>
      setState(() => {this.events = events});

  @override
  void beersChanged(List<Beer> beers) => setState(() =>
      {this.beers = beers.where((e) => e.uid == widget.user.uid).toList()});

  @override
  void usersChanged(List<User> users) {}

  String _getBeerEventName(int idx) {
    try {
      String eventId = beers[idx].eventId;
      return events.firstWhere((e) => e.id == eventId).name;
    } catch (_) {
      return 'No Event';
    }
  }

  String _beerTimeStampToDate(int idx) => DateFormat('yyyy-MM-dd hh:mm')
      .format(DateTime.fromMillisecondsSinceEpoch(beers[idx].timeStamp));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beers'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () => openBeerMap(context, beers),
          ),
        ],
      ),
      body: ListView.builder(
          itemCount: beers.length,
          itemBuilder: (BuildContext context, int idx) {
            return Container(
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 24, top: 8, right: 24, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(_beerTimeStampToDate(idx),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      Text(_getBeerEventName(idx)),
                      IconButton(
                        icon: Icon(Icons.location_on),
                        onPressed: () => openBeerMap(context, [beers[idx]]),
                      )
                    ],
                  ),
                ),
                onLongPress: () => helper.removeBeer(beers[idx]),
              ),
            );
          }),
    );
  }
}

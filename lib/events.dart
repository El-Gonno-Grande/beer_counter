import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  void beersChanged(List<Beer> beers) => setState(() =>
      {this.beers = beers.where((e) => e.eventId == widget.event.id).toList()});

  @override
  void usersChanged(List<User> users) => setState(() => {this.users = users});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.event.name),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
                            Text(users.firstWhere((e) => e.uid == uid).name,
                                style: TextStyle(fontSize: 16)),
                            Text(
                                beers
                                    .where((e) => e.uid == uid)
                                    .length
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
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

import 'dart:async';
import 'dart:math';

import 'package:beer_counter/beers.dart';
import 'package:beer_counter/events.dart';
import 'package:beer_counter/firebase/firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
  List<User> users = [];

  FirebaseHelper helper;

  _ProfilePageState() {
    helper = FirebaseHelper(callback: this);
  }

  @override
  void eventsChanged(List<BeerEvent> events) =>
      setState(() => this.events = events);

  @override
  void beersChanged(List<Beer> beers) => setState(() => this.beers = beers);

  @override
  void usersChanged(List<User> users) => setState(() => this.users = users);

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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Beer Event'),
          content: TextField(
            autofocus: true,
            controller: controller,
            decoration: InputDecoration(labelText: 'Event Name'),
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
    BeerEvent event = BeerEvent(name: 'No Event');
    List<BeerEvent> participatingEvents = [event];
    participatingEvents
        .addAll(events.where((e) => e.drinkers.contains(widget.user.uid)));

    final theme = Theme.of(context);
    return showDialog<BeerEvent>(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
              title: const Text('Pick a Beer Event'),
              children: participatingEvents
                  .map((e) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, e),
                        child: Text(
                          e.name,
                          style: theme.textTheme.bodyText1,
                        ),
                      ))
                  .toList(),
            ));
  }

  Future<void> _addBeer() async {
    BeerEvent event = await _askForBeerEvent();
    print(event);
    if (event == null || event.id == null) {
      return;
    }
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
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

  int _getBeerCount(uid) => beers.where((b) => b.uid == uid).length;

  int _getBeerGoal(uid) => users
      .firstWhere((element) => element.uid == uid, orElse: () => User(beerGoal: 1))
      .beerGoal;

  double _getDailyBeerPercentage() =>
      _getBeerCount(widget.user.uid).toDouble() /
      _getBeerGoal(widget.user.uid).toDouble();

  List<Widget> _generateEventsWidgets(theme, List<BeerEvent> events) => events
      .map((e) => Container(
            child: InkWell(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, top: 8, right: 16, bottom: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      child: CircleAvatar(
                        child: Icon(Icons.group),
                        backgroundColor: Colors.black38,
                      ),
                      margin: EdgeInsets.only(right: 16.0),
                    ),
                    Text(
                      e.name,
                      style: theme.textTheme.headline6,
                    )
                  ],
                ),
              ),
              onTap: () => openEventPage(context, widget.user, e),
            ),
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.user.photoUrl),
              child: InkWell(
                onTap: () {
                  /* TODO: logout */
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 10.0,
                  animation: true,
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: theme.accentColor..withAlpha(255),
                  backgroundColor: _getDailyBeerPercentage() >= 1.0
                      ? theme
                          .dividerColor /* TODO: What to do when goal achieved? */
                      : theme.dividerColor,
                  percent: ((_getDailyBeerPercentage() * 100) % 100) / 100,
                  center: Text(
                    _getBeerCount(widget.user.uid).toString(),
                    style: theme.textTheme.headline4
                        .apply(color: theme.accentColor),
                  ),
                  footer: RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: SvgPicture.asset('assets/beer.svg',
                              color: Colors.white60),
                        ),
                        TextSpan(
                            text: ' Beer Count',
                            style: theme.textTheme.headline6
                                .apply(color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
              ),
              onTap: () => openBeersPage(context, widget.user),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'My Events',
                    style: theme.textTheme.headline6
                        .apply(color: theme.accentColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlineButton(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: 'Create Event ',
                              style: theme.textTheme.button
                                  .apply(color: theme.accentColor)),
                          WidgetSpan(
                            child: Icon(Icons.add, size: 16),
                          ),
                        ],
                      ),
                    ),
                    onPressed: _createBeerEvent,
                    textColor: theme.accentColor,
                    color: theme.accentColor,
                    highlightedBorderColor: theme.accentColor,
                  ),
                ),
              ],
            ),
          ]..addAll(_generateEventsWidgets(theme, events)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBeer,
        child: SvgPicture.asset(
          'assets/add_beer.svg',
          color: Colors.black54,
          width: 28,
          height: 28,
        ),
        backgroundColor: theme.accentColor,
      ),
    );
  }
}

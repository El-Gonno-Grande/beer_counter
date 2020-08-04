import 'dart:convert';

/// various model classes to store data in Firebase

class BeerEvent {
  String id, name;
  List<String> participants;

  BeerEvent({
    this.id,
    this.name,
    this.participants,
  });

  /// get unique identifier for the [BeerEvent]
  String getId() => id;

  /// get [BeerEvent] name
  String getName() => name;

  /// get an array of all Uids of participating users in this [BeerEvent]
  getParticipants() => participants;

  BeerEvent.fromJson(Map<dynamic, dynamic> json)
      : id = json['id'],
        name = json['name'],
        participants = List<String>.from(jsonDecode(json['participants']));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'participants': jsonEncode(participants),
      };
}

class Beer {
  String uid;
  BeerEvent event;
  double lat, lon;
  int timeStamp;
  bool verified;

  Beer({
    this.uid,
    this.event,
    this.lat = 0,
    this.lon = 0,
    this.timeStamp = 0,
    this.verified = false,
  });

  /// get [BeerEvent].id where [Beer] was consumed
  BeerEvent getEvent() => event;

  /// get geo location at which [Beer] was consumed
  List<double> getLocation() => [lat, lon];

  /// get time at which [Beer] was consumed
  int getTime() => timeStamp;

  /// true is [Beer] was verified
  bool isVerified() => verified;

  Beer.fromJson(Map<dynamic, dynamic> json)
      : uid = json['uid'],
        event = jsonDecode(json['event']),
        lat = json['lat'],
        lon = json['lon'],
        timeStamp = json['timeStamp'],
        verified = json['verified'];

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'event': jsonEncode(event),
    'lat': lat,
    'lon': lon,
    'timeStamp': timeStamp,
    'verified': verified,
  };
}

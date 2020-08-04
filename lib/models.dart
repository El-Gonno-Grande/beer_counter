import 'package:latlong/latlong.dart';

/// various model classes to store data in Firebase

class BeerEvent {
  String id, name;
  List<String> drinkers;

  BeerEvent({
    this.id,
    this.name,
    this.drinkers,
  });

  /// get unique identifier for the [BeerEvent]
  String getId() => id;

  /// get [BeerEvent] name
  String getName() => name;

  /// get an array of all Uids of participating/drinking users in this [BeerEvent]
  getParticipants() => drinkers;

  @override
  String toString() {
    return name;
  }

  BeerEvent.fromJson(Map<dynamic, dynamic> json)
      : id = json['id'],
        name = json['name'],
        drinkers = List<String>.from(json['drinkers'] ?? []);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'drinkers': drinkers,
      };
}

class Beer {
  String uid, eventId;
  double lat, lon;
  int timeStamp;
  bool verified;

  Beer({
    this.uid,
    this.eventId,
    this.lat = 0,
    this.lon = 0,
    this.timeStamp = 0,
    this.verified = false,
  });

  /// get [BeerEvent].id where [Beer] was consumed
  String getEventId() => eventId;

  /// get geo location at which [Beer] was consumed
  LatLng getLocation() => LatLng(lat, lon);

  /// get time at which [Beer] was consumed
  int getTime() => timeStamp;

  /// true is [Beer] was verified
  bool isVerified() => verified;

  Beer.fromJson(Map<dynamic, dynamic> json)
      : uid = json['uid'],
        eventId = json['eventId'],
        lat = json['lat'],
        lon = json['lon'],
        timeStamp = json['timeStamp'],
        verified = json['verified'];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'eventId': eventId,
        'lat': lat,
        'lon': lon,
        'timeStamp': timeStamp,
        'verified': verified,
      };
}

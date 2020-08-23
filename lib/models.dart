import 'package:latlong/latlong.dart';

/// various model classes to store data in Firebase

class BeerEvent {
  String id, name;
  List<String> drinkers = [];

  BeerEvent({
    this.id,
    this.name = '',
    this.drinkers = const [],
  });

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

  static List<BeerEvent> fromJsonToList(dynamic json) => json == null
      ? []
      : List<BeerEvent>.from(json.map((b) => BeerEvent.fromJson(b)));

  @override
  bool operator ==(other) => other is BeerEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

  /// get geo location at which [Beer] was consumed
  LatLng getLocation() => LatLng(lat, lon);

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

  static List<Beer> fromJsonToList(dynamic json) =>
      json == null ? [] : List<Beer>.from(json.map((b) => Beer.fromJson(b)));

  @override
  bool operator ==(other) =>
      other is Beer && other.uid == uid && other.timeStamp == timeStamp;

  @override
  int get hashCode => (uid.hashCode + timeStamp).hashCode;
}

class User {
  String uid, name = '', photoUrl = '';

  User({this.uid, this.name, this.photoUrl});

  User.fromJson(Map<dynamic, dynamic> json)
      : uid = json['uid'],
        name = json['name'],
        photoUrl = json['photoUrl'];

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
      };

  static List<User> fromJsonToList(dynamic json) =>
      json == null ? [] : List<User>.from(json.map((b) => User.fromJson(b)));

  @override
  bool operator ==(other) => other is User && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

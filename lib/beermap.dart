import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'models.dart';

void openBeerMap(context, beers) =>
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) => BeerMapPage(beers: beers)));

class BeerMapPage extends StatefulWidget {
  final List<Beer> beers;

  BeerMapPage({this.beers});

  @override
  State<StatefulWidget> createState() => _BeerMapState();
}

class _BeerMapState extends State<BeerMapPage> {
  @override
  Widget build(BuildContext context) {
    // center map on latest beer
    LatLng mapCenter;
    if (widget.beers.isEmpty) {
      // no beer in list => center map on Munich
      mapCenter = LatLng(48.1351, 11.5820);
    } else {
      mapCenter = widget.beers
          .reduce((val, e) => e.timeStamp > val.timeStamp ? e : val)
          .getLocation();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('BeerMap'),
      ),
      body: FlutterMap(
        options: MapOptions(
          minZoom: 1.0,
          maxZoom: 18.0,
          center: mapCenter,
          zoom: 13.0,
        ),
        layers: [
          TileLayerOptions(
              urlTemplate:
                  'https://tile.thunderforest.com/neighbourhood/{z}/{x}/{y}{r}.png?apikey=1ccbe9a0e02a437b89226c3344e6c3cf',
              subdomains: ['a', 'b', 'c']),
          MarkerLayerOptions(
            markers: widget.beers
                .map((e) => Marker(
                      width: 80.0,
                      height: 80.0,
                      anchorPos: AnchorPos.exactly(Anchor(40.0, 0.0)),
                      point: e.getLocation(),
                      builder: (ctx) => Container(
                        child: Image.asset('assets/beer_pin.png'),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

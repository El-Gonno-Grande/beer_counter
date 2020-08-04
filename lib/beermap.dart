import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    Beer latestBeer =
        widget.beers.reduce((val, e) => e.timeStamp > val.timeStamp ? e : val);
    return Scaffold(
      appBar: AppBar(
        title: Text('BeerMap'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: latestBeer.getLocation(),
          zoom: 13.0,
        ),
        layers: [
          TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']),
          MarkerLayerOptions(
            markers: widget.beers
                .map((e) => Marker(
                      width: 80.0,
                      height: 80.0,
                      point: e.getLocation(),
                      builder: (ctx) => Container(
                        child: SvgPicture.asset(
                          'assets/beer_location.svg',
                          height: 50.0,
                          width: 50.0,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

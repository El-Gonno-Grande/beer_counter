import 'package:beer_counter/beermap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'models.dart';

class BeerPage extends StatefulWidget {
  final List<Beer> beers;

  BeerPage({this.beers});

  @override
  State<StatefulWidget> createState() => _BeerPageState();
}

class _BeerPageState extends State<BeerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beers'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<Null>(
                    builder: (BuildContext context) => BeerMapPage(
                          beers: widget.beers,
                        )),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('//TODO'),
      ),
    );
  }
}

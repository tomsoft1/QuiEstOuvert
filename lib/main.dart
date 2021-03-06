// @ Thomas LANDSPURG 2020
// An open source application to display open commerces during COVID19
//

import 'dart:async';

import 'package:QuiEstOuvert/select_cat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';
import 'package:user_location/user_location.dart';

import 'information_screen.dart';

void main() => runApp(QuiEstOuvertApp());

// Displayed category to file mapping
Map<String, List<String>> categories = {
  "Alimentation": [
    "grocery",
    "convenience",
    "bakery",
    "cheese",
    "supermarket",
    "alcohol",
    "butcher",
    "seafood",
    "marketplace",
    "fast_food",
    "greengrocer"
  ],
  "Pharmacie": ["pharmacy"],
  "Station services": ["fuel", "car"],
  "Banque": ["bank"],
  "Restaurant": ["restaurant"],
  "Funeraire": ["funeral_directors"],
  "Tabac Presse": ["tobacco", "newsagent"],
  "Postes": ["post_office"]
};

// Displayed state
Map<String, Color> mapping = {
  "ouvert": Colors.green,
  "inconnu": Colors.grey,
  "fermé": Colors.red,
  "ouvert_adapté": Colors.blue
};
Map<String, IconData> iconFromCategory = {
  "Alimentation": Icons.local_grocery_store,
  "Pharmacie": Icons.local_pharmacy,
  "Station services": Icons.local_gas_station,
  "Banque": Icons.local_atm,
  "Restaurant": Icons.restaurant_menu,
  "Funeraire": Icons.query_builder,
  "Tabac Presse": Icons.query_builder,
  "Postes": Icons.local_post_office,
  "Autres": Icons.access_time
};

class QuiEstOuvertApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapPage(title: 'Qui Est Ouvert'),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapController mapController = new MapController();
  Map<String, bool> selectedList = new Map<String, bool>();
  Location location = new Location(); // Current user location
  Geoflutterfire geo = Geoflutterfire();
  Timer reloadTimer;
  String ex1 = "No value selected";
  List<DocumentSnapshot>  currentList = List<DocumentSnapshot> ();
  GeoFirePoint lastCenter;
  //Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var markers = <Marker>[];
  var rad = 10.0;
  LocationData currentLoc;
  @override
  void initState() {
    super.initState();
    iconFromCategory.keys.forEach((element) {
      selectedList[element] = true;
    });
    _initLocation();
  }
  refresh() {
  setState(() {});
}

  @override
  Widget build(BuildContext context) {
    print("Selected:$selectedList");
    _updateMarkers(currentList);
    var userLocationOptions = UserLocationOptions(
        context: context,
        mapController: mapController,
        markers: markers,
        updateMapLocationOnPositionChange: false);
    print(selectedList);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Qui est ouvert?"),
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(children:[
                          Text("Categories",style: TextStyle(fontSize: 24)),
                          SingleChildScrollView(child:SelectCat(selectedState:this.selectedList,notifyParent: this.refresh )),
                          RaisedButton(onPressed: () => Navigator.pop(context),child:Text("Ok"))
                          ]));
                  });
            },
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => InformationScreen()));
            },
          )
        ],
      ),
      body: FlutterMap(
          mapController: mapController,
          options: new MapOptions(
            center: LatLng(43.40804, 3.6680193),
            zoom: 14.0,
            onPositionChanged: _onCameraIdle,
            plugins: [
              UserLocationPlugin(),
            ],
          ),
          layers: [
            new TileLayerOptions(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c']),
            new MarkerLayerOptions(markers: markers),
            userLocationOptions,
          ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _centerMap();
        },
        child: Icon(Icons.center_focus_strong ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Do a query to Firebase, centered on "location" with a radius of "rad"
  _startQuery(LatLng location) async {
    // Make a referece to firestore
    var ref = Firestore.instance.collection('locations');
    GeoFirePoint center =
        geo.point(latitude: location.latitude, longitude: location.longitude);
    if((center.latitude != lastCenter.latitude)||(center.longitude != lastCenter.longitude)){
      lastCenter = center;
    return geo
        .collection(collectionRef: ref)
        .within(
            center: GeoFirePoint(center.latitude, center.longitude),
            radius: rad,
            field: 'location',
            strictMode: true)
        .listen(_updateMarkers);

    }
  }

  String categoryFromName(String name) {
    var ret = "Autres";
    categories.forEach((key, value) {
      if (value.contains(name)) {
        ret = key;
      }
    });
    return ret;
  }

  void _centerMap() async {
    print("Center map");
    currentLoc = await location.getLocation();
    print(currentLoc);
    mapController.move(LatLng(currentLoc.latitude, currentLoc.longitude), 13);
  }

  // Update the marker according to the list of document
  // received from Firebase.
  //
  void _updateMarkers(List<DocumentSnapshot> documentList) {
    currentList  = documentList;
    print("UpdateMarkers, Document list length: ${documentList.length}");
//    markers.clear();
    markers.clear();
    const maxMarkers = 30;
    if (documentList.length > maxMarkers) {
      documentList = documentList.sublist(0, maxMarkers);
    }
    documentList.forEach((DocumentSnapshot document) {
      var data = document.data;

//      print(data);
      GeoPoint pos = document.data['location']['geopoint'];
       var cat = categoryFromName(data['cat']);
      if (selectedList[cat]) {
        var name = data['name'];

        if (data["brand"].length > 0) name = name + "(${data['brand']})";
        var icon = new Icon(
                iconFromCategory[cat],
                color: Colors.black);
        var marker = Marker(
          point: LatLng(pos.latitude, pos.longitude),
          builder: (ctx) => new Container(
            decoration: new BoxDecoration(
              color: mapping[data['status']],
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return Container(
                        height: 200,
                        child: Column(children: [
                          Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                              icon,
                              Text("$name",style: TextStyle(fontSize: 18))
                              ]),
                          Text("Catégorie: $cat"),
                          Text("Informations:${data['infos']}"),
                          Text("Etat:" +
                              data['status'] +
                              " Heures:" +
                              data['opening_hours'])
                        ]),
                      );
                    });
              },
              child: icon
            ),
          ),
        );

        setState(() {
          markers.add(marker);
        });
      }
    });
  }

  void _initLocation() async {
    print("Before init");
    currentLoc = await location.getLocation();
    print("After init");
    print(currentLoc);
    mapController.move(LatLng(currentLoc.latitude, currentLoc.longitude), 13);
  }

  // When user stop to move the map, we do a query to update points around
  void _onCameraIdle(MapPosition pos, bool hasGesture) async {
    if (reloadTimer != null) reloadTimer.cancel();
    reloadTimer = Timer(Duration(seconds: 1), () {
      print("Timer raised");
      _startQuery(pos.center);
    });
  }
}
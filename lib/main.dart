
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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
  GoogleMapController mapController;
  Location location = new Location();  // Current user location
  Geoflutterfire geo = Geoflutterfire();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var rad = 10.0;
  LocationData currentLoc ;
  @override
  Widget build(BuildContext context) {
      _initLocation();

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: LatLng(43.40804, 3.6680193), zoom: 10),
          onMapCreated: _onMapCreated,
          onCameraIdle: _onCameraIdle,
          myLocationButtonEnabled: true,
          myLocationEnabled:
              true, // Add little blue dot for device location, requires permission from user
          mapType: MapType.normal,
          mapToolbarEnabled: true,
          markers: Set<Marker>.of(markers.values),
        ));
  }

  _startQuery(LatLng location) async {
    // Make a referece to firestore
    var ref = Firestore.instance.collection('locations');
    GeoFirePoint center = geo.point(latitude: location.latitude, longitude: location.longitude);

    return geo
        .collection(collectionRef: ref)
        .within(
            center: GeoFirePoint(center.latitude, center.longitude),
            radius: rad,
            field: 'location',
            strictMode: true)
        .listen(_updateMarkers);
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print("UpdateMarkers");
    print("Document list length: ${documentList.length}");
    markers.clear();
    const maxMarkers = 30;
    if (documentList.length > maxMarkers) {
      documentList = documentList.sublist(0, maxMarkers);
    }
    documentList.forEach((DocumentSnapshot document) {
      var data = document.data;

      print(data);
      GeoPoint pos = document.data['location']['geopoint'];
      if (data['name'] != null) {
        var name = data['name'];
        if(data["brand"].length>0)name = name+"(${data['brand']})";
        var marker = Marker(
            position: LatLng(pos.latitude, pos.longitude),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow:
                InfoWindow(title: name, snippet: '${data['cat']} ${data['status']}'),
            markerId: MarkerId(document.documentID));
        setState(() {
          markers[marker.markerId] = marker;
        });
      }
    });
  }
  void _initLocation() async {
    currentLoc = await location.getLocation();
  }
  void _onCameraIdle() async {
    print("Idle");
    LatLngBounds bounds = await mapController.getVisibleRegion();
    print(bounds);
    LatLng center = LatLng(
        (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
        (bounds.southwest.longitude + bounds.northeast.longitude) / 2);
    _startQuery(center);
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }
}

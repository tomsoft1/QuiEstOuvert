import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text("A propos"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          Container(padding: EdgeInsets.only(bottom: 30),child: Text("Qui Est Ouvert?",style:TextStyle(fontSize:20))),
          Text("@Thomas LANDSPURG 2020",style:TextStyle(fontSize: 15,color: Colors.grey)),
          Text("Cette application utilise les données Open Source pour vous afficher les commeres ouvert même en confinement.... Contact: thomas.landspurg@gmail.com"),
          Text("v0.1.1  9/04/2020")],
      ),
    ));
  }
}
import 'package:flutter/material.dart';

class SelectCat extends StatefulWidget {
  final Function() notifyParent;

  SelectCat({
    Key key,
    this.selectedState,
     @required this.notifyParent
  }): super(key: key);

  final Map<String, bool> selectedState;

  @override
  _SelectCatState createState() => new _SelectCatState();
}

class _SelectCatState extends State<SelectCat> {

  @override
  Widget build(BuildContext context) {
    print(widget.notifyParent);
    return Column(
      children: widget.selectedState.keys.map((e) => 
        Container(padding: EdgeInsets.all(5.0),
        
          child:Row(children: [
              Expanded(child: Text(e)),
              Checkbox(
                value: widget.selectedState[e],
                onChanged: (bool newValue) {
                  print("$e $newValue");
                  setState(() {
                    widget.selectedState[e] = newValue;
                  });
                  widget.notifyParent();
                },
              )
            ])))
      .toList());
  }
}
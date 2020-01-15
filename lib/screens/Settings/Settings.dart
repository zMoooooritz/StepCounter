import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {

  @override
  void initState() {
    super.initState();
    _read();
  }

  double _stepSize = 1.0;
  String _roundStepSize = "1.0";
  TextEditingController _controller = new TextEditingController();


  _read() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stepSize = prefs.getDouble('stepSize') ?? 1.0;
      _roundStepSize = _stepSize.toStringAsFixed(2);
      _controller.text = prefs.getString('deviceName') ?? 'eSense-';
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('stepSize', _stepSize);
    prefs.setString('deviceName', _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _save();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(icon: Icon(Icons.arrow_back),
            onPressed: () {
              _save();
              Navigator.pop(context);
            },
          ),
          title: Text(
              'Einstellungen'
          ),
        ),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 16.0, bottom: 8.0, left: 8.0, right: 8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Gerätename',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.all(
                    const Radius.circular(5.0),
                  ),
                  border: Border.all(
                    color: Colors.grey[600],
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Schrittlänge',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600]
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            width: 250,
                            child: Slider(
                              activeColor: Colors.indigoAccent,
                              min: 0.1,
                              max: 1.5,
                              onChanged: (newStepSize) {
                                setState(() {
                                  _stepSize = newStepSize;
                                  _roundStepSize =
                                      newStepSize.toStringAsFixed(2);
                                });
                              },
                              value: _stepSize,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '$_roundStepSize m',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
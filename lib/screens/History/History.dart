

import 'dart:convert';

import 'package:stepcounter/screens/Activity/Track.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryView extends StatefulWidget {
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {

  List<String> _activityStrings = [];
  List<Track> _activities = [];

  @override
  void initState() {
    super.initState();
    _read();
  }

  void dispose() {
    super.dispose();
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    if (!this.mounted)
      return;

    setState(() {
      _activityStrings = prefs.getStringList('activities') ?? [];

      _activityStrings.forEach((element) {
        _activities.add(Track.fromJson(jsonDecode(element)));

      });
/*
      _activities.add(Track(DateTime.now(), "00:01:00", 15, 400.4, 7.8));
      _activities.add(Track(DateTime.now(), "00:01:00", 15, 400.4, 7.8));
      _activities.add(Track(DateTime.now(), "00:01:00", 15, 400.4, 7.8));
*/
      _activities.sort((a, b) => b.date.compareTo(a.date));
    });

  }

  _resetHistory() async {
    setState(() {
      _activities = [];
    });
    _saveHistory();
  }

  _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('activities', _activities.map((e) => jsonEncode(e.toJson())).toList());
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(icon:Icon(Icons.arrow_back),
          onPressed:() => Navigator.pop(context),
        ),
        title: Text(
            'Historie'
        ),
        actions: <Widget>[
          PopupMenuButton<CustomPopupMenu>(
            initialValue: choices[0],
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.map((CustomPopupMenu choice) {
                return PopupMenuItem<CustomPopupMenu>(
                  value: choice,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        choice.icon,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      Text('${choice.title}')
                    ],
                  ),
                );
              }).toList();
            },
          )
        ],
      ),
      body:
      _historyBody(),
    );
  }

  void _select(CustomPopupMenu choice) {
    if (choice.id == 0)
      _resetHistory();
  }

  Widget _historyBody() {
    if (_activities.length == 0)
      return Center(
        child: Text(
          'Keine vergangenen \nAktivitäten vorhanden!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    else
      return Padding(
        padding: EdgeInsets.only(top: 10.0),
        child:
        ListView.builder(
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            return _historyEntry(_activities[index]);
          },
        ),
      );
  }

  Widget _historyEntry(Track _activity) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child:
            Container(
              decoration: BoxDecoration(
                borderRadius: new BorderRadius.all(
                  const Radius.circular(20.0),
                ),
                border: Border.all(
                  color: Colors.blueAccent,
                  width: 5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Text(
                          _formatDate(_activity.date),
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.0, top: 8.0),
                        child: Text(
                          '${_activity.stepCount} Schritte',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
                        child: Text(
                          '${_activity.duration} Stunden',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.0, bottom: 8.0, top: 8.0),
                        child: Text(
                          '≈ ${_formatDistance(_activity.distance)}',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                          ),
                          iconSize: 30,
                          onPressed: () {
                            setState(() {
                              _activities.remove(_activity);
                              _saveHistory();
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.0, bottom: 8.0, top: 8.0),
                        child: Text(
                          '≈ ${_activity.speed.toStringAsFixed(1).replaceAll('.', ',')} km/h',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
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
    );
  }

  String _formatDate(DateTime date) {
    return "Datum: " + date.day.toString().padLeft(2, '0') + "."
        + date.month.toString().padLeft(2, '0') + "." + date.year.toString();
  }

  String _formatDistance(double distance) {
    if (distance < 1000)
      return distance.toStringAsFixed(1).replaceAll('.', ',') + ' m';
    else
      return (distance / 1000).toStringAsFixed(2).replaceAll('.', ',') + ' km';
  }

}

class CustomPopupMenu {
  CustomPopupMenu({this.id, this.title, this.icon});

  int id;
  String title;
  IconData icon;
}

List<CustomPopupMenu> choices = <CustomPopupMenu>[
  CustomPopupMenu(id: 0, title: 'Lösche Historie', icon: Icons.delete_forever),
];
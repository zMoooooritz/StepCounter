
import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:stepcounter/screens/Activity/Track.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityView extends StatefulWidget {
  _ActivityViewState createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {

  DateTime _startTime = DateTime.now();
  DateTime _lastPress;
  DateTime _prevStepTime = DateTime.now();

  Stopwatch _swatch = new Stopwatch();
  final dur = const Duration(seconds: 1);
  Timer timer;

  bool _isPaused = false;
  int _passedMicroSeconds = 0;
  int _stepCount = 0;
  double _stepSize;
  String _displayDuration = '00:00:00';
  double _distance = 0;
  String _displayDistance = '0 m';
  double _speed;
  String _displaySpeed = '0 km/h';
  String _pauseOrContinue = 'Pausieren';

  List<int> _prevAccel;

  StreamSubscription _bleSub;
  StreamSubscription _eSenseSub;
  StreamSubscription _eventsSub;
  StreamSubscription _sensorSub;

  List<String> _activities;

  @override
  void initState() {
    super.initState();
    _swatch.start();
    _read();
    startTimer();
    _listenToBLEEvents();
    _listenToConnectionEvents();
    _listenToESenseEvents();
    _listenToSensorEvents();
  }

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  void startTimer() {
    if (!_isPaused)
      timer = Timer(dur, keepRunning);
    else
      timer.cancel();
  }

  void startStopWatch() {
    _swatch.start();
    startTimer();
  }

  void stopStopWatch() {
    _swatch.stop();
  }

  void pauseStopWatch() {
    _isPaused = !_isPaused;
    if (!_isPaused) {
      startStopWatch();
    } else {
      _passedMicroSeconds += _swatch.elapsedMicroseconds;
      _swatch.stop();
      _swatch.reset();
    }

    setState(() {
      _pauseOrContinue = _isPaused ? "Fortsetzen" : "Pausieren";
    });
  }

  void keepRunning() {
    if (_swatch.isRunning && !_isPaused) {
      startTimer();
    }
    if (!this.mounted || !_swatch.isRunning)
      return;

    setState(() {
      Duration timePassed = Duration(microseconds: _passedMicroSeconds
          + _swatch.elapsedMicroseconds);

      _displayDuration =
          timePassed.inHours.toString().padLeft(2, '0') + ':'
              + (timePassed.inMinutes % 60).toString().padLeft(2, '0') +
              ':'
              + (timePassed.inSeconds % 60).toString().padLeft(2, '0');

      _speed = ((_distance / 1000) / (timePassed.inMilliseconds / 3600000));
      _displaySpeed = "≈ " + _speed.toStringAsFixed(1) + " km/h";
    });
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stepSize = prefs.getDouble('stepSize') ?? 1.0;
      _activities = prefs.getStringList('activities') ?? [];
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('activities', _activities);
  }

  void _listenToBLEEvents() async {
    _bleSub = FlutterBlue.instance.state.listen((event) {
      setState(() {
        if (event == BluetoothState.off)
          _endActivity(true);
      });
    });
  }

  void _listenToConnectionEvents() async {
    _eSenseSub = ESenseManager.connectionEvents.listen((event) {
      setState(() {
        if (event.type != ConnectionType.connected)
          _endActivity(true);
      });
    });
  }

  void _listenToESenseEvents() async {
    _eventsSub = ESenseManager.eSenseEvents.listen((event) {
      setState(() {
        if (event.runtimeType == ButtonEventChanged
            && (event as ButtonEventChanged).pressed) {

          pauseStopWatch();
          DateTime now = DateTime.now();

          if (_lastPress != null && now.difference(_lastPress).inMilliseconds < 500)
            _endActivity(true);

          _lastPress = DateTime.now();
        }
      });
    });
  }

  void _listenToSensorEvents() async {
    _sensorSub = ESenseManager.sensorEvents.listen((event) {
      setState(() {
        if (_isPaused)
          return;

        List<int> accel = event.accel;

        if (_prevAccel != null) {
          DateTime now = DateTime.now();

          if (now.difference(_prevStepTime).inMilliseconds < 300)
            return;

          if (accel[0].sign != _prevAccel[0].sign && accel[0].abs() > 300 && _prevAccel[0].abs() > 100
              || accel[1].sign != _prevAccel[1].sign && accel[1].abs() > 300 && _prevAccel[1].abs() > 100
              || accel[2].sign != _prevAccel[2].sign && accel[2].abs() > 300 && _prevAccel[2].abs() > 100) {
            _stepCount++;
            _prevStepTime = now;
          }
        }
        _prevAccel = accel;

        _distance = _stepSize * _stepCount;
        if (_distance < 1000)
          _displayDistance = _distance.toStringAsFixed(2) + ' m';
        else
          _displayDistance = (_distance / 1000).toStringAsFixed(2) + ' km';
      });
    });
  }

  void _stopListening() async {
    if (_bleSub != null)
      await _bleSub.cancel();
    if (_eSenseSub != null)
      await _eSenseSub.cancel();
    if (_eventsSub != null)
      await _eventsSub.cancel();
    if (_sensorSub != null)
      await _sensorSub.cancel();
  }

  void _endActivity(bool save) {
    if (save) {
      _activities.add(jsonEncode(
          Track(_startTime, _displayDuration, _stepCount, _distance, _speed)
              .toJson()));
      _save();
    }
    _stopListening();
    stopStopWatch();
    timer.cancel();
    Navigator.pop(context);
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              'Aktivität'
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Text(
                      '$_displayDuration',
                      style: TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
              ],
            ),
            Divider(
              thickness: 5,
              color: Colors.blueGrey,
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Text(
                      'Schritte:',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Text(
                      '$_stepCount',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Text(
                      'Distanz:',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Text(
                      '$_displayDistance',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
              ],
            ),
            Divider(
              thickness: 5,
              color: Colors.blueGrey,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Text(
                      '$_displaySpeed',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
              ],
            ),
            Expanded(
              flex: 1,
              child: SizedBox.shrink(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ButtonTheme(
                    minWidth: 160,
                    height: 50,
                    child: RaisedButton(
                      child: Text(
                        '$_pauseOrContinue',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      color: Colors.blueAccent,
                      onPressed: () {
                        pauseStopWatch();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ButtonTheme(
                    minWidth: 160,
                    height: 50,
                    child: RaisedButton(
                      child: Text(
                        'Verwerfen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      color: Colors.redAccent,
                      onPressed: () {
                        _endActivity(false);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ButtonTheme(
                    minWidth: 340,
                    height: 50,
                    child: RaisedButton(
                      child: Text(
                        'Speichern & Beenden',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      color: Colors.green,
                      onPressed: () {
                        _endActivity(true);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }
}

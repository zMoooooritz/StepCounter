import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepcounter/connection_status.dart';
import 'package:stepcounter/router.dart';
import 'package:stepcounter/router_constants.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:esense_flutter/esense.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown]).then((_) =>
      runApp(new DynamicTheme(
          defaultBrightness: Brightness.light,
          data: (brightness) => new ThemeData(
              brightness: brightness,
              primarySwatch: Colors.blue,
          ),
          themedWidgetBuilder: (context, theme) {
            return new MaterialApp(
              title: "StepCounter",
              initialRoute: HomeViewRoute,
              onGenerateRoute: generateRoute,
              theme: theme,
            );
          })
      )
  );
}

const String DEFAULT_ESENSE_NAME = 'eSense-0864';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _deviceName = 'Unknown';
  double _voltage = -1;

  bool _appIsUsed = true;
  bool _isDark;

  Timer _timer;

  StreamSubscription _eSenseSub;
  StreamSubscription _eventsSub;
  StreamSubscription _bleSub;

  ConnectionStatus _connectionStatus = ConnectionStatus.BluetoothOn;
  
  Color retryButtonColor = Colors.amber[600];

  List<bool> _batteryStatus = [true, true, true, true, true];

  @override
  void initState() {
    super.initState();
    _setBarColor();
    _checkBLE();
    _updateLoop();
  }

  void _setBarColor() async {
    final prefs = await SharedPreferences.getInstance();

    bool isDark = prefs.getBool('isDark');

    if (isDark == null)
      isDark = true;
    else
      isDark = !isDark;

    _setBarColors(isDark);
    setState(() {
      _isDark = prefs.getBool('isDark') ?? false;
    });
  }

  void _updateLoop() async {
    final prefs = await SharedPreferences.getInstance();
    String _newDeviceName = prefs.getString('deviceName') ?? 'eSense-0864';

    if (_deviceName != _newDeviceName) {
      setState(() {
        _deviceName = _newDeviceName;
      });

      _stopListening();
      ESenseManager.disconnect();
      _listenToConnectionEvents();
    }

    _startTimer();
  }

  void _startTimer() {
    if (_appIsUsed)
      _timer = Timer(Duration(seconds: 1), _updateLoop);
    else
      _timer.cancel();
  }

  void _checkBLE() async {
    bool bleOn = await FlutterBlue.instance.isOn;
    if (!bleOn)
      _connectionStatus = ConnectionStatus.BluetoothOff;

    _listenToBLEEvents();
  }

  void _listenToBLEEvents() async {
    _bleSub = FlutterBlue.instance.state.listen((event) {

      if (event == BluetoothState.on) _listenToConnectionEvents();

      setState(() {
        switch (event) {
          case BluetoothState.on:
            _connectionStatus = ConnectionStatus.BluetoothOn;
            break;
          case BluetoothState.off:
            _connectionStatus = ConnectionStatus.BluetoothOff;
            break;
          default:
            break;
        }
      });
    });
  }

  void _listenToConnectionEvents() async {
    bool con = false;
    
    _eSenseSub = ESenseManager.connectionEvents.listen((event) {
      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        if (_connectionStatus == ConnectionStatus.BluetoothOff)
          return;

        switch (event.type) {
          case ConnectionType.connected:
            _connectionStatus = ConnectionStatus.Connected;
            break;
          case ConnectionType.unknown:
            _connectionStatus = ConnectionStatus.Unknown;
            break;
          case ConnectionType.disconnected:
            _connectionStatus = ConnectionStatus.Disconnected;
            break;
          case ConnectionType.device_found:
            _connectionStatus = ConnectionStatus.DeviceFound;
            break;
          case ConnectionType.device_not_found:
            _connectionStatus = ConnectionStatus.DeviceNotFound;
            break;
          default:
            _connectionStatus = ConnectionStatus.None;
            break;
        }
      });
    });

    _loadDeviceName().then(((val) async {
      if (_connectionStatus == ConnectionStatus.BluetoothOff)
        return;
      await ESenseManager.connect(_deviceName).then((value) {
        setState(() {
          _connectionStatus = con ? ConnectionStatus.Connected : ConnectionStatus.Disconnected;
        });
      });
    }));
  }

  Future<void> _loadDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    String devName = prefs.getString('deviceName');
    if (devName == null) {
      prefs.setString('deviceName', DEFAULT_ESENSE_NAME);
      devName = DEFAULT_ESENSE_NAME;
    }
    setState(() {
      _deviceName = devName;
    });
  }

  void _listenToESenseEvents() async {
    _eventsSub = ESenseManager.eSenseEvents.listen((event) {

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName;
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage;

            _batteryStatus = [true, true, true, true, true];
            if (_voltage <= 4.0)
              _batteryStatus[0] = false;
            if (_voltage <= 3.8)
              _batteryStatus[1] = false;
            if (_voltage <= 3.6)
              _batteryStatus[2] = false;
            if (_voltage <= 3.4)
              _batteryStatus[3] = false;
            break;
          default:
            break;
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    // get the battery level every 10 secs
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if (_connectionStatus == ConnectionStatus.Connected && this.mounted && ESenseManager.connected)
        await ESenseManager.getBatteryVoltage();
    });


    Timer(Duration(seconds: 2), () async {
      if (ESenseManager.connected)
        await ESenseManager.getDeviceName();
    });
  }

  void _stopListening() {
    if (_eSenseSub != null)
      _eSenseSub.cancel();
    if (_eventsSub != null)
      _eventsSub.cancel();
  }

  void dispose() {
    _stopListening();
    if (_bleSub != null)
      _bleSub.cancel();
    _timer.cancel();
    _appIsUsed = false;
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _createHeader(),
            _drawerNewActivity(),
            _createDrawerItem(
                icon: Icons.history,
                text: 'Historie',
                onTap: () {
                  Navigator.popAndPushNamed(context, HistoryViewRoute);
                }
            ),
            Divider(
              color: Colors.blueGrey,
              thickness: 2,
            ),
            _createDrawerItem(
                icon: Icons.settings,
                text: 'Einstellungen',
                onTap: () {
                  Navigator.popAndPushNamed(context, SettingsViewRoute);
                }
            ),
            ListTile(
              title: Row(
                children: <Widget>[
                  Icon(Icons.brightness_2),
                  Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text('Nachtmodus'),
                  )
                ],
              ),
              trailing: Switch(
                value: _isDark,
                activeColor: Colors.blue[400],
                onChanged: (_) => _changeTheme(),
              ),
              onTap: _changeTheme,
            ),
            _createDrawerItem(
                icon: Icons.info,
                text: 'Über',
                onTap: () {
                  Navigator.popAndPushNamed(context, AboutViewRoute);
                }
            ),
            Divider(
              color: Colors.blueGrey,
              thickness: 2,
            ),
            _createDrawerItem(
                icon: Icons.exit_to_app,
                text: 'Verlassen',
                onTap: () {
                  dispose();
                  SystemNavigator.pop();
                }
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('StepCounter'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 200,
                  color: _connectionStatus.statusColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _connectionState(),
                        _deviceInfo(),
                        _reconnectButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Divider(
            color: Colors.blueGrey,
            height: 10,
            thickness: 10,
          ),
          Expanded(
            child: Text(''),
          ),
          _newActivity(),
          Expanded(
            child: Text(''),
          ),
          _batteryInfo(),
          _battery()
        ],
      ),
    );
  }

  void _changeTheme() {
    setState(() {
      _isDark = Theme.of(context).brightness == Brightness.light;
    });
    DynamicTheme.of(context).setBrightness(!_isDark ? Brightness.light: Brightness.dark);
    _setBarColors(!_isDark);
  }

  Widget _connectionState() {
    return Text(
      _connectionStatus.statusMessage,
      style: TextStyle(
        fontSize: 35,
        fontWeight: FontWeight.bold,
        color: Colors.grey[850],
      ),
    );
  }

  Widget _deviceInfo() {
    if (_connectionStatus == ConnectionStatus.Connected ||
        _connectionStatus == ConnectionStatus.DeviceFound)
      return Text(
        _deviceName,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.grey[850],
        ),
      );
    else if (_connectionStatus == ConnectionStatus.Disconnected ||
        _connectionStatus == ConnectionStatus.DeviceNotFound)
      return Text(
        '( $_deviceName )',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.grey[850],
        ),
      );
    else
      return SizedBox.shrink();
  }

  Widget _reconnectButton() {
    if (_connectionStatus == ConnectionStatus.BluetoothOn)
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: ButtonTheme(
          minWidth: 150,
          height: 50,
          child: RaisedButton(
            child: Text(
              'Verbinde mit eSense',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Colors.grey[850],
              ),
            ),
            color: retryButtonColor,
            onPressed: () {
              _stopListening();
              _listenToConnectionEvents();
            },
          ),
        ),
      );
    else if (_connectionStatus == ConnectionStatus.BluetoothOff)
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          width: 300,
          height: 30,
          color: retryButtonColor,
          child: Text(
            'Bitte aktiviere Bluetooth',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Colors.grey[850],
            ),
          ),
        ),
      );
    else if (_connectionStatus == ConnectionStatus.Disconnected ||
          _connectionStatus == ConnectionStatus.DeviceNotFound)
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: ButtonTheme(
          minWidth: 150,
          height: 50,
          child: RaisedButton(
            child: Text(
              'Erneut Versuchen',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Colors.grey[850],
              ),
            ),
            color: retryButtonColor,
            onPressed: () {
              _stopListening();
              _listenToConnectionEvents();
            },
          ),
        ),
      );
    else
      return SizedBox.shrink();
  }

  Widget _newActivity() {
    if (_connectionStatus == ConnectionStatus.Connected)
      return Padding(
        padding: EdgeInsets.all(10.0),
        child: Container(
          decoration:  BoxDecoration(
            borderRadius: BorderRadius.all(
              const Radius.circular(10.0),
            ),
            border: Border.all(
              color: Colors.blueGrey,
              width: 7,
            ),
          ),
          child: ButtonTheme(
            minWidth: 300,
            height: 60,
            child: RaisedButton(
              padding: const EdgeInsets.all(10.0),
              color: Colors.blueAccent[700],
              onPressed: () {
                Navigator.pushNamed(context, ActivityViewRoute);
              },
              child: Text(
                'Neue Aktivität',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[850],
                ),
              ),
            ),
          ),
        ),
      );
    else
      return SizedBox.shrink();
  }

  Widget _drawerNewActivity() {
    if (_connectionStatus == ConnectionStatus.Connected)
      return _createDrawerItem(
          icon: Icons.local_activity,
          text: 'Neue Aktivität',
          onTap: () {
            Navigator.popAndPushNamed(context, ActivityViewRoute);
          }
      );
    else
      return ListTile(
        title: Row(
          children: <Widget>[
            Icon(
              Icons.local_activity,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400],
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                'Neue Aktivität',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            )
          ],
        ),
      );
  }

  Widget _batteryInfo() {
    if (_connectionStatus == ConnectionStatus.Connected)
      if (Theme.of(context).brightness == Brightness.dark) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: new BorderRadius.all(
              const Radius.circular(10.0),
            ),
          ),
          child: Center(
              child: Text(
                'Batteriestatus',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              )
          ),
        );
      } else {
        return Center(
            child: Text(
              'Batteriestatus',
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            )
        );
      }
    else
      return SizedBox.shrink();
  }

  Widget _battery() {
    if (_connectionStatus == ConnectionStatus.Connected)
      return Container(
        decoration: BoxDecoration(
          borderRadius: new BorderRadius.all(
            const Radius.circular(20.0),
          ),
          border: Border.all(
            color: Colors.black87,
            width: 7,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for(bool item in _batteryStatus) _batteryCell(item),
          ],
        ),
      );
    else
      return SizedBox.shrink();
  }

  Widget _batteryCell(isFilled) {
    Color filling = isFilled ? (_isDark ? Colors.lightGreen[600] : Colors.lightGreenAccent)
        : (_isDark ? Colors.grey[600] : Colors.grey[400]);

    return Expanded(
      flex: 3,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: new BorderRadius.all(
            const Radius.circular(7.0),
          ),
          border: Border.all(
            color: Colors.black87,
            width: 2,
          ),
          color: filling,
        ),
      ),
    );
  }

  void _setBarColors(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: isDark ? Colors.grey[100] : Colors.grey[900],
      systemNavigationBarIconBrightness: isDark ? Brightness.dark: Brightness.light,
      statusBarColor: isDark ? Colors.blue[600] : Colors.black,
    ));
  }
}

Widget _createHeader() {
  return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill,
              image:  AssetImage('assets/images/header.jpg'))),
      child: Stack(children: <Widget>[
        Positioned(
            bottom: 12.0,
            left: 16.0,
            child: Text("StepCounter",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w400))),
      ]
      )
  );
}

Widget _createDrawerItem(
    {IconData icon, String text, GestureTapCallback onTap}) {
  return ListTile(
    title: Row(
      children: <Widget>[
        Icon(icon),
        Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text(text),
        )
      ],
    ),
    onTap: onTap,
  );
}

/* TODO
    App testen, damit sie auf keinen Fall abstürzt
 */

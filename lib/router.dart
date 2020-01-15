import 'package:stepcounter/router_constants.dart';
import 'package:stepcounter/screens/About/About.dart';
import 'package:stepcounter/screens/History/History.dart';
import 'package:stepcounter/screens/Home/Home.dart';
import 'package:stepcounter/screens/Settings/Settings.dart';
import 'package:stepcounter/screens/Activity/Activity.dart';
import 'package:flutter/material.dart';

import 'screens/Error/Error.dart';


Route<dynamic> generateRoute(RouteSettings settings) {

  switch (settings.name) {
    case HomeViewRoute:
      return MaterialPageRoute(builder: (context) => HomeView());
    case ActivityViewRoute:
      return MaterialPageRoute(builder: (context) => ActivityView());
    case HistoryViewRoute:
      return MaterialPageRoute(builder: (context) => HistoryView());
    case SettingsViewRoute:
      return MaterialPageRoute(builder: (context) => SettingsView());
    case AboutViewRoute:
      return MaterialPageRoute(builder: (context) => AboutView());
    case ErrorViewRoute:
      return MaterialPageRoute(builder: (context) => ErrorView(name: settings.name));
    default:
      return MaterialPageRoute(builder: (context) => ErrorView(name: settings.name));


  }

}
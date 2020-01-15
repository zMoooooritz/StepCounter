
import 'package:flutter/material.dart';

class ErrorView extends StatefulWidget {
  final String name;
  const ErrorView({Key key, this.name}) : super(key: key);

  _ErrorViewState createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {

  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Error'),
          automaticallyImplyLeading: true,
          leading: IconButton(icon:Icon(Icons.arrow_back),
            onPressed:() => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Text(''),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'ERROR',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Unbekannte Route "${widget.name}"',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Hier solltest du niemals landen!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Gehe zur zuletzt genutzten Seite zurück',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
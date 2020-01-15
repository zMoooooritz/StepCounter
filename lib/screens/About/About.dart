
import 'package:flutter/material.dart';

class AboutView extends StatefulWidget {
  _AboutViewState createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {

  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Über'),
          automaticallyImplyLeading: true,
          leading: IconButton(icon:Icon(Icons.arrow_back),
            onPressed:() => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(10.0),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Text(
                'StepCounter',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 20.0, left: 10.0, right: 10.0),
              child: Text(
                'Dies ist eine App, die für die Earables eSense entwickelt wurde. '
                    + 'Sie liest den Beschleunigungssensor des eSense Earables aus, '
                    + 'um mit dessen Daten die Anzahl der gegangenen Schritte zu '
                    + 'berechnen. Mittels der vom Nutzer angegebenen Schrittweite '
                    + 'kann damit die zu Fuß zurückgelegte Distanz approximiert werden. '
                    + 'Damit die Messung erfolgen kann, muss der LINKE Earbud im Ohr '
                    + 'getragen werden, der rechte ist dafür jedoch nicht nötig.',
                overflow: TextOverflow.ellipsis,
                maxLines: 15,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Divider(
              color: Colors.blueGrey,
              thickness: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                'Entwickler',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Name: Moritz Biering\n'
                    + 'GitHub: zMoooooritz\n'
                    + 'E-Mail: moritzbiering.mb@gmail.com',
                overflow: TextOverflow.ellipsis,
                maxLines: 10,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        )
    );
  }
}
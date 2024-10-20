import 'dart:developer';

import 'package:autocomplete_google_places_widget/autocomplete_google_places_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Google Places Autocomplete Demo',
      home: MyHomePage(
        title: 'Google Places Autocomplete Demo',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _yourGoogleAPIKey = ''; // fill with your Google API Key

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
              child: GPlacesAutoComplete(
            googleAPIKey: _yourGoogleAPIKey,
            countries: const ['FR'],
            onItemSelected: (p0) => log('onItemSelected: ${p0.description}'),
            enablePredictionsHistory: true,
            liteModeHistory: true,
            menuTileIcon: const Icon(
              Icons.location_on,
            ),
          )),
        ),
      ),
    );
  }
}

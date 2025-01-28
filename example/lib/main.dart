import 'dart:developer';

import 'package:autocomplete_google_places_widget/autocomplete_google_places_widget.dart';
import 'package:flutter/material.dart';
import '.env';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'GPlacesAutoComplete Widget Demo',
      home: MyHomePage(
        title: 'GPlacesAutoComplete Widget Demo',
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
  final _yourGoogleAPIKey = apiKey; // fill with your Google API Key

  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isLoading = false;

  String _selectedPlace = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected Place: $_selectedPlace'),
              const SizedBox(height: 16),
              GPlacesAutoComplete(
                googleAPIKey: _yourGoogleAPIKey,
                textEditingController: _textEditingController,
                focusNode: _focusNode,
                textFormFieldBuilder: (BuildContext context,
                    TextEditingController controller,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: (_) {
                      onFieldSubmitted();
                    },
                    decoration: InputDecoration(
                      prefixIcon: isLoading
                          ? Transform.scale(
                              scale: 0.35,
                              child: const CircularProgressIndicator())
                          : const Icon(Icons.search),
                      hintText: 'Search places...',
                      border: const OutlineInputBorder(),
                    ),
                  );
                },
                loadingCallback: (bool loading) {
                  setState(() {
                    isLoading = loading;
                  });
                },
                countries: const ['FR'],
                onOptionSelected: (option) {
                  log('onOptionSelected: ${option.toJson()}');
                  setState(() {
                    _selectedPlace = option.description ?? '';
                  });
                },
                incudeLatLng: true,
                enableHistory: true,
                liteModeHistory: true,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () {
            _textEditingController.clear();
            setState(() {
              _selectedPlace = '';
            });
          },
          tooltip: 'Clear',
          child: const Icon(Icons.delete),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:autocomplete_google_places_widget/src/helper/debouncer.dart';
import 'package:autocomplete_google_places_widget/src/models/place_autocomplete_response.dart';
import 'package:autocomplete_google_places_widget/src/models/predicition.dart';
import 'package:autocomplete_google_places_widget/src/services/google_places_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Flutter code sample for [Autocomplete] that demonstrates fetching the
/// options asynchronously and debouncing the network calls, including handling
/// network errors.

class GPlacesAutoComplete extends StatefulWidget {
  /// The Google API key to use for the Places API.
  final String googleAPIKey;

  /// A callback that is called when the user selects an option.
  final void Function(Prediction)? onItemSelected;

  /// A builder for the field decoration. If not provided, a default
  /// decoration will be used. [isSearching] is true when the field is
  /// currently searching for options, and [isAPIException] is true when
  /// an error occurred while searching for options.
  final InputDecoration Function(bool isSearching, bool isAPIException)?
      fieldDecorationBuilder;

  /// A builder for the menu tile.
  final Widget Function(BuildContext context, Prediction prediction)?
      menuTileBuilder;

  /// The time (in milliseconds) to wait after the user stops typing
  ///  to make the API request.
  final int debounceTime;

  /// The countries to restrict the search to.
  final List<String>? countries;

  /// The maximum height of the options menu.
  final double optionsMaxHeight;

  /// The maximum width of the options menu.
  final double? optionsMaxWidth;

  /// The color of the menu.
  final Color? menuColor;

  /// The elevation of the menu.
  final double menuElevation;

  /// The shape of the menu.
  final double menuBorderRadius;

  /// If true, the menu tile will be dense.
  final bool denseMenuTile;

  ///  The icon to use for the menu.
  final Widget? menuTileIcon;

  /// A builder for the options view.
  final Widget Function(
      BuildContext context,
      AutocompleteOnSelected<Prediction> onSelected,
      Iterable<Prediction> options)? optionsViewBuilder;

  /// If true, the predictions history will be saved in shared preferences
  final bool enablePredictionsHistory;

  /// if True, The prediction saved will contain only the `placeId`, `description` and `LatLng` (if available)
  final bool liteModeHistory;

  const GPlacesAutoComplete({
    super.key,
    required this.googleAPIKey,
    this.onItemSelected,
    this.menuTileBuilder,
    this.debounceTime = 500,
    this.countries,
    this.optionsMaxHeight = 275,
    this.optionsMaxWidth,
    this.fieldDecorationBuilder,
    this.optionsViewBuilder,
    this.enablePredictionsHistory = false,
    this.liteModeHistory = false,
    this.denseMenuTile = true,
    this.menuTileIcon,
    this.menuColor,
    this.menuElevation = 2.0,
    this.menuBorderRadius = 8.0,
  });

  @override
  State<GPlacesAutoComplete> createState() => _GPlacesAutoCompleteState();
}

class _GPlacesAutoCompleteState extends State<GPlacesAutoComplete> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late Iterable<Prediction> _lastPredicitons = <Prediction>[];

  late final Debounceable<Iterable<Prediction>?, String> _debouncedSearch;

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<Prediction>?> _search(String query) async {
    if (_lastPredicitons.contains(Prediction(description: query))) {
      return _lastPredicitons;
    }
    if (_predictionsHistory.contains(Prediction(description: query))) {
      return _predictionsHistory;
    }

    _currentQuery = query;

    late final Iterable<Prediction> predicitions;

    predicitions = await _insertPredicitions(_currentQuery!);

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return predicitions;
  }

  List<Prediction> _predictionsHistory = [];
  Future<void> getPredictionsHistory() async {
    if (!widget.enablePredictionsHistory) {
      return;
    }
    _predictionsHistory =
        await GooglePlacesService.getPredictionsFromSharedPref() ?? [];
    log("predictionsHistory: $_predictionsHistory");
  }

  void addPredictionToHistoryCallBack(Prediction prediction) {
    if (!widget.enablePredictionsHistory) {
      return;
    }
    if (_predictionsHistory.contains(prediction)) {
      log("prediction already in history: $prediction");
      return;
    }
    // max 5 predictions
    if (_predictionsHistory.length >= 5) {
      _predictionsHistory.removeAt(0);
    }
    _predictionsHistory.add(prediction);
    log("prediction added to history: $prediction");
    GooglePlacesService.savePrediction(prediction,
        liteMode: widget.liteModeHistory);
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = debounce<Iterable<Prediction>?, String>(_search,
        debounceDuration: Duration(milliseconds: widget.debounceTime));
    getPredictionsHistory();
  }

  static String _displayStringForPredicition(Prediction prediction) =>
      prediction.description ?? '';

  @override
  Widget build(BuildContext context) {
    double defaultFieldAndMenuWidth = MediaQuery.sizeOf(context).width * 0.9;
    return Autocomplete<Prediction>(
      displayStringForOption: _displayStringForPredicition,
      fieldViewBuilder: (BuildContext context, TextEditingController controller,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return SizedBox(
          width: widget.optionsMaxWidth ?? defaultFieldAndMenuWidth,
          child: TextFormField(
            decoration: widget.fieldDecorationBuilder
                    ?.call(_isSearching, _apiException) ??
                _defaultInputDecoration().copyWith(
                  errorText: _apiException
                      ? 'An error occurred while searching for places.'
                      : null,
                  prefixIcon: _isSearching
                      ? Transform.scale(
                          scale: 0.5,
                          child: const CircularProgressIndicator(),
                        )
                      : null,
                ),
            controller: controller,
            focusNode: focusNode,
            onFieldSubmitted: (_) {
              onFieldSubmitted();
            },
          ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return _predictionsHistory;
        }
        final Iterable<Prediction>? options =
            await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastPredicitons;
        }
        _lastPredicitons = options;
        return options;
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (widget.optionsViewBuilder != null) {
          return widget.optionsViewBuilder!.call(context, onSelected, options);
        }
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: widget.menuElevation,
            color: widget.menuColor,
            borderRadius: BorderRadius.circular(widget.menuBorderRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: widget.optionsMaxHeight,
                  maxWidth: widget.optionsMaxWidth ?? defaultFieldAndMenuWidth),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Prediction prediction = options.elementAt(index);

                  return InkWell(
                    child: Builder(builder: (context) {
                      final bool highlight =
                          AutocompleteHighlightedOption.of(context) == index;
                      if (highlight) {
                        SchedulerBinding.instance.addPostFrameCallback(
                            (Duration timeStamp) {
                          Scrollable.ensureVisible(context, alignment: 0.5);
                        }, debugLabel: 'AutocompleteOptions.ensureVisible');
                      }
                      return widget.menuTileBuilder
                              ?.call(context, prediction) ??
                          ListTile(
                            onTap: () {
                              onSelected(prediction);
                              widget.onItemSelected?.call(prediction);
                              addPredictionToHistoryCallBack(prediction);
                            },
                            tileColor:
                                highlight ? Theme.of(context).focusColor : null,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                              top: Radius.circular(
                                  index == 0 ? widget.menuBorderRadius : 0.0),
                              bottom: Radius.circular(
                                  index == options.length - 1
                                      ? widget.menuBorderRadius
                                      : 0.0),
                            )),
                            leading: widget.menuTileIcon,
                            dense: widget.denseMenuTile,
                            title: Text(_displayStringForPredicition(
                                options.elementAt(index))),
                          );
                    }),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSearching = false;
  bool _apiException = false;

  Future<Iterable<Prediction>> _insertPredicitions(String query) async {
    if (query == '') {
      return const Iterable<Prediction>.empty();
    }
    try {
      setState(() {
        _isSearching = true;
      });
      PlaceAutocompleteResponse response =
          await GooglePlacesService.fetchPlaces(query, widget.googleAPIKey,
              countries: widget.countries);

      log('response length: ${response.predictions?.length}');
      return response.predictions ?? [];
    } on Exception {
      setState(() {
        _apiException = true;
      });

      return [];
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  InputDecoration _defaultInputDecoration() {
    return InputDecoration(
      hintText: 'e.g. Paris, France',
      labelText: 'Search for a place',
      prefixIcon: const Icon(Icons.search),
      errorMaxLines: 2,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );
  }
}

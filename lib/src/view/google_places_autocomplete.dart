import 'dart:async';
import 'dart:developer';

import 'package:autocomplete_google_places_widget/src/helpers/debouncer.dart';
import 'package:autocomplete_google_places_widget/src/models/place_autocomplete_response.dart';
import 'package:autocomplete_google_places_widget/src/models/prediction.dart';
import 'package:autocomplete_google_places_widget/src/services/google_places_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that uses the Google Places API to provide places suggestions.
/// The user can select an option from the suggestions, and the selected
/// option will be passed to the [onOptionSelected] callback.
/// The options menu can be customized using the [menuBuilder] and
/// [menuOptionBuilder] parameters.
class GPlacesAutoComplete extends StatefulWidget {
  /// The Google API key to use for the Places API.
  final String googleAPIKey;

  /// A callback that is called when the user selects an option.
  final void Function(Prediction)? onOptionSelected;

  /// A builder for the text field used to input search queries.
  /// If not provided, a default text field will be used.
  ///
  /// Ensure using the provided [TextEditingController], [FocusNode] and [onFieldSubmitted] callback
  /// to make the widget work properly. Check the package example for more details.
  ///
  /// Note: You should not use your own TextEditingController and FocusNode with the [textFormFieldBuilder], instead you can use
  /// the provided TextEditingController and FocusNode provided in [GPlacesAutoComplete] widget.
  final Widget Function(
          BuildContext, TextEditingController, FocusNode, void Function())?
      textFormFieldBuilder;

  /// A builder for the options view.
  final Widget Function(
      BuildContext context,
      AutocompleteOnSelected<Prediction> onSelected,
      Iterable<Prediction> options)? menuBuilder;

  /// A builder for a single option view in the menu.
  final Widget Function(BuildContext context, int index, Prediction prediction)?
      menuOptionBuilder;

  /// The controller for the text field.
  /// If this parameter is not null, then [focusNode] must also be not null.
  final TextEditingController? textEditingController;

  /// The focus node for the text field.
  /// If this parameter is not null, then [textEditingController] must also be
  /// not null.
  final FocusNode? focusNode;

  /// The time (in milliseconds) to wait after the user stops typing
  /// to make the API request.
  final int debounceTime;

  /// The countries to restrict the search to (two-character region code).
  final List<String>? countries;

  /// If true, the predictions will include the latitude and longitude of the
  /// place (an additional API request will be made to get the lat/lng).
  final bool incudeLatLng;

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

  /// If true, the menu option will be dense.
  final bool denseMenuOption;

  /// If true, the predictions history will be saved in shared preferences
  /// and will be displayed in the options menu when the current query is empty
  final bool enableHistory;

  /// if True, The prediction saved will contain only the `placeId`, `description` and `LatLng` (if available)
  final bool liteModeHistory;

  /// A callback that is called when the widget is searching for options.
  /// This can be used to show a loading indicator.
  ///
  /// Example:
  /// ```dart
  /// loadingCallback: (bool loading) {
  ///  if (loading) {
  ///   setState(() {
  ///   _yourLoadingVariable = true;
  ///  });
  /// } else {
  ///  setState(() {
  ///  _yourLoadingVariable = false;
  /// });
  /// }
  final void Function(bool loading)? loadingCallback;

  /// A callback that is called when an API exception occurs.
  /// This can be used to show an error message.
  ///
  /// Example:
  /// ```dart
  /// apiExceptionCallback: (bool apiException) {
  ///  if (apiException) {
  ///   setState(() {
  ///  _yourErrorMsgVariable = "An error occurred while searching for places".
  ///  });
  /// } else {
  ///  setState(() {
  /// _yourErrorMsgVariable = null;
  /// });
  /// }
  final void Function(bool apiExceptionCallback)? apiExceptionCallback;

  /// Creates a new Google Places Autocomplete widget.
  /// The [googleAPIKey] parameter is required.
  const GPlacesAutoComplete(
      {super.key,
      required this.googleAPIKey,
      this.onOptionSelected,
      this.menuOptionBuilder,
      this.textEditingController,
      this.focusNode,
      this.debounceTime = 500,
      this.countries,
      this.incudeLatLng = false,
      this.optionsMaxHeight = 275,
      this.optionsMaxWidth,
      this.textFormFieldBuilder,
      this.menuBuilder,
      this.enableHistory = false,
      this.liteModeHistory = false,
      this.denseMenuOption = true,
      this.menuColor,
      this.menuElevation = 2.0,
      this.menuBorderRadius = 8.0,
      this.loadingCallback,
      this.apiExceptionCallback})
      : assert((focusNode == null) == (textEditingController == null));

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
    if (query.isEmpty) {
      return _predictionsHistory;
    }
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
    if (!widget.enableHistory) {
      return;
    }
    _predictionsHistory =
        await GooglePlacesService.getPredictionsFromSharedPref() ?? [];
    log("predictionsHistory: $_predictionsHistory");
  }

  void addPredictionToHistoryCallBack(Prediction prediction) {
    if (!widget.enableHistory) {
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
    return RawAutocomplete<Prediction>(
      textEditingController: widget.textEditingController,
      focusNode: widget.focusNode,
      displayStringForOption: _displayStringForPredicition,
      fieldViewBuilder: (BuildContext context, TextEditingController controller,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return SizedBox(
          width: widget.optionsMaxWidth ?? defaultFieldAndMenuWidth,
          child: widget.textFormFieldBuilder != null
              ? widget.textFormFieldBuilder!
                  .call(context, controller, focusNode, onFieldSubmitted)
              : TextFormField(
                  decoration: _defaultInputDecoration(),
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: (_) {
                    onFieldSubmitted();
                  },
                ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<Prediction>? options =
            await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastPredicitons;
        }
        _lastPredicitons = options;
        return options;
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (widget.menuBuilder != null) {
          return widget.menuBuilder!.call(context, onSelected, options);
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
                      return widget.menuOptionBuilder
                              ?.call(context, index, prediction) ??
                          ListTile(
                            onTap: () async {
                              onSelected(prediction);
                              if (widget.incudeLatLng) {
                                await GooglePlacesService
                                    .getPlaceDetailsFromPlaceId(
                                  prediction,
                                  widget.googleAPIKey,
                                );
                              }
                              widget.onOptionSelected?.call(prediction);
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
                            dense: widget.denseMenuOption,
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

  Future<Iterable<Prediction>> _insertPredicitions(String query) async {
    if (query == '') {
      return const Iterable<Prediction>.empty();
    }
    widget.apiExceptionCallback?.call(false);

    try {
      widget.loadingCallback?.call(true);
      PlaceAutocompleteResponse response =
          await GooglePlacesService.fetchPlaces(
        query,
        widget.googleAPIKey,
        countries: widget.countries,
      );

      return response.predictions ?? [];
    } on Exception {
      widget.apiExceptionCallback?.call(true);

      return [];
    } finally {
      widget.loadingCallback?.call(false);
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

<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->




A wrapper around Flutter’s default Autocomplete widget that leverages the Google Places API to provide real-time place suggestions as users type.
<img src="https://raw.githubusercontent.com/dhiaCodes/autocomplete_google_places_widget/38abfd4a7b1e101f892b28ca6913d2736fd8f1dd/images/pub_dev_preview.png" width="100%" alt="Package Preview" />


## Features

* 🎨 **Highly Customizable**: Offers extensive customization options to fit your specific needs.
* 🕒 **History Support**: Includes history support for quick access to previous search results.
* 💳 **Session Tokens**: Uses session tokens to group user queries in a single session ensuring efficient billing.
* ⏳ **Debounce**: Implements a debounce mechanism to reduce the frequency of API calls.

## Getting started

Import the package in your Dart file.

```dart
import 'package:autocomplete_google_places_widget/autocomplete_google_places_widget.dart';
```

Add your Google API key in the `GPlacesAutoComplete` widget.

```dart
GPlacesAutoComplete(
            googleAPIKey: _yourGoogleAPIKey,
            ...
          )
```
And you are good to go!

## Usage

The `GPlacesAutoComplete` widget has several parameters that you can use.

```dart
  /// The Google API key to use for the Places API.
  final String googleAPIKey;

  /// A callback that is called when the user selects an option.
  final void Function(Prediction)? onOptionSelected;

  /// A builder for the options view.
  final Widget Function(
      BuildContext context,
      AutocompleteOnSelected<Prediction> onSelected,
      Iterable<Prediction> options)? menuBuilder;

  /// A builder for a single option view in the menu.
  final Widget Function(BuildContext context, int index, Prediction prediction)?
      menuOptionBuilder;

  /// The time (in milliseconds) to wait after the user stops typing
  /// to make the API request.
  final int debounceTime;

  /// A builder for the field decoration. If not provided, a default
  /// decoration will be used. [isSearching] is true when the field is
  /// currently searching for options, and [isAPIException] is true when
  /// an error occurred while searching for options.
  final InputDecoration Function(bool isSearching, bool isAPIException)?
      fieldDecorationBuilder;

  /// The countries to restrict the search to (two-character region code).
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

  /// If true, the menu option will be dense.
  final bool denseMenuOption;

  /// If true, the prediction history will be saved in shared preferences
  /// and will be displayed in the options menu when the current query is empty
  final bool enableHistory;

  /// If True, The prediction saved will contain only the `placeId`, `description`, and `LatLng` (if available)
  final bool liteModeHistory;
```

## Feedback

Please feel free to give me [any feedback](https://github.com/dhiaCodes/autocomplete_google_places_widget/issues) helping support this package!

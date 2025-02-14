import 'dart:convert';
import 'dart:developer';

import 'package:autocomplete_google_places_widget/src/models/place_details.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/place_autocomplete_response.dart';
import '../models/prediction.dart';

class GooglePlacesService {
  static String? sessionToken;

  static Future<PlaceAutocompleteResponse> fetchPlaces(
    String text,
    String googleAPIKey, {
    String? proxyURL,
    List<String>? countries,
    bool useSessionToken = true,
    bool useNewPlacesAPI = false,
    List<String> types = const [],
  }) async {
    final prefix = proxyURL ?? "";
    final Dio dio = Dio();

    PlaceAutocompleteResponse subscriptionResponse;

    if (useSessionToken && sessionToken == null) {
      var uuid = const Uuid();
      sessionToken = uuid.v4();
    }
    log("Inside getLocation: $text");

    if (useNewPlacesAPI) {
      String url =
          "${prefix}https://places.googleapis.com/v1/places:autocomplete";

      Map<String, dynamic> requestBody = {"input": text};

      if (countries != null) {
        requestBody["includedRegionCodes"] = countries;
      }
      if (sessionToken != null) {
        requestBody["sessionToken"] = sessionToken;
      }
      if (types.isNotEmpty) {
        requestBody["includedPrimaryTypes"] = types;
      }

      final response = await dio.post(url,
          options: Options(
            headers: {"X-Goog-Api-Key": googleAPIKey},
          ),
          data: jsonEncode(requestBody));
      subscriptionResponse =
          PlaceAutocompleteResponse.fromJsonNewApi(response.data);
    } else {
      String url =
          "${prefix}https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=$googleAPIKey";

      if (countries != null) {
        for (int i = 0; i < countries.length; i++) {
          final country = countries[i];

          if (i == 0) {
            url = "$url&components=country:$country";
          } else {
            url = "$url|country:$country";
          }
        }
      }

      if (types.isNotEmpty) {
        url += "&types=${types.join('|')}";
      }

      if (sessionToken != null) {
        url += "&sessiontoken=$sessionToken";
      }
      log("sessionToken: $sessionToken");
      final response = await dio.get(url);

      subscriptionResponse = PlaceAutocompleteResponse.fromJson(response.data);
    }

    return subscriptionResponse;
  }

  static Future<Prediction> getPlaceDetailsFromPlaceId(
    Prediction prediction,
    String? googleAPIKey, {
    String? proxyURL,
  }) async {
    try {
      final prefix = proxyURL ?? "";
      final Dio dio = Dio();

      final url =
          "${prefix}https://maps.googleapis.com/maps/api/place/details/json?placeid=${prediction.placeId}${googleAPIKey != null ? "&key=$googleAPIKey" : ""}";
      final response = await dio.get(
        url,
      );

      final placeDetails = PlaceDetails.fromJson(response.data);

      prediction.lat = placeDetails.result?.geometry?.location?.lat.toString();
      prediction.lng = placeDetails.result?.geometry?.location?.lng.toString();

      return prediction;
    } catch (e) {
      return prediction;
    }
  }

  static const predictionHistoryKey = "predictionHistory";

  /// [Prediction] will be saved in shared preferences
  static Future<void> savePrediction(Prediction prediction,
      {bool? liteMode}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = prediction.toJson();

    if (liteMode ?? false) {
      json.removeWhere((key, value) =>
          key != "description" &&
          key != "place_id" &&
          key != "lat" &&
          key != "lng");
    }
    json.removeWhere((key, value) => value == null);
    String jsonString = jsonEncode(json);
    // Get the current list of predictions
    List<String> currentPredictions =
        prefs.getStringList(predictionHistoryKey) ?? [];
    // max 5 predictions
    if (currentPredictions.length >= 5) {
      currentPredictions.removeAt(0);
    }
    // Add the new prediction to the list
    currentPredictions.add(jsonString);
    // Save the updated list
    prefs.setStringList(predictionHistoryKey, currentPredictions);
    log("History saved: $jsonString");
  }

  /// Get the previous predictions from shared preferences
  static Future<List<Prediction>?> getPredictionsFromSharedPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(predictionHistoryKey);
    log("History fetched: $json");
    if (json == null) {
      return null;
    }
    return json.map((e) => Prediction.fromJson(jsonDecode(e))).toList();
  }
}

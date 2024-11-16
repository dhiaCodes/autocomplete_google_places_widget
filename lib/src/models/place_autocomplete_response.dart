import 'prediction.dart';

class PlaceAutocompleteResponse {
  List<Prediction>? predictions;
  String? status;

  PlaceAutocompleteResponse({this.predictions, this.status});

  PlaceAutocompleteResponse.fromJson(Map<String, dynamic> json) {
    if (json['predictions'] != null) {
      predictions = [];
      json['predictions'].forEach((v) {
        predictions!.add(Prediction.fromJson(v));
      });
    }
    status = json['status'];
  }
  PlaceAutocompleteResponse.fromJsonNewApi(Map<String, dynamic> json) {
    if (json['suggestions'] != null && json['suggestions'].length > 0) {
      predictions = [];
      json['suggestions'].forEach((v) {
        if (v['placePrediction'] != null) {
          predictions!.add(Prediction.fromJsonNewApi(v['placePrediction']));
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (predictions != null) {
      data['predictions'] = predictions!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    return data;
  }
}

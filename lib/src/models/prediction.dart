import 'package:autocomplete_google_places_widget/src/models/place_details.dart';

import 'matched_substrings.dart';
import 'structured_formatting.dart';
import 'term.dart';

class Prediction {
  String? description;
  String? id;
  List<MatchedSubstring>? matchedSubstrings;
  String? placeId;
  String? reference;
  StructuredFormatting? structuredFormatting;
  List<Term>? terms;
  List<String>? types;
  PlaceDetails? details;

  bool get hasLatLng =>
      details?.result?.geometry?.location?.lat != null &&
      details?.result?.geometry?.location?.lng != null;

  double? get lat {
    return details?.result?.geometry?.location?.lat;
  }

  double? get lng {
    return details?.result?.geometry?.location?.lng;
  }

  String? get getPostalCode {
    List<AddressComponents> addressComponents =
        details?.result?.addressComponents ?? [];

    for (final component in addressComponents) {
      if (component.types?.contains('postal_code') == true) {
        return component.longName;
      }
    }

    return null;
  }

  Prediction({
    this.description,
    this.id,
    this.matchedSubstrings,
    this.placeId,
    this.reference,
    this.structuredFormatting,
    this.terms,
    this.types,
    this.details,
  });

  Prediction.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    id = json['id'];
    if (json['matched_substrings'] != null) {
      matchedSubstrings = [];
      json['matched_substrings'].forEach((v) {
        matchedSubstrings!.add(MatchedSubstring.fromJson(v));
      });
    }
    placeId = json['place_id'];
    reference = json['reference'];
    structuredFormatting = json['structured_formatting'] != null
        ? StructuredFormatting?.fromJson(json['structured_formatting'])
        : null;
    if (json['terms'] != null) {
      terms = [];
      json['terms'].forEach((v) {
        terms!.add(Term.fromJson(v));
      });
    }
    types = json['types']?.cast<String>();
  }
  Prediction.fromJsonNewApi(Map<String, dynamic> json) {
    placeId = json['placeId'];
    description = json['text'] != null ? json['text']['text'] : null;
    structuredFormatting = json['structuredFormat'] != null
        ? StructuredFormatting.fromJsonNewApi(json['structuredFormat'])
        : null;
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['id'] = id;
    if (matchedSubstrings != null) {
      data['matched_substrings'] =
          matchedSubstrings!.map((v) => v.toJson()).toList();
    }
    data['place_id'] = placeId;
    data['reference'] = reference;
    if (structuredFormatting != null) {
      data['structured_formatting'] = structuredFormatting!.toJson();
    }
    if (terms != null) {
      data['terms'] = terms!.map((v) => v.toJson()).toList();
    }
    data['types'] = types;

    data['details'] = details?.toJson();

    return data;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Prediction &&
        other.id == id &&
        other.description == description;
  }

  @override
  int get hashCode => id.hashCode ^ description.hashCode;
}

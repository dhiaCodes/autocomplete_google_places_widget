class StructuredFormatting {
  String? mainText;

  String? secondaryText;

  StructuredFormatting({this.mainText, this.secondaryText});

  StructuredFormatting.fromJson(Map<String, dynamic> json) {
    mainText = json['main_text'];

    secondaryText = json['secondary_text'];
  }
  StructuredFormatting.fromJsonNewApi(Map<String, dynamic> json) {
    mainText = json['mainText'] != null ? json['mainText']['text'] : null;
    secondaryText =
        json['secondaryText'] != null ? json['secondaryText']['text'] : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['main_text'] = mainText;
    data['secondary_text'] = secondaryText;
    return data;
  }
}

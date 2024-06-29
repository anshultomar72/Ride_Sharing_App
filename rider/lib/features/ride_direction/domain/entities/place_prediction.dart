class PlacePrediction {
  String description = "";
  String place_id = "";

  PlacePrediction({this.description = "", this.place_id = ""});

  PlacePrediction.fromJson(Map<String, dynamic> json) {
    description = json["description"];
    place_id = json["place_id"];
  }
}
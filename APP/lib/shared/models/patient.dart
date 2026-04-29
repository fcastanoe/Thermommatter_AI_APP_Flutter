import 'dart:convert';

class Patient {
  final String first;
  final String last;
  final int age;
  final double weight;
  final double height;

  Patient({
    required this.first,
    required this.last,
    required this.age,
    required this.weight,
    required this.height,
  });

  String get folderName => '${first}_$last';

  Map<String, dynamic> toJson() => {
        'first': first,
        'last': last,
        'age': age,
        'weight': weight,
        'height': height,
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        first: json['first'] as String,
        last: json['last'] as String,
        age: json['age'] as int,
        weight: (json['weight'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  static Patient fromJsonString(String s) => Patient.fromJson(jsonDecode(s));
  String toJsonString() => jsonEncode(toJson());
}

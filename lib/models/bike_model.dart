// lib/models/bike_model.dart

class BikeModel {
  final String id;
  final String name;
  final String imageUrl;
  final String tagline;
  final int engineCC;
  final int horsepower;

  const BikeModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.tagline,
    required this.engineCC,
    required this.horsepower,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'tagline': tagline,
    'engineCC': engineCC,
    'horsepower': horsepower,
  };

  factory BikeModel.fromJson(Map<String, dynamic> json) => BikeModel(
    id: json['id'] as String,
    name: json['name'] as String,
    imageUrl: json['imageUrl'] as String,
    tagline: json['tagline'] as String,
    engineCC: json['engineCC'] as int,
    horsepower: json['horsepower'] as int,
  );

  static List<BikeModel> get availableBikes => const [
    BikeModel(
      id: 'ns-200',
      name: 'NS 200',
      imageUrl: 'asset/ns.png',
      tagline: 'Born to Race',
      engineCC: 200,
      horsepower: 19,
    ),
    BikeModel(
      id: 'unicorn-160',
      name: 'Unicorn',
      imageUrl: 'asset/unicorn.png',
      tagline: 'Make Life a Ride',
      engineCC: 160,
      horsepower: 14,
    ),
  ];
}

// lib/models/bike_model.dart

class BikeModel {
  final String id;
  final String name;
  final String brandName;
  final String imageUrl;
  final String tagline;
  final num engineCC;
  final num horsepower;

  const BikeModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.tagline,
    required this.engineCC,
    required this.horsepower,
    required this.brandName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'tagline': tagline,
    'engineCC': engineCC,
    'horsepower': horsepower,
    'brandName': brandName,
  };

  factory BikeModel.fromJson(Map<String, dynamic> json) => BikeModel(
    id: json['id'] as String,
    name: json['name'] as String,
    imageUrl: json['imageUrl'] as String,
    tagline: json['tagline'] as String,
    engineCC: json['engineCC'] ,
    horsepower: json['horsepower'],
    brandName: json['brandName'],
  );

  static List<BikeModel> get availableBikes => const [
    BikeModel(
      id: 'ns-200',
      name: 'NS 200',
      imageUrl: 'asset/ns.png',
      tagline: 'Born to Race',
      engineCC: 199.5,
      horsepower: 24.5,
      brandName: 'Bajaj Pulsar',
    ),
    BikeModel(
      id: 'unicorn-160',
      name: 'Unicorn',
      imageUrl: 'asset/unicorn.png',
      tagline: 'Make Life a Ride',
      engineCC: 162.71,
      horsepower: 12.73,
      brandName: 'Honda',
    ),
  ];
}

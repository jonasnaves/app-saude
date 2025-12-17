class DrugModel {
  final String id;
  final String name;
  final String dosage;
  final String category;
  final double? price;

  DrugModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.category,
    this.price,
  });

  factory DrugModel.fromJson(Map<String, dynamic> json) {
    return DrugModel(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      category: json['category'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }
}


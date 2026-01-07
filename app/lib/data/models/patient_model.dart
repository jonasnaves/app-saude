class PatientAddress {
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;

  PatientAddress({
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  factory PatientAddress.fromJson(Map<String, dynamic> json) {
    return PatientAddress(
      street: json['street'] ?? '',
      number: json['number'] ?? '',
      complement: json['complement'],
      neighborhood: json['neighborhood'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }
}

class PatientDocument {
  final String id;
  final String name;
  final String type;
  final String url;
  final DateTime uploadedAt;
  final int? size;

  PatientDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedAt,
    this.size,
  });

  factory PatientDocument.fromJson(Map<String, dynamic> json) {
    return PatientDocument(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt']),
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      'size': size,
    };
  }
}

class PatientModel {
  final String id;
  // Dados pessoais
  final String name;
  final String? cpf;
  final String? rg;
  final DateTime? birthDate;
  final String? gender; // 'M', 'F', 'O', 'N'
  final String? phone;
  final String? email;

  // Endereço
  final PatientAddress? address;

  // Informações de saúde
  final List<String>? allergies;
  final String? medicalHistory;
  final List<String>? currentMedications;
  final List<String>? chronicConditions;

  // Contatos de emergência
  final List<EmergencyContact>? emergencyContacts;

  // Arquivos
  final List<String> photos;
  final List<PatientDocument> documents;

  // Metadados
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  PatientModel({
    required this.id,
    required this.name,
    this.cpf,
    this.rg,
    this.birthDate,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.allergies,
    this.medicalHistory,
    this.currentMedications,
    this.chronicConditions,
    this.emergencyContacts,
    required this.photos,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cpf: json['cpf'],
      rg: json['rg'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'] != null ? PatientAddress.fromJson(json['address']) : null,
      allergies: json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      medicalHistory: json['medicalHistory'],
      currentMedications:
          json['currentMedications'] != null ? List<String>.from(json['currentMedications']) : null,
      chronicConditions:
          json['chronicConditions'] != null ? List<String>.from(json['chronicConditions']) : null,
      emergencyContacts: json['emergencyContacts'] != null
          ? (json['emergencyContacts'] as List).map((e) => EmergencyContact.fromJson(e)).toList()
          : null,
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      documents: json['documents'] != null
          ? (json['documents'] as List).map((e) => PatientDocument.fromJson(e)).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
    };

    // Adicionar campos opcionais apenas se não forem null
    if (cpf != null) json['cpf'] = cpf;
    if (rg != null) json['rg'] = rg;
    if (birthDate != null) json['birthDate'] = birthDate!.toIso8601String();
    if (gender != null) json['gender'] = gender;
    if (phone != null) json['phone'] = phone;
    if (email != null) json['email'] = email;
    if (address != null) json['address'] = address!.toJson();
    if (allergies != null) json['allergies'] = allergies;
    if (medicalHistory != null) json['medicalHistory'] = medicalHistory;
    if (currentMedications != null) json['currentMedications'] = currentMedications;
    if (chronicConditions != null) json['chronicConditions'] = chronicConditions;
    if (emergencyContacts != null) {
      json['emergencyContacts'] = emergencyContacts!.map((e) => e.toJson()).toList();
    }
    if (photos.isNotEmpty) json['photos'] = photos;
    if (documents.isNotEmpty) {
      json['documents'] = documents.map((e) => e.toJson()).toList();
    }
    json['createdAt'] = createdAt.toIso8601String();
    json['updatedAt'] = updatedAt.toIso8601String();
    if (createdBy != null) json['createdBy'] = createdBy;

    return json;
  }

  // Helper para calcular idade
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // Helper para obter foto principal ou avatar
  String? get mainPhoto => photos.isNotEmpty ? photos.first : null;
}


class CreateFeatureRequestDto {
  final String description;

  CreateFeatureRequestDto({required this.description});

  Map<String, dynamic> toJson() {
    return {'description': description};
  }
}

class Site {
  final String id;
  final String name;
  final bool isActive;

  const Site({required this.id, required this.name, this.isActive = true});

  factory Site.fromMap(Map<String, dynamic> data, String documentId) {
    return Site(
      id: documentId,
      name: data['name'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'isActive': isActive};
  }
}

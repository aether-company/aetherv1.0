class ActivityModel {
  final String title;
  final String type;
  final bool isAutoTracked;

  ActivityModel({
    required this.title,
    required this.type,
    required this.isAutoTracked,
  });

  // Convert to Firestore-ready map
  Map<String, dynamic> toMap() {
    return {'title': title, 'type': type, 'isAutoTracked': isAutoTracked};
  }

  // Create from Firestore map
  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      isAutoTracked: map['isAutoTracked'] ?? false,
    );
  }
}

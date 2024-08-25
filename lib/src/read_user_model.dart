class ReadUserModel {
  final String profile;
  final String title;
  final String subtitle;
  final bool showBadge;

  ReadUserModel({
    required this.profile,
    required this.title,
    required this.subtitle,
    required this.showBadge,
  });

  // Convert a ReadUserModel to a Map.
  Map<String, dynamic> toMap() {
    return {
      'profile': profile,
      'title': title,
      'subtitle': subtitle,
      'showBadge': showBadge,
    };
  }

  // Convert a Map to a ReadUserModel.
  factory ReadUserModel.fromMap(Map<String, dynamic> map) {
    return ReadUserModel(
      profile: map['profile'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      showBadge: map['showBadge'] ?? false,
    );
  }

  // If you're dealing with JSON, you might want to add these:
  factory ReadUserModel.fromJson(Map<String, dynamic> json) {
    return ReadUserModel(
      profile: json['profile'],
      title: json['title'],
      subtitle: json['subtitle'],
      showBadge: json['showBadge'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile,
      'title': title,
      'subtitle': subtitle,
      'showBadge': showBadge,
    };
  }
}

import 'user_model.dart';

class Site {
  final int id;
  final String name;
  final String latitude;
  final String longitude;
  final String address;
  final String company;
  final String? startDate;
  final String? endDate;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int pinned;
  final Pivot? pivot;
  final List<SiteImage> siteImages;
  final List<UserInSite> users;

  Site({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.company,
    this.startDate,
    this.endDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.pinned,
    this.pivot,
    required this.siteImages,
    this.users = const [],
  });

  Site copyWith({
    int? id,
    String? name,
    String? latitude,
    String? longitude,
    String? address,
    String? company,
    String? startDate,
    String? endDate,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    int? pinned,
    Pivot? pivot,
    List<SiteImage>? siteImages,
    List<UserInSite>? users,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      company: company ?? this.company,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pinned: pinned ?? this.pinned,
      pivot: pivot ?? this.pivot,
      siteImages: siteImages ?? this.siteImages,
      users: users ?? this.users,
    );
  }

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      company: json['company'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      pinned: json['pinned'] ?? 0,
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null,
      siteImages: (json['site_images'] as List<dynamic>?)?.map((img) => SiteImage.fromJson(img)).toList() ?? [],
      users: (json['users'] as List<dynamic>?)?.map((u) => UserInSite.fromJson(u)).toList() ?? [],
    );
  }
}

class Pivot {
  final int userId;
  final int siteId;

  Pivot({required this.userId, required this.siteId});

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      userId: json['user_id'],
      siteId: json['site_id'],
    );
  }
}

class SiteImage {
  final int id;
  final String imageUrl;

  SiteImage({required this.id, required this.imageUrl});

  factory SiteImage.fromJson(Map<String, dynamic> json) {
    return SiteImage(
      id: json['id'],
      imageUrl: json['image_url'],
    );
  }
}

class UserInSite {
  final int id;
  final String name;
  final String? imagePath;
  final Pivot? pivot;

  UserInSite({required this.id, required this.name, this.imagePath, this.pivot});

  factory UserInSite.fromJson(Map<String, dynamic> json) {
    return UserInSite(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imagePath: json['image_path'],
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null,
    );
  }
} 
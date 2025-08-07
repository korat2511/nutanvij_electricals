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
  // Additional fields from API
  final int? categoryId;
  final int? minRange;
  final int? maxRange;
  final int? createdBy;
  final dynamic category;

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
    this.categoryId,
    this.minRange,
    this.maxRange,
    this.createdBy,
    this.category,
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
    int? categoryId,
    int? minRange,
    int? maxRange,
    int? createdBy,
    dynamic category,
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
      categoryId: categoryId ?? this.categoryId,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
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
      categoryId: json['category_id'],
      minRange: json['min_range'],
      maxRange: json['max_range'],
      createdBy: json['created_by'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'company': company,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'pinned': pinned,
      'pivot': pivot?.toJson(),
      'site_images': siteImages.map((img) => img.toJson()).toList(),
      'users': users.map((user) => user.toJson()).toList(),
      'category_id': categoryId,
      'min_range': minRange,
      'max_range': maxRange,
      'created_by': createdBy,
      'category': category,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'site_id': siteId,
    };
  }
}

class SiteImage {
  final int id;
  final String imageUrl;
  final int siteId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? image; // Original image field from API

  SiteImage({
    required this.id,
    required this.imageUrl,
    required this.siteId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.image,
  });

  factory SiteImage.fromJson(Map<String, dynamic> json) {
    return SiteImage(
      id: json['id'],
      imageUrl: json['image_url'] ?? '',
      siteId: json['site_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'site_id': siteId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'image': image,
    };
  }
}

class UserInSite {
  final int id;
  final String name;
  final String? imagePath;
  final Pivot? pivot;
  final int hasKeypadMobile;
  final String? lastStatus;

  UserInSite({
    required this.id,
    required this.name,
    this.imagePath,
    this.pivot,
    this.hasKeypadMobile = 0,
    this.lastStatus,
  });

  UserInSite copyWith({
    int? id,
    String? name,
    String? imagePath,
    Pivot? pivot,
    int? hasKeypadMobile,
    String? lastStatus,
  }) {
    return UserInSite(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      pivot: pivot ?? this.pivot,
      hasKeypadMobile: hasKeypadMobile ?? this.hasKeypadMobile,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }

  factory UserInSite.fromJson(Map<String, dynamic> json) {
    return UserInSite(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imagePath: json['image_path'],
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null,
      hasKeypadMobile: json['has_keypad_mobile'] ?? 0,
      lastStatus: json['last_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'pivot': pivot?.toJson(),
      'has_keypad_mobile': hasKeypadMobile,
      'last_status': lastStatus,
    };
  }
} 
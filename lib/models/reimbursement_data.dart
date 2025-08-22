class ReimbursementSummary {
  final int total;
  final int review;
  final int approved;
  final int rejected;
  final int paided;
  final int unpaid;

  ReimbursementSummary({
    required this.total,
    required this.review,
    required this.approved,
    required this.rejected,
    required this.paided,
    required this.unpaid,
  });

  factory ReimbursementSummary.fromJson(Map<String, dynamic> json) {
    return ReimbursementSummary(
      total: json['total'] ?? 0,
      review: json['review'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      paided: json['paided'] ?? 0,
      unpaid: json['unpaid'] ?? 0,
    );
  }
}

class ReimbursementImage {
  final int id;
  final int employeeExpenseId;
  final String image;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String imagePath;

  ReimbursementImage({
    required this.id,
    required this.employeeExpenseId,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.imagePath,
  });

  factory ReimbursementImage.fromJson(Map<String, dynamic> json) {
    return ReimbursementImage(
      id: json['id'] ?? 0,
      employeeExpenseId: json['employee_expense_id'] ?? 0,
      image: json['image']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
      imagePath: json['image_path']?.toString() ?? '',
    );
  }
}

class ApprovedBy {
  final int id;
  final String name;
  final String? imagePath;
  final String? addharCardFrontPath;
  final String? addharCardBackPath;
  final String? panCardImagePath;
  final String? passbookImagePath;

  ApprovedBy({
    required this.id,
    required this.name,
    this.imagePath,
    this.addharCardFrontPath,
    this.addharCardBackPath,
    this.panCardImagePath,
    this.passbookImagePath,
  });

  factory ApprovedBy.fromJson(Map<String, dynamic> json) {
    return ApprovedBy(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      imagePath: json['image_path']?.toString(),
      addharCardFrontPath: json['addhar_card_front_path']?.toString(),
      addharCardBackPath: json['addhar_card_back_path']?.toString(),
      panCardImagePath: json['pan_card_image_path']?.toString(),
      passbookImagePath: json['passbook_image_path']?.toString(),
    );
  }
}

class ReimbursementData {
  final int id;
  final int userId;
  final String title;
  final String amount;
  final String description;
  final String status;
  final String? approvedAmount;
  final String expenseDate;
  final String? approvedAt;
  final ApprovedBy? approvedBy;
  final String? adminReason;
  final String paymentStatus;
  final int salaryId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<ReimbursementImage> employeeExpenseImages;

  ReimbursementData({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.description,
    required this.status,
    this.approvedAmount,
    required this.expenseDate,
    this.approvedAt,
    this.approvedBy,
    this.adminReason,
    required this.paymentStatus,
    required this.salaryId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.employeeExpenseImages,
  });

  factory ReimbursementData.fromJson(Map<String, dynamic> json) {
    return ReimbursementData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      approvedAmount: json['approved_amount']?.toString(),
      expenseDate: json['expense_date']?.toString() ?? '',
      approvedAt: json['approved_at']?.toString(),
      approvedBy: json['approved_by'] != null ? ApprovedBy.fromJson(json['approved_by']) : null,
      adminReason: json['admin_reason']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      salaryId: json['salary_id'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
      employeeExpenseImages: (json['employee_expense_images'] as List?)
          ?.map((image) => ReimbursementImage.fromJson(image))
          .toList() ?? [],
    );
  }

  String get formattedAmount {
    final amt = double.tryParse(amount) ?? 0.0;
    return '₹${amt.toStringAsFixed(2)}';
  }

  String get formattedApprovedAmount {
    if (approvedAmount == null) return 'N/A';
    final amt = double.tryParse(approvedAmount!) ?? 0.0;
    return '₹${amt.toStringAsFixed(2)}';
  }

  String get formattedExpenseDate {
    try {
      final DateTime date = DateTime.parse(expenseDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return expenseDate;
    }
  }

  String get formattedApprovedAt {
    if (approvedAt == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(approvedAt!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return approvedAt!;
    }
  }
}

class ReimbursementResponse {
  final ReimbursementSummary summary;
  final List<ReimbursementData> reimbursements;

  ReimbursementResponse({
    required this.summary,
    required this.reimbursements,
  });

  factory ReimbursementResponse.fromJson(Map<String, dynamic> json) {
    return ReimbursementResponse(
      summary: ReimbursementSummary.fromJson(json),
      reimbursements: (json['reimbursements'] as List?)
          ?.map((item) => ReimbursementData.fromJson(item))
          .toList() ?? [],
    );
  }
}
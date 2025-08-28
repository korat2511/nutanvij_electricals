class ManpowerEntryModel {
  final int contractorId;
  final int shift;
  final int skillWorker;
  final int unskillWorker;
  final int skillPayPerHead;
  final int unskillPayPerHead;

  ManpowerEntryModel({
    required this.contractorId,
    required this.shift,
    required this.skillWorker,
    required this.unskillWorker,
    required this.skillPayPerHead,
    required this.unskillPayPerHead,
  });

  Map<String, dynamic> toJson() {
    return {
      'contractor_id': contractorId,
      'shift': shift,
      'skill_worker': skillWorker,
      'unskill_worker': unskillWorker,
      'skill_pay_per_head': skillPayPerHead,
      'unskill_pay_per_head': unskillPayPerHead,
    };
  }

  factory ManpowerEntryModel.fromJson(Map<String, dynamic> json) {
    return ManpowerEntryModel(
      contractorId: json['contractor_id'] is int
          ? json['contractor_id']
          : int.tryParse(json['contractor_id'].toString()) ?? 0,
      shift: json['shift'] is int
          ? json['shift']
          : int.tryParse(json['shift'].toString()) ?? 1,
      skillWorker: json['skill_worker'] is int
          ? json['skill_worker']
          : int.tryParse(json['skill_worker'].toString()) ?? 0,
      unskillWorker: json['unskill_worker'] is int
          ? json['unskill_worker']
          : int.tryParse(json['unskill_worker'].toString()) ?? 0,
      skillPayPerHead: _parseIntFromString(json['skill_pay_per_head']) ?? 0,
      unskillPayPerHead: _parseIntFromString(json['unskill_pay_per_head']) ?? 0,
    );
  }

  ManpowerEntryModel copyWith({
    int? contractorId,
    String? categoryName,
    int? shift,
    int? skillWorker,
    int? unskillWorker,
    int? skillPayPerHead,
    int? unskillPayPerHead,
  }) {
    return ManpowerEntryModel(
      contractorId: contractorId ?? this.contractorId,
      shift: shift ?? this.shift,
      skillWorker: skillWorker ?? this.skillWorker,
      unskillWorker: unskillWorker ?? this.unskillWorker,
      skillPayPerHead: skillPayPerHead ?? this.skillPayPerHead,
      unskillPayPerHead: unskillPayPerHead ?? this.unskillPayPerHead,
    );
  }

  String get shiftText {
    switch (shift) {
      case 1:
        return 'Day';
      case 2:
        return 'Night';
      case 3:
        return 'Day Night';
      default:
        return 'Day';
    }
  }

  static int? _parseIntFromString(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Handle string values like "250.00" or "0.00"
      final cleanValue = value.replaceAll('.00', '');
      return int.tryParse(cleanValue);
    }
    return null;
  }
}

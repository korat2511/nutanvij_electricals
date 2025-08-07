class PaymentData {
  final int id;
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String section;
  final String department;
  final String modeOfPayment;
  final String actualSalary;
  final String expense;
  final String grossSalary;
  final String rate;
  final int workingDays;
  final int workedDays;
  final String grossBasicDa;
  final String grossHra;
  final String performance;
  final String basicDa;
  final String hra;
  final String performance2;
  final String payableSalary;
  final String professionalTax;
  final String pfStatus;
  final String pf;
  final String esi;
  final String tds;
  final String otherDeduction;
  final String totalDeduction;
  final String netPayableSalary;
  final String otPerHr;
  final int ot;
  final String totalOt;
  final String actualExp;
  final String expenseDiff;
  final String bankName;
  final String? bankAccountNumber;
  final String ifscCode;
  final String salaryBankName;
  final String salaryAccountNo;
  final String salaryIfscCode;
  final int month;
  final int year;
  final String status;
  final String createdAt;
  final String updatedAt;

  PaymentData({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.section,
    required this.department,
    required this.modeOfPayment,
    required this.actualSalary,
    required this.expense,
    required this.grossSalary,
    required this.rate,
    required this.workingDays,
    required this.workedDays,
    required this.grossBasicDa,
    required this.grossHra,
    required this.performance,
    required this.basicDa,
    required this.hra,
    required this.performance2,
    required this.payableSalary,
    required this.professionalTax,
    required this.pfStatus,
    required this.pf,
    required this.esi,
    required this.tds,
    required this.otherDeduction,
    required this.totalDeduction,
    required this.netPayableSalary,
    required this.otPerHr,
    required this.ot,
    required this.totalOt,
    required this.actualExp,
    required this.expenseDiff,
    required this.bankName,
    this.bankAccountNumber,
    required this.ifscCode,
    required this.salaryBankName,
    required this.salaryAccountNo,
    required this.salaryIfscCode,
    required this.month,
    required this.year,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'],
      employeeId: json['employee_id'],
      employeeCode: json['employee_code']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      modeOfPayment: json['mode_of_payment']?.toString() ?? '',
      actualSalary: json['actual_salary']?.toString() ?? '0.00',
      expense: json['expense']?.toString() ?? '0.00',
      grossSalary: json['gross_salary']?.toString() ?? '0.00',
      rate: json['rate']?.toString() ?? '0.00',
      workingDays: json['working_days'] ?? 0,
      workedDays: json['worked_days'] ?? 0,
      grossBasicDa: json['gross_basic_da']?.toString() ?? '0.00',
      grossHra: json['gross_hra']?.toString() ?? '0.00',
      performance: json['performance']?.toString() ?? '0.00',
      basicDa: json['basic_da']?.toString() ?? '0.00',
      hra: json['hra']?.toString() ?? '0.00',
      performance2: json['performance_2']?.toString() ?? '0.00',
      payableSalary: json['payable_salary']?.toString() ?? '0.00',
      professionalTax: json['professional_tax']?.toString() ?? '0.00',
      pfStatus: json['pf_status']?.toString() ?? 'NO',
      pf: json['pf']?.toString() ?? '0.00',
      esi: json['esi']?.toString() ?? '0.00',
      tds: json['tds']?.toString() ?? '0.00',
      otherDeduction: json['other_deduction']?.toString() ?? '0.00',
      totalDeduction: json['total_deduction']?.toString() ?? '0.00',
      netPayableSalary: json['net_payable_salary']?.toString() ?? '0.00',
      otPerHr: json['ot_per_hr']?.toString() ?? '0.00',
      ot: json['ot'] ?? 0,
      totalOt: json['total_ot']?.toString() ?? '0.00',
      actualExp: json['actual_exp']?.toString() ?? '0.00',
      expenseDiff: json['expense_diff']?.toString() ?? '0.00',
      bankName: json['bank_name']?.toString() ?? '',
      bankAccountNumber: json['bank_account_number']?.toString(),
      ifscCode: json['ifsc_code']?.toString() ?? '',
      salaryBankName: json['salary_bank_name']?.toString() ?? '',
      salaryAccountNo: json['salary_account_no']?.toString() ?? '',
      salaryIfscCode: json['salary_ifsc_code']?.toString() ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2025,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String get formattedNetSalary {
    final amount = double.tryParse(netPayableSalary) ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedPayableSalary {
    final amount = double.tryParse(payableSalary) ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedGrossSalary {
    final amount = double.tryParse(grossSalary) ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedTotalDeduction {
    final amount = double.tryParse(totalDeduction) ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }
} 
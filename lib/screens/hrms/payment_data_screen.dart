import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/payment_data.dart';
import '../../widgets/custom_button.dart';
import 'reimbursement_screen.dart';

class PaymentDataScreen extends StatefulWidget {
  const PaymentDataScreen({Key? key}) : super(key: key);

  @override
  State<PaymentDataScreen> createState() => _PaymentDataScreenState();
}

class _PaymentDataScreenState extends State<PaymentDataScreen> {
  List<PaymentData> _paymentData = [];
  bool _isLoading = true;
  String? _error;

  // Month and year selection
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';

      final paymentData = await ApiService().getPaymentData(
        context: context,
        apiToken: apiToken,
        month: _selectedMonth,
        year: _selectedYear,
      );

      setState(() {
        _paymentData = paymentData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<void> _selectMonth() async {
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final List<int> years = List.generate(
      DateTime.now().year - 2019,
      (index) => 2020 + index,
    ).reversed.toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempMonth = _selectedMonth;
        int tempYear = _selectedYear;

        return AlertDialog(
          title: Text(
            'Select Month & Year',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month Dropdown
                  DropdownButtonFormField<int>(
                    value: tempMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: months.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key + 1,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tempMonth = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Year Dropdown
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tempYear = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedMonth = tempMonth;
                  _selectedYear = tempYear;
                });
                _fetchPaymentData();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'My Salary',
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          // Month/Year Selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectMonth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_getMonthName(_selectedMonth)} $_selectedYear',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.date_range,
                                  color: AppColors.primary, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _fetchPaymentData,
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load payment data',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchPaymentData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _paymentData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No payment data found',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No payment records found for ${_getMonthName(_selectedMonth)} $_selectedYear',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchPaymentData,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _paymentData.length,
                              itemBuilder: (context, index) {
                                final payment = _paymentData[index];
                                return _buildPaymentCard(payment);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentData payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Employee Info and Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.employeeName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      payment.employeeCode,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(payment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getStatusColor(payment.status)),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    color: _getStatusColor(payment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Net Payable Salary (Highlighted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Text(
                  'Net Payable Salary:',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  payment.formattedNetSalary,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Basic Information
          _buildInfoRow('Department',
              payment.department.isNotEmpty ? payment.department : 'N/A'),
          _buildInfoRow(
              'Section', payment.section.isNotEmpty ? payment.section : 'N/A'),
          _buildInfoRow('Mode of Payment', payment.modeOfPayment),
          _buildInfoRow(
              'Working Days', '${payment.workedDays}/${payment.workingDays}'),

          const Divider(height: 24),

          // Salary Breakdown
          _buildInfoRow('Actual Salary', payment.actualSalary),
          _buildClickableExpenseRow('Expenses', payment.expense, payment),
          _buildInfoRow('Gross Salary', payment.formattedGrossSalary),
          _buildInfoRow('Basic + DA', '₹${payment.basicDa}'),
          _buildInfoRow('HRA', '₹${payment.hra}'),
          _buildInfoRow('Performance', '₹${payment.performance2}'),
          _buildInfoRow('Payable Salary', payment.formattedPayableSalary),

          const Divider(height: 24),

          // Deductions
          _buildInfoRow('PF', '₹${payment.pf}'),
          _buildInfoRow('ESI', '₹${payment.esi}'),
          _buildInfoRow('TDS', '₹${payment.tds}'),
          _buildInfoRow('Professional Tax', '₹${payment.professionalTax}'),
          _buildInfoRow('Other Deductions', '₹${payment.otherDeduction}'),
          _buildInfoRow('Total Deductions', payment.formattedTotalDeduction),

          // Overtime (if applicable)
          if (double.tryParse(payment.totalOt) != null &&
              double.parse(payment.totalOt) > 0) ...[
            const Divider(height: 24),
            _buildInfoRow('OT Rate/Hour', '₹${payment.otPerHr}'),
            _buildInfoRow('OT Hours', payment.totalOt),
            _buildInfoRow('OT Amount',
                '₹${(double.tryParse(payment.otPerHr) ?? 0) * (double.tryParse(payment.totalOt) ?? 0)}'),
          ],

          // Bank Details (if available)
          if (payment.bankName.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow('Bank Name', payment.bankName),
            if (payment.bankAccountNumber != null &&
                payment.bankAccountNumber!.isNotEmpty)
              _buildInfoRow('Account Number', payment.bankAccountNumber!),
            _buildInfoRow('IFSC Code', payment.ifscCode),
          ],
          payment.status == "paid"
              ? CustomButton(
                  text: "Get PaySlip",
                  onPressed: () {
                    print("Click PaySlip");
                    downloadPDF(context, payment.payslip_pdf_url);
                  })
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableExpenseRow(
      String label, String value, PaymentData payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReimbursementScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> downloadPDF(BuildContext context, String pSlipUrl) async {
    try {
      // Ask for permission
      print("Pay Slip :$pSlipUrl");
      bool isGranted = await requestStoragePermission();
      if (!isGranted) {
        Fluttertoast.showToast(msg: "❌ Storage permission denied");
        return;
      }

      final fileName =
          "NEPL_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf";
      final downloadPath = "/storage/emulated/0/Download/$fileName";
      final file = File(downloadPath);

      // Delete existing file to prevent duplicates
      if (await file.exists()) {
        await file.delete();
      }

      final dio = Dio();

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text("Downloading..."),
            content: StatefulBuilder(
              builder: (context, setState) {
                double progress = 0.0;

                dio.download(
                  "$pSlipUrl",
                  downloadPath,
                  onReceiveProgress: (received, total) {
                    if (total != -1) {
                      setState(() {
                        progress = received / total;
                      });
                    }
                  },
                ).then((_) {
                  Navigator.of(context).pop(); // Close dialog
                  Fluttertoast.showToast(
                      msg: "✅ Downloaded to Downloads folder");
                }).catchError((e) {
                  Navigator.of(context).pop(); // Close dialog
                  Fluttertoast.showToast(msg: "❌ Download failed");
                  print("Download error: $e");
                });

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    SizedBox(height: 10),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ Error occurred");
      print("❌ Error: $e");
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }
}

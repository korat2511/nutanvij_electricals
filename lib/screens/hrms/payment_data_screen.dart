import 'dart:io';

// import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
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
              ? Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                                                CustomButton(
                                text: "Get PaySlip",
                                onPressed: () {
                                  downloadPDF(context, payment.payslip_pdf_url);
                                }),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _showFileInfo(context, payment.payslip_pdf_url);
                              },
                              child: const Text("Show File Info"),
                            ),
                  ],
                )
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
                    const Icon(
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
      print("Pay Slip URL: $pSlipUrl");
      bool isGranted = await requestStoragePermission();
      if (!isGranted) {
        SnackBarUtils.showError(context, "Storage permission denied");
        return;
      }

      final fileName = "NEPL_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf";
      final downloadPath = await getDownloadDirectoryPath();
      final file = File('$downloadPath/$fileName');
      
      print("Download path: ${file.path}");
      print("File will be saved as: $fileName");

      // Delete existing file to prevent duplicates
      if (await file.exists()) {
        await file.delete();
        print("Deleted existing file");
      }

      final dio = Dio();

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Downloading..."),
            content: StatefulBuilder(
              builder: (context, setState) {
                double progress = 0.0;

                dio.download(
                  pSlipUrl,
                  file.path,
                  onReceiveProgress: (received, total) {
                    if (total != -1) {
                      setState(() {
                        progress = received / total;
                      });
                    }
                  },
                ).then((_) async {
                  Navigator.of(context).pop();
                  
                  // Verify file was actually downloaded
                  if (await file.exists()) {
                    final fileSize = await file.length();
                    print("File downloaded successfully. Size: ${fileSize} bytes");
                    print("File path: ${file.path}");
                    
                    // Try to copy to public Downloads folder
                    String publicPath = await _copyToPublicDownloads(file, fileName);
                    
                    // Show success dialog with option to open file
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text("Download Successful"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("PDF downloaded successfully (${fileSize} bytes)"),
                                const SizedBox(height: 8),
                                if (publicPath != file.path) ...[
                                  const Text("✅ File saved to Downloads folder", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 4),
                                  const Text("You can find it in your device's Downloads folder"),
                                ] else ...[
                                  const Text("⚠️ File saved to app folder", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const SizedBox(height: 4),
                                  const Text("Use 'Open File' to view the PDF"),
                                ],
                                const SizedBox(height: 8),
                                Text("File: $fileName", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text("OK"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  if (context.mounted) {
                                    _openDownloadedFile(publicPath);
                                  }
                                },
                                child: const Text("Open File"),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // If context is not mounted, show a simple snackbar
                      SnackBarUtils.showSuccess(context, "PDF downloaded successfully ($fileSize bytes)");
                    }
                  } else {
                    print("File download failed - file doesn't exist");
                    SnackBarUtils.showError(context, "Download failed - file not found");
                  }
                }).catchError((e) {
                  Navigator.of(context).pop();
                  print("Download error: $e");
                  SnackBarUtils.showError(context, "Download failed: ${e.toString()}");
                });

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      SnackBarUtils.showError(context, "Error occurred: $e");
      print("❌ Error: $e");
    }
  }

  Future<String> getDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      // For Android, try to get the Downloads directory
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Navigate to Downloads folder
          final downloadsPath = '${directory.path}/../Download';
          final downloadsDir = Directory(downloadsPath);
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          print('Android Downloads path: $downloadsPath');
          return downloadsPath;
        }
      } catch (e) {
        print('Error accessing external storage: $e');
      }
      
      // Try alternative Downloads path
      try {
        final downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          print('Android alternative Downloads path: $downloadsPath');
          return downloadsPath;
        }
      } catch (e) {
        print('Error accessing alternative Downloads path: $e');
      }
      
      // Try using the public Downloads directory
      try {
        final downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        print('Android public Downloads path: $downloadsPath');
        return downloadsPath;
      } catch (e) {
        print('Error creating public Downloads directory: $e');
      }
      
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      print('Android fallback path: ${appDir.path}');
      return appDir.path;
    } else {
      // For iOS, use the documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      print('iOS documents path: ${documentsDir.path}');
      return documentsDir.path;
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    // iOS doesn't need storage permission for app documents directory
    return true;
  }

  Future<void> _openDownloadedFile(String filePath) async {
    if (!context.mounted) return;
    
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          SnackBarUtils.showError(context, "Could not open file: ${result.message}");
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, "Error opening file: $e");
      }
      print("Error opening file: $e");
    }
  }

  Future<void> _showFileInfo(BuildContext context, String pSlipUrl) async {
    try {
      final fileName = "NEPL_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf";
      final downloadPath = await getDownloadDirectoryPath();
      final file = File('$downloadPath/$fileName');
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("File Information"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("URL: $pSlipUrl"),
                const SizedBox(height: 8),
                Text("Download Path: $downloadPath"),
                const SizedBox(height: 8),
                Text("File Name: $fileName"),
                const SizedBox(height: 8),
                Text("Full Path: ${file.path}"),
                const SizedBox(height: 8),
                FutureBuilder<bool>(
                  future: file.exists(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text("File Exists: ${snapshot.data}");
                    }
                    return const Text("Checking file existence...");
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      SnackBarUtils.showError(context, "Error getting file info: $e");
    }
  }

  Future<String> _copyToPublicDownloads(File sourceFile, String fileName) async {
    if (Platform.isAndroid) {
      try {
        // Try to copy to public Downloads folder
        final publicDownloadsPath = '/storage/emulated/0/Download';
        final publicDownloadsDir = Directory(publicDownloadsPath);
        
        if (!await publicDownloadsDir.exists()) {
          await publicDownloadsDir.create(recursive: true);
        }
        
        final publicFile = File('$publicDownloadsPath/$fileName');
        
        // Delete existing file if it exists
        if (await publicFile.exists()) {
          await publicFile.delete();
        }
        
        // Copy the file
        await sourceFile.copy(publicFile.path);
        print("File copied to public Downloads: ${publicFile.path}");
        
        // Verify the copy was successful
        if (await publicFile.exists()) {
          final originalSize = await sourceFile.length();
          final copiedSize = await publicFile.length();
          print("Original size: $originalSize, Copied size: $copiedSize");
          
          if (originalSize == copiedSize) {
            return publicFile.path;
          }
        }
      } catch (e) {
        print("Error copying to public Downloads: $e");
      }
    }
    
    // Return original path if copy failed or not Android
    return sourceFile.path;
  }

  Future<void> _openDownloadsFolder() async {
    if (!context.mounted) return;
    
    try {
      // Try multiple approaches to open Downloads folder
      List<String> possiblePaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];
      
      bool opened = false;
      for (String path in possiblePaths) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            print("Trying to open Downloads folder: $path");
            final result = await OpenFile.open(path);
            if (result.type == ResultType.done) {
              opened = true;
              print("Successfully opened Downloads folder: $path");
              break;
            } else {
              print("Failed to open $path: ${result.message}");
            }
          }
        } catch (e) {
          print("Error trying path $path: $e");
        }
      }
      
      if (!opened) {
        // Try using the system file manager
        try {
          final result = await OpenFile.open('content://com.android.externalstorage.documents/document/primary:Download');
          if (result.type != ResultType.done) {
            if (context.mounted) {
              SnackBarUtils.showError(context, "Could not open Downloads folder. Please check your file manager manually.");
            }
          }
        } catch (e) {
          if (context.mounted) {
            SnackBarUtils.showError(context, "Could not open Downloads folder. Please check your file manager manually.");
          }
          print("Error opening Downloads folder: $e");
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, "Error opening Downloads folder: $e");
      }
      print("Error opening Downloads folder: $e");
    }
  }

  Future<void> _showFileLocationDialog(String filePath, String fileName) async {
    if (!context.mounted) return;
    
    try {
      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("File Location Details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("File Name: $fileName"),
                const SizedBox(height: 8),
                Text("Full Path: $filePath"),
                const SizedBox(height: 8),
                Text("File Exists: ${exists ? 'Yes' : 'No'}"),
                if (exists) ...[
                  const SizedBox(height: 8),
                  Text("File Size: ${size} bytes"),
                ],
                const SizedBox(height: 16),
                const Text(
                  "To find this file manually:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("1. Open your device's File Manager"),
                const Text("2. Navigate to 'Downloads' folder"),
                Text("3. Look for the file: $fileName"),
                const SizedBox(height: 8),
                const Text(
                  "Note: If you can't see the file, it might be in the app's private folder.",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Close"),
              ),
              if (exists)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      _openDownloadedFile(filePath);
                    }
                  },
                  child: const Text("Open File"),
                ),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, "Error showing file location: $e");
      }
    }
  }
}

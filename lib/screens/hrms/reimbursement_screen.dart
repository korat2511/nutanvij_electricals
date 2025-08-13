import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/reimbursement_data.dart';
import '../viewer/full_screen_image_viewer.dart';

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({Key? key}) : super(key: key);

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> {
  ReimbursementResponse? _reimbursementResponse;
  bool _isLoading = true;
  String? _error;
  
  // Month and year selection
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchReimbursementData();
  }

  Future<void> _fetchReimbursementData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      
      final reimbursementResponse = await ApiService().getMyReimbursement(
        context: context,
        apiToken: apiToken,
        month: _selectedMonth,
        year: _selectedYear,
      );

      setState(() {
        _reimbursementResponse = reimbursementResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Reimbursement API Error: $e'); // Debug logging
      SnackBarUtils.showError(context, 'Failed to load reimbursement data: ${e.toString()}');
    }
  }

  Future<void> _selectMonth() async {
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
                _fetchReimbursementData();
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'My Reimbursements',
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              const Icon(Icons.date_range, color: AppColors.primary, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _fetchReimbursementData,
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Summary Cards
          if (_reimbursementResponse != null && !_isLoading) ...[
            _buildSummaryCards(_reimbursementResponse!.summary),
            const SizedBox(height: 16),
          ],
          
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
                                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load reimbursement data',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    _error!,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchReimbursementData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                    : _reimbursementResponse?.reimbursements.isEmpty ?? true
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No reimbursements found',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No reimbursement records found for ${_getMonthName(_selectedMonth)} $_selectedYear',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReimbursementData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _reimbursementResponse!.reimbursements.length,
                              itemBuilder: (context, index) {
                                final reimbursement = _reimbursementResponse!.reimbursements[index];
                                return _buildReimbursementCard(reimbursement);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReimbursementSummary summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Total', '₹${summary.total}', Icons.account_balance_wallet, AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem('Approved', '₹${summary.approved}', Icons.check_circle, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem('Pending', '₹${summary.review}', Icons.schedule, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Rejected', '₹${summary.rejected}', Icons.cancel, Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem('Paid', '₹${summary.paided}', Icons.payment, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem('Unpaid', '₹${summary.unpaid}', Icons.money_off, Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReimbursementCard(ReimbursementData reimbursement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title, Amount and Status in one row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reimbursement.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reimbursement.formattedExpenseDate,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  reimbursement.formattedAmount,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getStatusColor(reimbursement.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getStatusColor(reimbursement.status), width: 0.5),
                ),
                child: Text(
                  reimbursement.status.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    color: _getStatusColor(reimbursement.status),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Compact info rows
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoRow('Payment', reimbursement.paymentStatus.toUpperCase()),
              ),
              if (reimbursement.approvedAmount != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('Approved', reimbursement.formattedApprovedAmount),
                ),
              ],
            ],
          ),
          
          if (reimbursement.approvedBy != null) ...[
            const SizedBox(height: 4),
            _buildCompactInfoRow('Approved By', reimbursement.approvedBy!.name),
            const SizedBox(height: 2),
            _buildCompactInfoRow('Approved At', reimbursement.formattedApprovedAt),
          ],
          
          if (reimbursement.description.isNotEmpty && reimbursement.description.toLowerCase() != 'na') ...[
            const SizedBox(height: 4),
            _buildCompactInfoRow('Description', reimbursement.description),
          ],
          
          if (reimbursement.adminReason?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            _buildCompactInfoRow('Admin Reason', reimbursement.adminReason!),
          ],
          
          // Images with View button
          if (reimbursement.employeeExpenseImages.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 85,
                  child: Text(
                    'Images : ',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final imageUrls = reimbursement.employeeExpenseImages
                        .map((img) => img.imagePath)
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          images: imageUrls,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            '$label: ',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
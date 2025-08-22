import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/site/providers/contractor_provider.dart';
import 'package:nutanvij_electricals/widgets/add_contractor_sheet.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../services/api_service.dart';
import '../../../providers/user_provider.dart';
import '../../../models/manpower.dart';
import '../../../models/site.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/contractor.dart';
import 'contractor_bottomsheet.dart';

class ManpowerManagementScreen extends StatefulWidget {
  final Site site;

  const ManpowerManagementScreen({
    Key? key,
    required this.site,
  }) : super(key: key);

  @override
  State<ManpowerManagementScreen> createState() => _ManpowerManagementScreenState();
}

class _ManpowerManagementScreenState extends State<ManpowerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  
  // Add/Edit variables
  DateTime _selectedDate = DateTime.now();
  Manpower? _currentManpower;
  bool _isLoadingManpower = false;
  bool _isEditing = false;
  
  // Range-wise variables
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Manpower> _manpowerList = [];
  bool _isLoadingRange = false;
  
  // Form controllers for adding/editing
  final TextEditingController _skillWorkerController = TextEditingController();
  final TextEditingController _unskillWorkerController = TextEditingController();
  final TextEditingController _skillPayController = TextEditingController();
  final TextEditingController _unskillPayController = TextEditingController();
  int _selectedShift = 1;
  
  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedContractorId = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentDateManpower();

    // Call Contractor List
    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final contractorProvider =
      Provider.of<ContractorProvider>(context, listen: false);

      contractorProvider.fetchContractors(
        context: context,
        siteId: widget.site.id.toString(),
        userProvider: userProvider,
      );
    });

  }

  @override
  void dispose() {
    _tabController.dispose();
    _skillWorkerController.dispose();
    _unskillWorkerController.dispose();
    _skillPayController.dispose();
    _unskillPayController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentDateManpower() async {
    setState(() {
      _isLoadingManpower = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final manpower = await ApiService().getManPower(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.site.id,
        date: dateString,
      );

      setState(() {
        _currentManpower = manpower;
        _isLoadingManpower = false;
      });

      // Pre-fill form if data exists
      if (manpower?.id != null) {
        _skillWorkerController.text = manpower!.skillWorker.toString();
        _unskillWorkerController.text = manpower.unskillWorker.toString();
        _skillPayController.text = manpower.skillPayPerHead.toString();
        _unskillPayController.text = manpower.unskillPayPerHead.toString();
        _selectedShift = manpower.shift;
      } else {
        _clearForm();
      }
    } catch (e) {
      setState(() {
        _error = null; // Clear any previous errors
        _isLoadingManpower = false;
      });
      _clearForm();
      
      // Log the error for debugging
      print('Manpower loading error: $e');
      
      // Don't show error for "no data found" - this is expected behavior
      if (!e.toString().contains('No data found') && 
          !e.toString().contains('null') &&
          !e.toString().contains('type')) {
        setState(() {
          _error = 'Failed to load manpower data. Please try again.';
        });
      }
    }
  }

  Future<void> _loadManpowerRange() async {
    setState(() {
      _isLoadingRange = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final startDateString = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateString = DateFormat('yyyy-MM-dd').format(_endDate);
      
      final report = await ApiService().getManPowerReport(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.site.id,
        startDate: startDateString,
        endDate: endDateString,
      );

      setState(() {
        _manpowerList = report.data;
        _isLoadingRange = false;
      });
    } catch (e) {
      setState(() {
        _error = null; // Clear any previous errors
        _isLoadingRange = false;
      });
      
      // Log the error for debugging
      print('Manpower range loading error: $e');
      
      // Don't show error for "no data found" - this is expected behavior
      if (!e.toString().contains('No data found') && 
          !e.toString().contains('null') &&
          !e.toString().contains('type')) {
        setState(() {
          _error = 'Failed to load manpower report. Please try again.';
        });
      }
    }
  }

  void _clearForm() {
    _skillWorkerController.clear();
    _unskillWorkerController.clear();
    _skillPayController.clear();
    _unskillPayController.clear();
    _selectedShift = 1;
    _isEditing = false;
  }

  Future<void> _saveManpower() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final manpower = await ApiService().storeManPower(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.site.id,
        date: dateString,
        skillWorker: int.parse(_skillWorkerController.text),
        unskillWorker: int.parse(_unskillWorkerController.text),
        shift: _selectedShift,
        skillPayPerHead: double.parse(_skillPayController.text),
        unskillPayPerHead: double.parse(_unskillPayController.text),
        contactorId: _selectedContractorId
      );

      setState(() {
        _currentManpower = manpower;
        _isLoading = false;
        _isEditing = false;
        _selectedContractorId = -1;// Reset editing state
      });

      SnackBarUtils.showSuccess(context, 'Manpower data saved successfully!');
      _loadCurrentDateManpower();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
      if (_tabController.index == 2) {
        _loadManpowerRange();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access contractor provider once here
    final contractorProvider = Provider.of<ContractorProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        onMenuPressed: () => NavigationUtils.pop(context),
        title: 'Manage Manpower - ${widget.site.name}',
      ),
      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Add/Edit'),
                Tab(text: 'Date Range'),
              ],
              onTap: (index) {
                if (index == 0) {
                  _loadCurrentDateManpower();
                }
              },
            ),
          ),
          
          // Error Display
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(color: Colors.red),
              ),
            ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAddEditTab(),
                _buildRangeReportTab(),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }



  Widget _buildRangeReportTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Selector
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(_startDate),
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(_endDate),
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          CustomButton(
            text: 'Load Report',
            onPressed: _loadManpowerRange,
            isLoading: _isLoadingRange,
          ),
          
          const SizedBox(height: 24),
          
          // Report Summary
          if (_manpowerList.isNotEmpty) ...[
            _buildReportSummary(),
            const SizedBox(height: 16),
          ],
          
          // Manpower List
          Expanded(
            child: _isLoadingRange
                ? const Center(child: CircularProgressIndicator())
                : _manpowerList.isEmpty
                    ? _buildNoDataCard()
                    : ListView.builder(
                        itemCount: _manpowerList.length,
                        itemBuilder: (context, index) {
                          return _buildManpowerCard(_manpowerList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEditTab() {
    // Access contractor provider once here
    final contractorProvider = Provider.of<ContractorProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                      _loadCurrentDateManpower();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: AppTypography.bodyMedium,
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Current Data Display (only show if data exists and not loading)
          if (_isLoadingManpower)
            const Center(child: CircularProgressIndicator())
          else if (_currentManpower != null && !_isEditing) ...[
            _buildManpowerCard(_currentManpower!),
            const SizedBox(height: 24),
          ],
          
          // Form (only show when editing or adding new data)
          if (_isEditing || _currentManpower == null)
            Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contractor Dropdown
                GestureDetector(
                  onTap: contractorProvider.isLoading
                      ? null
                      : () async {
                    final selectedId = await showModalBottomSheet<int>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => ContractorBottomSheet(
                        contractors: contractorProvider.contractors,
                        selectedId: _selectedContractorId,
                        onAddContractor: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            backgroundColor: Colors.white,
                            builder: (context) {
                              return AddContractorSheet(
                                onAdd: (name) async {
                                  await _addContractor(name);
                                },
                              );
                            },
                          );
                        },

                      ),
                    );

                    if (selectedId != null) {
                      setState(() {
                        _selectedContractorId = selectedId;
                      });
                    }
                  },

                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: TextEditingController(
                        text: contractorProvider.contractors
                            .firstWhere(
                              (c) => c.id == _selectedContractorId,
                          orElse: () => Contractor(
                            id: 0,
                            name: '',
                            mobile: '',
                            email: '',
                            siteId: 0,
                            deletedAt: null,
                            createdAt: '',
                            updatedAt: '',
                          ),
                        )
                            .name,
                      ),
                      label: 'Select Contractor',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.primary, // set color here
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skilled Worker Field
                CustomTextField(
                  controller: _skillWorkerController,
                  label: 'Skilled Workers (Enter number of skilled workers)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of skilled workers';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (int.parse(value) < 0) {
                      return 'Number cannot be negative';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _unskillWorkerController,
                  label: 'Unskilled Workers (Enter number of unskilled workers)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of unskilled workers';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (int.parse(value) < 0) {
                      return 'Number cannot be negative';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _skillPayController,
                  label: 'Skilled Worker Pay (₹/head) (Enter pay per skilled worker)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pay per skilled worker';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    if (double.parse(value) < 0) {
                      return 'Amount cannot be negative';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _unskillPayController,
                  label: 'Unskilled Worker Pay (₹/head) (Enter pay per unskilled worker)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pay per unskilled worker';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    if (double.parse(value) < 0) {
                      return 'Amount cannot be negative';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Shift Selection
                Text(
                  'Shift',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedShift,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Day')),
                      DropdownMenuItem(value: 2, child: Text('Night')),
                      DropdownMenuItem(value: 3, child: Text('Day & Night')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedShift = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    if (_isEditing) ...[
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                            _clearForm();
                          },
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: _currentManpower != null ? 'Update Manpower' : 'Save Manpower',
                        onPressed: _saveManpower,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManpowerCard(Manpower manpower) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(manpower.date)),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        manpower.shiftName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isEditing = true;
                        });
                        // Pre-fill form with current data
                        _skillWorkerController.text = manpower.skillWorker.toString();
                        _unskillWorkerController.text = manpower.unskillWorker.toString();
                        _skillPayController.text = manpower.skillPayPerHead.toString();
                        _unskillPayController.text = manpower.unskillPayPerHead.toString();
                        _selectedShift = manpower.shift;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Skilled Workers',
                    '${manpower.skillWorker}',
                    Icons.engineering,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Unskilled Workers',
                    '${manpower.unskillWorker}',
                    Icons.person,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Skilled Pay',
                    '₹${manpower.skillPayPerHead}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Unskilled Pay',
                    '₹${manpower.unskillPayPerHead}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount:',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹${manpower.totalAmount.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildNoDataCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No manpower data found',
            style: AppTypography.titleMedium.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add manpower data for this date/range',
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Text(
            'Use the "Add/Edit" tab to add new manpower data',
            style: AppTypography.bodySmall.copyWith(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary() {
    if (_manpowerList.isEmpty) return const SizedBox.shrink();
    
    final totalSkilled = _manpowerList.fold<int>(0, (sum, item) => sum + item.skillWorker);
    final totalUnskilled = _manpowerList.fold<int>(0, (sum, item) => sum + item.unskillWorker);
    final totalAmount = _manpowerList.fold<double>(0, (sum, item) => sum + item.totalAmount);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Summary',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Total Skilled', '$totalSkilled'),
                ),
                Expanded(
                  child: _buildSummaryItem('Total Unskilled', '$totalUnskilled'),
                ),
                Expanded(
                  child: _buildSummaryItem('Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _addContractor(String name) async {
  /*  setState(() => _isTagLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      final tag = await ApiService().addTag(apiToken: apiToken, name: name);
      await _fetchTags(); // Refresh the tag list after adding
      setState(() {
        _selectedTagId = tag.id;
        _isTagLoading = false;
      });
    } catch (e) {
      setState(() {
        _tagError = e.toString();
        _isTagLoading = false;
      });
    }
  */
  }

}


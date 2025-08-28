import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/models/manpower_entry_model.dart';
import 'package:nutanvij_electricals/screens/site/providers/contractor_provider.dart';
import 'package:nutanvij_electricals/widgets/add_contractor_sheet.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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
  State<ManpowerManagementScreen> createState() =>
      _ManpowerManagementScreenState();
}

class _ManpowerManagementScreenState extends State<ManpowerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;

  // Add/Edit variables
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingManpower = false;
  bool _isEditing = false;

  // Range-wise variables
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Manpower> _manpowerList = [];
  bool _isLoadingRange = false;
  bool _isFilterExpanded = false;

  // Form controllers for adding/editing
  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();

  int _selectedContractorIdDateRange = -1;

  List<Manpower> _currentManpowerList = [];
  bool _isAddingMore = false;
  bool _isAddingMoreButton = false;

  // Multiple manpower entries support
  List<Map<String, dynamic>> _manpowerEntries = [];
  List<TextEditingController> _skillWorkerControllers = [];
  List<TextEditingController> _unskillWorkerControllers = [];
  List<TextEditingController> _skillPayControllers = [];
  List<TextEditingController> _unskillPayControllers = [];
  List<int> _selectedShifts = [];
  List<int> _selectedContractorIds = [];

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
    // Dispose all controllers
    for (var controller in _skillWorkerControllers) {
      controller.dispose();
    }
    for (var controller in _unskillWorkerControllers) {
      controller.dispose();
    }
    for (var controller in _skillPayControllers) {
      controller.dispose();
    }
    for (var controller in _unskillPayControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrentDateManpower() async {
    setState(() {
      _isLoadingManpower = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dateString = DateFormat('dd-MM-yyyy').format(_selectedDate);

      final manpower = await ApiService().getManPower(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.site.id,
        date: dateString,
      );

      setState(() {
        _currentManpowerList = manpower;
        _isLoadingManpower = false;
      });

      // If data exists, automatically load it into editable form
      if (manpower.isNotEmpty) {
        setState(() {
          _isEditing = true;
          _isAddingMore = true;
          _isAddingMoreButton = true;
        });
        
        // Clear existing form and load all entries
        _clearForm();
        
        for (int i = 0; i < manpower.length; i++) {
          final entry = manpower[i];
          _addManpowerEntry();
          
          _skillWorkerControllers[i].text = entry.skillWorker.toString();
          _unskillWorkerControllers[i].text = entry.unskillWorker.toString();
          _skillPayControllers[i].text = entry.skillPayPerHead.toString();
          _unskillPayControllers[i].text = entry.unskillPayPerHead.toString();
          _selectedShifts[i] = entry.shift;
          if (entry.contractor != null) {
            _selectedContractorIds[i] = entry.contractor!.id;
          }
        }
      } else {
        // No data exists, show add form
        setState(() {
          _isEditing = false;
          _isAddingMore = false;
          _isAddingMoreButton = false;
        });
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

  Future<void> _loadCurrentDateManpowerContractor(int contractor_id) async {
    setState(() {
      _isLoadingManpower = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dateString = DateFormat('dd-MM-yyyy').format(_selectedDate);

      final manpower = await ApiService().getManPowerWithContractor(
          context: context,
          apiToken: userProvider.user?.data.apiToken ?? '',
          siteId: widget.site.id,
          date: dateString,
          contractor_id: contractor_id);

      setState(() {
        _currentManpowerList = manpower;
        _isLoadingManpower = false;
      });

      //TODO N
/*      // Pre-fill form if data exists
      if (manpower?.id != null) {
        _skillWorkerController.text = manpower!.skillWorker.toString();
        _unskillWorkerController.text = manpower.unskillWorker.toString();
        _skillPayController.text = manpower.skillPayPerHead.toString();
        _unskillPayController.text = manpower.unskillPayPerHead.toString();
        _selectedShift = manpower.shift;
      } else {
        _clearForm();
      }*/
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
      final startDateString = DateFormat('dd-MM-yyyy').format(_startDate);
      final endDateString = DateFormat('dd-MM-yyyy').format(_endDate);

      final report = await ApiService().getManPowerReport(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.site.id,
        startDate: startDateString,
        endDate: endDateString,
        contractorId: _selectedContractorIdDateRange != -1 ? _selectedContractorIdDateRange : null,
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
    // Clear all controllers
    for (var controller in _skillWorkerControllers) {
      controller.clear();
    }
    for (var controller in _unskillWorkerControllers) {
      controller.clear();
    }
    for (var controller in _skillPayControllers) {
      controller.clear();
    }
    for (var controller in _unskillPayControllers) {
      controller.clear();
    }
    
    // Reset lists
    _manpowerEntries.clear();
    _skillWorkerControllers.clear();
    _unskillWorkerControllers.clear();
    _skillPayControllers.clear();
    _unskillPayControllers.clear();
    _selectedShifts.clear();
    _selectedContractorIds.clear();
    
    _isEditing = false;
  }

  void _addManpowerEntry() {
    setState(() {
      _skillWorkerControllers.add(TextEditingController());
      _unskillWorkerControllers.add(TextEditingController());
      _skillPayControllers.add(TextEditingController());
      _unskillPayControllers.add(TextEditingController());
      _selectedShifts.add(1);
      _selectedContractorIds.add(-1);
      _manpowerEntries.add({});
    });
  }

  void _removeManpowerEntry(int index) {
    setState(() {
      _skillWorkerControllers[index].dispose();
      _unskillWorkerControllers[index].dispose();
      _skillPayControllers[index].dispose();
      _unskillPayControllers[index].dispose();
      
      _skillWorkerControllers.removeAt(index);
      _unskillWorkerControllers.removeAt(index);
      _skillPayControllers.removeAt(index);
      _unskillPayControllers.removeAt(index);
      _selectedShifts.removeAt(index);
      _selectedContractorIds.removeAt(index);
      _manpowerEntries.removeAt(index);
    });
  }


  Future<void> _saveManpower() async {
    if (!_formKey2.currentState!.validate()) return;

    // Validate that at least one entry has data
    bool hasValidEntry = false;
    for (int i = 0; i < _skillWorkerControllers.length; i++) {
      if (_skillWorkerControllers[i].text.isNotEmpty && 
          _unskillWorkerControllers[i].text.isNotEmpty &&
          _skillPayControllers[i].text.isNotEmpty &&
          _unskillPayControllers[i].text.isNotEmpty &&
          _selectedContractorIds[i] != -1) {
        hasValidEntry = true;
        break;
      }
    }

    if (!hasValidEntry) {
      SnackBarUtils.showError(context, 'Please add at least one manpower entry');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dateString = DateFormat('dd-MM-yyyy').format(_selectedDate);

      // Prepare the data array with all valid entries
      final List<ManpowerEntryModel> manpowerData = [];
      
      for (int i = 0; i < _skillWorkerControllers.length; i++) {
        if (_skillWorkerControllers[i].text.isNotEmpty && 
            _unskillWorkerControllers[i].text.isNotEmpty &&
            _skillPayControllers[i].text.isNotEmpty &&
            _unskillPayControllers[i].text.isNotEmpty &&
            _selectedContractorIds[i] != -1) {
          
          manpowerData.add(ManpowerEntryModel(
            shift: _selectedShifts[i],
            skillWorker: int.parse(_skillWorkerControllers[i].text),
            unskillWorker: int.parse(_unskillWorkerControllers[i].text),
            contractorId: _selectedContractorIds[i],
            skillPayPerHead: int.parse(_skillPayControllers[i].text),
            unskillPayPerHead: int.parse(_unskillPayControllers[i].text),
          ));
        }
      }

      final List<Map<String, dynamic>> data = manpowerData.map((entry) => entry.toJson()).toList();



      await ApiService().storeManPower(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.site.id,
        date: dateString,
        data: data,
      );

      setState(() {
        _isLoading = false;
        _isAddingMore = false;
        _isAddingMoreButton = false;
        _isEditing = false;
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
      builder: (context, child) {
        return Container(
          color: Colors.white,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                surface: Colors.white,
                onSurface: Colors.black,
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
              scaffoldBackgroundColor: Colors.white,
              cardColor: Colors.white,
            ),
            child: Material(
              color: Colors.white,
              child: child!,
            ),
          ),
        );
      },
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
        title: 'Manage Manpower',
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
    final contractorProvider = Provider.of<ContractorProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Filter Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with summary and expand button
                InkWell(
                  onTap: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Filters',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_selectedContractorIdDateRange != -1)
                                Text(
                                  contractorProvider.contractors
                                      .firstWhere(
                                        (c) => c.id == _selectedContractorIdDateRange,
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
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Expandable Filter Content
                if (_isFilterExpanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
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
                                        style: AppTypography.bodySmall
                                            .copyWith(color: AppColors.primary),
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
                            const SizedBox(width: 12),
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
                                        style: AppTypography.bodySmall
                                            .copyWith(color: AppColors.primary),
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
                        
                        // Contractor Selection
                        GestureDetector(
                          onTap: contractorProvider.isLoading
                              ? null
                              : () async {
                                  final selectedId = await showModalBottomSheet<int>(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (context) => ContractorBottomSheet(
                                      contractors: contractorProvider.contractors,
                                      selectedId: _selectedContractorIdDateRange,
                                      onAddContractor: () async {
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          backgroundColor: Colors.white,
                                          builder: (context) {
                                            return AddContractorSheet(
                                              onAdd: (name, email, phone) async {
                                                await _addContractor(name, email, phone);
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );

                                  if (selectedId != null) {
                                    setState(() {
                                      _selectedContractorIdDateRange = selectedId;
                                    });

                                    // 🔥 Call API again after selecting contractor
                                    _loadCurrentDateManpowerContractor(
                                        _selectedContractorIdDateRange);
                                  }
                                },
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: TextEditingController(
                                text: contractorProvider.contractors
                                    .firstWhere(
                                      (c) => c.id == _selectedContractorIdDateRange,
                                      orElse: () => Contractor(
                                        id: 0,
                                        name: 'All Contractors',
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
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Load Report Button
                        CustomButton(
                          text: 'Load Report',
                          onPressed: _loadManpowerRange,
                          isLoading: _isLoadingRange,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Report Summary
          if (_manpowerList.isNotEmpty) ...[
            _buildReportSummary(),

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
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Container(
                          color: Colors.white,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                surface: Colors.white,
                                onSurface: Colors.black,
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                              ),
                              dialogBackgroundColor: Colors.white,
                              scaffoldBackgroundColor: Colors.white,
                              cardColor: Colors.white,
                            ),
                            child: Material(
                              color: Colors.white,
                              child: child!,
                            ),
                          ),
                        );
                      },
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
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: AppTypography.bodyMedium,
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.primary),
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
          else if (_currentManpowerList.isNotEmpty &&
              !_isEditing &&
              !_isAddingMore) ...[
            // Show existing manpower entries for the selected date
            Text(
              'Manpower for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              itemCount: _currentManpowerList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildManpowerCard(_currentManpowerList[index]);
              },
            ),

            const SizedBox(height: 24),

            // Add More Button
            CustomButton(
              text: 'Add More Entries',
              onPressed: () {
                setState(() {
                  _isAddingMore = true;
                  _isAddingMoreButton = true;
                });
              },
              backgroundColor: AppColors.primary,
            ),
          ] else if (_currentManpowerList.isEmpty &&
              !_isEditing &&
              !_isAddingMore) ...[
            // No data found for the selected date
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No manpower data found for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: AppTypography.titleMedium
                        .copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add the first manpower entry for this date',
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Add Manpower',
                    onPressed: () {
                      setState(() {
                        _isAddingMore = true;
                        _isAddingMoreButton = true;
                        _clearForm();
                      });
                    },
                    backgroundColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],

          // Form (only show when adding new data)
          if (_isAddingMore && _isAddingMoreButton)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Manpower Entries' : 'Add Manpower',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: _addManpowerEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Add Entry',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                Form(
                  key: _formKey2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Initialize first entry if empty
                        if (_skillWorkerControllers.isEmpty)
                          Builder(
                            builder: (context) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _addManpowerEntry();
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                        
                        // Multiple manpower entries in a compact list
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _skillWorkerControllers.length,
                          itemBuilder: (context, index) {
                            return _buildManpowerEntryCard(index, contractorProvider);
                          },
                        ),
                        
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel',
                                onPressed: () {
                                  setState(() {
                                    _isAddingMore = false;
                                    _isAddingMoreButton = false;
                                  });
                                  _clearForm();
                                },
                                backgroundColor: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomButton(
                                text: _isEditing ? 'Update Manpower' : 'Save All Entries',
                                onPressed: _saveManpower,
                                isLoading: _isLoading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildManpowerCard(Manpower manpower) {
    return Card(
      color: Colors.white,
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
                  DateFormat('dd MMM yyyy')
                      .format(DateTime.parse(manpower.date)),
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Contractor Info
            if (manpower.contractor != null) ...[
              Row(
                children: [
                  const Icon(Icons.business, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      manpower.contractor?.name ?? "N/A",
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 🔹 Skilled & Unskilled Workers

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
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
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

    final totalSkilled =
        _manpowerList.fold<int>(0, (sum, item) => sum + item.skillWorker);
    final totalUnskilled =
        _manpowerList.fold<int>(0, (sum, item) => sum + item.unskillWorker);
    final totalAmount =
        _manpowerList.fold<double>(0, (sum, item) => sum + item.totalAmount);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Summary',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Total Skilled', '$totalSkilled'),
                ),
                Expanded(
                  child:
                      _buildSummaryItem('Total Unskilled', '$totalUnskilled'),
                ),
                Expanded(
                  child: _buildSummaryItem(
                      'Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
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

  Widget _buildManpowerEntryCard(int index, ContractorProvider contractorProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [



            // Contractor Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: contractorProvider.isLoading
                        ? null
                        : () async {
                            final usedContractorIds = _currentManpowerList
                                .map((m) => m.contractor?.id)
                                .whereType<int>()
                                .toSet();
                            for (int i = 0; i < _selectedContractorIds.length; i++) {
                              if (i != index && _selectedContractorIds[i] != -1) {
                                usedContractorIds.add(_selectedContractorIds[i]);
                              }
                            }

                            final availableContractors = contractorProvider.contractorsFiltered
                                .where((c) => !usedContractorIds.contains(c.id))
                                .toList();

                            final selectedId = await showModalBottomSheet<int>(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) => ContractorBottomSheet(
                                contractors: availableContractors,
                                selectedId: _selectedContractorIds[index],
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
                                        onAdd: (name, email, phone) async {
                                          await _addContractor(name, email, phone);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            );

                            if (selectedId != null) {
                              setState(() {
                                _selectedContractorIds[index] = selectedId;
                              });
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.business, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              contractorProvider.contractorsFiltered
                                  .firstWhere(
                                    (c) => c.id == _selectedContractorIds[index],
                                    orElse: () => Contractor(
                                      id: 0,
                                      name: 'Select Contractor',
                                      mobile: '',
                                      email: '',
                                      siteId: 0,
                                      deletedAt: null,
                                      createdAt: '',
                                      updatedAt: '',
                                    ),
                                  )
                                  .name,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeManpowerEntry(index),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Form fields - Single row for workers
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextFormField(
                      controller: _skillWorkerControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Skilled',
                        labelStyle: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        if (int.parse(value) < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextFormField(
                      controller: _unskillWorkerControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Unskilled',
                        labelStyle: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        if (int.parse(value) < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Form fields - Single row for pay
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextFormField(
                      controller: _skillPayControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Skilled Pay (₹)',
                        labelStyle: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        if (int.parse(value) < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextFormField(
                      controller: _unskillPayControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Unskilled Pay (₹)',
                        labelStyle: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        if (int.parse(value) < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Shift Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Shift:',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedShifts[index],
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Day', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 2, child: Text('Night', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 3, child: Text('Day & Night', style: TextStyle(fontSize: 14))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedShifts[index] = value!;
                        });
                      },
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

  Future<void> _addContractor(String name, String email, String phone) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final contractorProvider =
        Provider.of<ContractorProvider>(context, listen: false);

    await contractorProvider.addNewContractor(
      context: context,
      apiToken: userProvider.user?.data.apiToken ?? '',
      siteId: widget.site.id.toString(),
      name: name,
      mobile: phone,
      email: email,
    );
  }
}

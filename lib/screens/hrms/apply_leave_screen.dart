import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({Key? key}) : super(key: key);

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _leaveType;
  String? _duration;
  String? _halfDaySession;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _reason;
  TimeOfDay? _earlyOffStartTime;
  TimeOfDay? _earlyOffEndTime;

  final List<String> _leaveTypes = ['Sick', 'Casual', 'Paid'];
  final List<String> _durations = [
    'Full Day',
    'Half Day',
    'Late Coming',
    'Early Off'
  ];
  final List<String> _halfDaySessions = ['First Half', 'Second Half'];

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final firstDate = isStart ? DateTime.now() : (_startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
          if (_duration == 'Late Coming' || _duration == 'Early Off' || _duration == 'Half Day') {
            _endDate = _startDate;
          }
        } else {
          if (picked.isBefore(_startDate!)) {
            SnackBarUtils.showError(context, 'End date cannot be before start date');
            return;
          }
          if (_duration == 'Late Coming' || _duration == 'Early Off' || _duration == 'Half Day') {
            SnackBarUtils.showError(context, 'Start and end date must be same for ${_duration}');
            return;
          }
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    if (_duration == 'Late Coming' && isStart) {
      setState(() {
        _earlyOffStartTime = const TimeOfDay(hour: 9, minute: 0);
      });
      return;
    }
    if (_duration == 'Early Off' && !isStart) {
      setState(() {
        _earlyOffEndTime = const TimeOfDay(hour: 18, minute: 0);
      });
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _earlyOffStartTime = picked;
        } else {
          _earlyOffEndTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_leaveType == null ||
        _duration == null ||
        _startDate == null ||
        _endDate == null) {
      SnackBarUtils.showError(context, 'Please fill all required fields.');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    
    if (startDate.isBefore(today)) {
      SnackBarUtils.showError(context, 'Cannot apply leave for past dates');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      SnackBarUtils.showError(context, 'End date cannot be before start date');
      return;
    }

    if ((_duration == 'Late Coming' || _duration == 'Early Off' || _duration == 'Half Day') && 
        !_startDate!.isAtSameMomentAs(_endDate!)) {
      SnackBarUtils.showError(context, 'Start and end date must be same for ${_duration}');
      return;
    }

    if (_duration == 'Half Day' && _halfDaySession == null) {
      SnackBarUtils.showError(context, 'Please select half day session');
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState!.save();
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) throw Exception('User not found');
      await ApiService().applyForLeave(
        context: context,
        apiToken: user.data.apiToken,
        leaveType: _leaveType!,
        duration: _duration!,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        reason: _reason ?? '',
        halfDaySession: _halfDaySession,
        earlyOffStartTime:
            _duration == 'Early Off' && _earlyOffStartTime != null
                ? _earlyOffStartTime!.format(context)
                : null,
        earlyOffEndTime: _duration == 'Early Off' && _earlyOffEndTime != null
            ? _earlyOffEndTime!.format(context)
            : null,
      );
      SnackBarUtils.showSuccess(context, 'Leave applied successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Apply Leave',
        onMenuPressed: () => Navigator.of(context).pop(),
        showProfilePicture: false,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.responsiveValue(
              context: context, mobile: 16, tablet: 32),
          vertical: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leave Type',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _leaveType,
                items: _leaveTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _leaveType = val),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Duration',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _duration,
                items: _durations
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _duration = val;
                    if (val == 'Late Coming') {
                      _earlyOffStartTime = const TimeOfDay(hour: 9, minute: 0);
                      _earlyOffEndTime = null;
                    } else if (val == 'Early Off') {
                      _earlyOffEndTime = const TimeOfDay(hour: 18, minute: 0);
                      _earlyOffStartTime = null;
                    } else if (val != 'Half Day') {
                      _halfDaySession = null;
                    }
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (val) => val == null ? 'Required' : null,
              ),
              if (_duration == 'Half Day') ...[
                const SizedBox(height: 16),
                Text('Half Day Session',
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _halfDaySession,
                  items: _halfDaySessions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _halfDaySession = val),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (val) => val == null ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickDate(context, true),
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Select',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              controller: TextEditingController(
                                text: _startDate != null
                                    ? DateFormat('dd MMM yyyy')
                                        .format(_startDate!)
                                    : '',
                              ),
                              validator: (val) =>
                                  _startDate == null ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Date',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickDate(context, false),
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Select',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              controller: TextEditingController(
                                text: _endDate != null
                                    ? DateFormat('dd MMM yyyy')
                                        .format(_endDate!)
                                    : '',
                              ),
                              validator: (val) =>
                                  _endDate == null ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Reason',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSaved: (val) => _reason = val,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
              if (_duration == 'Early Off') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Early Off Start Time',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickTime(context, true),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  hintText: 'Select',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  suffixIcon: const Icon(Icons.access_time),
                                ),
                                controller: TextEditingController(
                                  text: _earlyOffStartTime != null
                                      ? _earlyOffStartTime!.format(context)
                                      : '',
                                ),
                                validator: (val) => _earlyOffStartTime == null
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Early Off End Time',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: null,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Select',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  suffixIcon: Icon(Icons.lock, color: Colors.grey),
                                ),
                                controller: TextEditingController(
                                  text: _earlyOffEndTime != null
                                      ? _earlyOffEndTime!.format(context)
                                      : '',
                                ),
                                validator: (val) => _earlyOffEndTime == null
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (_duration == 'Late Coming') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Late Coming Start Time',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: null,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Select',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  suffixIcon: Icon(Icons.lock, color: Colors.grey),
                                ),
                                controller: TextEditingController(
                                  text: _earlyOffStartTime != null
                                      ? _earlyOffStartTime!.format(context)
                                      : '',
                                ),
                                validator: (val) => _earlyOffStartTime == null
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Late Coming End Time',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickTime(context, false),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Select',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  suffixIcon: Icon(Icons.access_time),
                                ),
                                controller: TextEditingController(
                                  text: _earlyOffEndTime != null
                                      ? _earlyOffEndTime!.format(context)
                                      : '',
                                ),
                                validator: (val) => _earlyOffEndTime == null
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

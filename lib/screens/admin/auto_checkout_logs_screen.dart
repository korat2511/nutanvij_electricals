import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/auto_checkout_logger.dart';
import '../../widgets/custom_app_bar.dart';

class AutoCheckoutLogsScreen extends StatefulWidget {
  const AutoCheckoutLogsScreen({super.key});

  @override
  State<AutoCheckoutLogsScreen> createState() => _AutoCheckoutLogsScreenState();
}

class _AutoCheckoutLogsScreenState extends State<AutoCheckoutLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'errors', 'user', 'site'
  String _userId = '';
  int _siteId = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> logs = [];
      
      switch (_selectedFilter) {
        case 'all':
          logs = await AutoCheckoutLogger.instance.getAllLogs(limit: 100);
          break;
        case 'errors':
          logs = await AutoCheckoutLogger.instance.getErrorLogs(limit: 100);
          break;
        case 'user':
          if (_userId.isNotEmpty) {
            logs = await AutoCheckoutLogger.instance.getUserLogs(userId: _userId, limit: 100);
          }
          break;
        case 'site':
          if (_siteId > 0) {
            logs = await AutoCheckoutLogger.instance.getSiteLogs(siteId: _siteId, limit: 100);
          }
          break;
        default:
          // Default to all logs
          logs = await AutoCheckoutLogger.instance.getAllLogs(limit: 100);
          break;
      }
      
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd MMM yyyy, HH:mm:ss').format(timestamp.toDate());
      } else if (timestamp is String) {
        return DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.parse(timestamp));
      }
    } catch (e) {
      return 'Invalid date';
    }
    
    return 'Unknown';
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'auto_checkout_success':
        return Colors.green;
      case 'auto_checkout_error':
        return Colors.red;
      case 'auto_checkout_trigger':
        return Colors.orange;
      case 'location_check':
        return Colors.blue;
      case 'monitoring_start':
        return Colors.purple;
      case 'monitoring_stop':
        return Colors.grey;
      case 'app_start_check':
        return Colors.teal;
      default:
        return Colors.black;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'auto_checkout_success':
        return Icons.check_circle;
      case 'auto_checkout_error':
        return Icons.error;
      case 'auto_checkout_trigger':
        return Icons.location_off;
      case 'location_check':
        return Icons.location_on;
      case 'monitoring_start':
        return Icons.play_arrow;
      case 'monitoring_stop':
        return Icons.stop;
      case 'app_start_check':
        return Icons.power_settings_new;
      default:
        return Icons.info;
    }
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final action = log['action'] ?? 'unknown';
    final timestamp = log['timestamp'];
    final note = log['note'] ?? '';
    final isSuccess = log['isSuccess'] ?? false;
    final distance = log['distance'];
    final maxRange = log['maxRange'];
    final siteName = log['siteName'] ?? 'Unknown Site';
    final userName = log['userName'] ?? 'Unknown User';
    final errorMessage = log['errorMessage'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getActionIcon(action),
                  color: _getActionColor(action),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.replaceAll('_', ' ').toUpperCase(),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getActionColor(action),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSuccess ? 'SUCCESS' : 'ERROR',
                    style: AppTypography.bodySmall.copyWith(
                      color: isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(timestamp),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  userName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),


              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  siteName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (distance != null && maxRange != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Distance: ${distance.round()}m / ${maxRange}m',
                    style: AppTypography.bodySmall.copyWith(
                      color: distance > maxRange ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              note,
              style: AppTypography.bodySmall,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $errorMessage',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Auto Checkout Logs',
        onMenuPressed: () => NavigationUtils.pop(context),
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Logs')),
                      DropdownMenuItem(value: 'errors', child: Text('Errors Only')),
                      DropdownMenuItem(value: 'user', child: Text('By User')),
                      DropdownMenuItem(value: 'site', child: Text('By Site')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedFilter = value!);
                      _loadLogs();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loadLogs,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text('No logs found'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return _buildLogCard(_logs[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
} 
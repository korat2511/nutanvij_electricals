import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../services/auto_checkout_logger.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/snackbar_utils.dart';

class AutoCheckoutLogsScreen extends StatefulWidget {
  const AutoCheckoutLogsScreen({super.key});

  @override
  State<AutoCheckoutLogsScreen> createState() => _AutoCheckoutLogsScreenState();
}

class _AutoCheckoutLogsScreenState extends State<AutoCheckoutLogsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeUsers = [];
  Map<String, dynamic>? _selectedUserStats;
  List<Map<String, dynamic>> _userLogs = [];
  String? _selectedUserId;
  String? _selectedUserName;

  @override
  void initState() {
    super.initState();
    _loadActiveUsers();
  }

  Future<void> _loadActiveUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AutoCheckoutLogger.instance.getActiveUsers(days: 30);
      setState(() {
        _activeUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarUtils.showError(context, 'Failed to load active users: $e');
    }
  }

  Future<void> _loadUserStats(String userId) async {
    setState(() => _isLoading = true);
    try {
      final stats = await AutoCheckoutLogger.instance.getUserStatistics(userId: userId);
      setState(() {
        _selectedUserStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarUtils.showError(context, 'Failed to load user statistics: $e');
    }
  }

  Future<void> _loadUserLogs(String userId) async {
    setState(() => _isLoading = true);
    try {
      final logs = await AutoCheckoutLogger.instance.getUserLogs(userId: userId, limit: 100);
      setState(() {
        _userLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarUtils.showError(context, 'Failed to load user logs: $e');
    }
  }

  Future<void> _loadUserErrorLogs(String userId) async {
    setState(() => _isLoading = true);
    try {
      final logs = await AutoCheckoutLogger.instance.getUserErrorLogs(userId: userId, limit: 50);
      setState(() {
        _userLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarUtils.showError(context, 'Failed to load user error logs: $e');
    }
  }

  void _selectUser(String userId, String userName) {
    setState(() {
      _selectedUserId = userId;
      _selectedUserName = userName;
      _userLogs = [];
      _selectedUserStats = null;
    });
    _loadUserStats(userId);
    _loadUserLogs(userId);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    }
    return 'Unknown';
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'auto_checkout_trigger':
        return Colors.red;
      case 'auto_checkout_success':
        return Colors.green;
      case 'auto_checkout_error':
        return Colors.orange;
      case 'location_check':
        return Colors.blue;
      case 'monitoring_start':
        return Colors.purple;
      case 'monitoring_stop':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Auto Checkout Logs',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => NavigationUtils.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadActiveUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left panel - Active Users
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Active Users (${_activeUsers.length})',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _activeUsers.length,
                            itemBuilder: (context, index) {
                              final user = _activeUsers[index];
                              final isSelected = user['userId'] == _selectedUserId;
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _selectUser(user['userId'], user['userName']),
                                  title: Text(
                                    user['userName'] ?? 'Unknown User',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID: ${user['userId']}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Logs: ${user['logCount']}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: user['hasErrors'] == true
                                      ? Icon(Icons.error, color: Colors.red, size: 16)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right panel - User Details and Logs
                Expanded(
                  flex: 2,
                  child: _selectedUserId == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Select a user to view logs',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // User Stats Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedUserName ?? 'Unknown User',
                                          style: AppTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'ID: $_selectedUserId',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedUserStats != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${_selectedUserStats!['successRate'].toStringAsFixed(1)}% Success',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Action Buttons
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _loadUserLogs(_selectedUserId!),
                                      icon: const Icon(Icons.list),
                                      label: const Text('All Logs'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _loadUserErrorLogs(_selectedUserId!),
                                      icon: const Icon(Icons.error),
                                      label: const Text('Errors Only'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Stats Cards
                            if (_selectedUserStats != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Logs',
                                        _selectedUserStats!['totalLogs'].toString(),
                                        Icons.analytics,
                                        AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Success',
                                        _selectedUserStats!['successLogs'].toString(),
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Errors',
                                        _selectedUserStats!['errorLogs'].toString(),
                                        Icons.error,
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Logs List
                            Expanded(
                              child: _userLogs.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No logs found',
                                            style: AppTypography.bodyLarge.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _userLogs.length,
                                      itemBuilder: (context, index) {
                                        final log = _userLogs[index];
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _getActionColor(log['action']).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getActionIcon(log['action']),
                                                color: _getActionColor(log['action']),
                                                size: 16,
                                              ),
                                            ),
                                            title: Text(
                                              log['action'] ?? 'Unknown Action',
                                              style: AppTypography.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  log['note'] ?? 'No description',
                                                  style: AppTypography.bodySmall,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatTimestamp(log['timestamp']),
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: log['isSuccess'] == true
                                                ? Icon(Icons.check_circle, color: Colors.green, size: 16)
                                                : Icon(Icons.error, color: Colors.red, size: 16),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'auto_checkout_trigger':
        return Icons.location_off;
      case 'auto_checkout_success':
        return Icons.check_circle;
      case 'auto_checkout_error':
        return Icons.error;
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
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../services/auto_checkout_service.dart';
import '../../services/auto_checkout_logger.dart';
import '../../widgets/custom_app_bar.dart';

class AutoCheckoutLogsScreen extends StatefulWidget {
  const AutoCheckoutLogsScreen({Key? key}) : super(key: key);

  @override
  State<AutoCheckoutLogsScreen> createState() => _AutoCheckoutLogsScreenState();
}

class _AutoCheckoutLogsScreenState extends State<AutoCheckoutLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await AutoCheckoutLogger.instance.getAllLogs(limit: 100);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testAutoCheckout() async {
    try {
      await AutoCheckoutService.instance.testAutoCheckoutDirectly(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto checkout test completed. Check logs for details.'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload logs to see the test result
      _loadLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'Auto Checkout Logs',
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          // Test Button
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _testAutoCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Test Auto Checkout'),
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
                              'Failed to load logs',
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
                              onPressed: _loadLogs,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No logs found',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Auto checkout logs will appear here',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLogs,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return _buildLogCard(log);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] as Timestamp?;
    final action = log['action'] as String? ?? 'Unknown';
    final isSuccess = log['isSuccess'] as bool? ?? false;
    final note = log['note'] as String? ?? '';
    final errorMessage = log['errorMessage'] as String?;
    final userName = log['userName'] as String? ?? 'Unknown User';
    final siteName = log['siteName'] as String? ?? 'Unknown Site';
    final distance = log['distance'] as double?;
    final maxRange = log['maxRange'] as int?;

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
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      userName,
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
                  color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  isSuccess ? 'SUCCESS' : 'ERROR',
                  style: AppTypography.bodySmall.copyWith(
                    color: isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Details
          if (timestamp != null) ...[
            _buildInfoRow('Time', timestamp.toDate().toString()),
          ],
          if (siteName.isNotEmpty) ...[
            _buildInfoRow('Site', siteName),
          ],
          if (distance != null && maxRange != null) ...[
            _buildInfoRow('Distance', '${distance.round()}m / ${maxRange}m'),
          ],
          if (note.isNotEmpty) ...[
            _buildInfoRow('Note', note),
          ],
          if (errorMessage != null && errorMessage.isNotEmpty) ...[
            _buildInfoRow('Error', errorMessage),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
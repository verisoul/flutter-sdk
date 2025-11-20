import 'package:flutter/material.dart';
import 'test_harness.dart';

class ResultsView extends StatelessWidget {
  final TestResults results;
  final String testType;
  final VoidCallback onDismiss;

  const ResultsView({
    Key? key,
    required this.results,
    required this.testType,
    required this.onDismiss,
  }) : super(key: key);

  double get successRate => results.totalRounds > 0
      ? (results.successCount / results.totalRounds) * 100
      : 0;

  double get minLatency => results.sessionLatencies.isNotEmpty
      ? results.sessionLatencies.reduce((a, b) => a < b ? a : b)
      : 0;

  double get maxLatency => results.sessionLatencies.isNotEmpty
      ? results.sessionLatencies.reduce((a, b) => a > b ? a : b)
      : 0;

  Color _getSuccessRateColor(double rate) {
    if (rate >= 95) return const Color(0xFF28a745);
    if (rate >= 80) return const Color(0xFFFF9500);
    return const Color(0xFFdc3545);
  }

  Color _getLatencyColor(double latency) {
    if (latency < 100) return const Color(0xFF28a745);
    if (latency < 500) return const Color(0xFFFF9500);
    return const Color(0xFFdc3545);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Test Results',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: const SizedBox(width: 60),
        actions: [
          TextButton(
            onPressed: onDismiss,
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Icon and Title
            _buildTopSection(),
            const Divider(height: 40, color: Color(0xFFDDDDDD)),
            // Summary Stats
            _buildStatsSection(),
            const SizedBox(height: 10),
            // Summary Message
            _buildSummaryBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        Text(
          results.failureCount == 0 ? '✅' : '⚠️',
          style: const TextStyle(fontSize: 60),
        ),
        const SizedBox(height: 10),
        Text(
          testType,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Results',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        _buildStatRow(
          icon: '🔢',
          title: 'Total Rounds',
          value: results.totalRounds.toString(),
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: '✅',
          title: 'API 200 (Success)',
          value: results.successCount.toString(),
          color: const Color(0xFF28a745),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: results.failureCount > 0 ? '❌' : '✅',
          title: 'API Fails',
          value: results.failureCount.toString(),
          color: results.failureCount > 0
              ? const Color(0xFFdc3545)
              : const Color(0xFF28a745),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: '📊',
          title: 'Success Rate',
          value: '${successRate.toStringAsFixed(1)}%',
          color: _getSuccessRateColor(successRate),
        ),
        const Divider(height: 40, color: Color(0xFFDDDDDD)),
        _buildStatRow(
          icon: '⏱️',
          title: 'Average Session Latency',
          value: '${results.averageLatency.toStringAsFixed(2)} ms',
          color: _getLatencyColor(results.averageLatency),
        ),
        if (minLatency > 0) ...[
          const SizedBox(height: 12),
          _buildStatRow(
            icon: '🐇',
            title: 'Fastest Session',
            value: '${minLatency.toStringAsFixed(2)} ms',
            color: const Color(0xFF007AFF),
          ),
        ],
        if (maxLatency > 0) ...[
          const SizedBox(height: 12),
          _buildStatRow(
            icon: '🐢',
            title: 'Slowest Session',
            value: '${maxLatency.toStringAsFixed(2)} ms',
            color: const Color(0xFF007AFF),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow({
    required String icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: TextStyle(fontSize: 20, color: color),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            results.failureCount == 0
                ? '🎉 All Tests Passed!'
                : '⚠️ Some Tests Failed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: results.failureCount == 0
                  ? const Color(0xFF28a745)
                  : const Color(0xFFFF9500),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            results.failureCount == 0
                ? 'No blocking detected. The session management is working correctly.'
                : '${results.failureCount} out of ${results.totalRounds} requests failed.',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


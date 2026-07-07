import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/app_theme.dart';
import '../../providers/report_provider.dart';
import '../../models/dashboard_summary.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final report = context.read<ReportProvider>();
    await Future.wait([
      report.fetchDashboardSummary(),
      report.fetchRevenueReport(groupBy: 'month'),
      report.fetchPackageSalesReport(),
      report.fetchClassAttendanceReport(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final currency = NumberFormat.decimalPattern('vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Tổng quan'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: report.isLoading && report.summary == null
            ? const Center(child: CircularProgressIndicator())
            : report.errorMessage != null && report.summary == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lỗi: ${report.errorMessage}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _refreshData, child: const Text('Tải lại')),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (report.summary != null) ...[
                        _buildKpiGrid(report.summary!, currency),
                        const SizedBox(height: 20),
                      ],
                      if (report.revenueData.isNotEmpty) ...[
                        _buildRevenueChartCard(report.revenueData, currency),
                        const SizedBox(height: 20),
                      ],
                      if (report.packageSales.isNotEmpty) ...[
                        _buildPackageSalesCard(report.packageSales, currency),
                        const SizedBox(height: 20),
                      ],
                      if (report.classAttendance.isNotEmpty) ...[
                        _buildAttendanceCard(report.classAttendance),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildKpiGrid(DashboardSummary summary, NumberFormat currency) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildKpiCard(
          title: 'Tổng thành viên',
          value: '${summary.totalMembers}',
          subtitle: 'Hoạt động: ${summary.activeMembers}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildKpiCard(
          title: 'Doanh thu tháng',
          value: '${currency.format(summary.revenueThisMonth)} đ',
          subtitle: 'Tháng này',
          icon: Icons.monetization_on,
          color: Colors.green,
        ),
        _buildKpiCard(
          title: 'Gói tập active',
          value: '${summary.activeSubscriptions}',
          subtitle: 'Thành viên đang tập',
          icon: Icons.card_membership,
          color: Colors.orange,
        ),
        _buildKpiCard(
          title: 'Lịch hẹn hôm nay',
          value: '${summary.upcomingPtSessions + summary.upcomingClassSessions}',
          subtitle: 'PT: ${summary.upcomingPtSessions} | Lớp: ${summary.upcomingClassSessions}',
          icon: Icons.calendar_month,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard(List<RevenuePoint> data, NumberFormat currency) {
    // Show only last 6 points to avoid cluttering
    final displayData = data.length > 6 ? data.sublist(data.length - 6) : data;

    double maxRevenue = 100000;
    for (var point in displayData) {
      if (point.revenue > maxRevenue) maxRevenue = point.revenue;
    }

    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ doanh thu gần đây',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxRevenue * 1.15,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${displayData[group.x].period}\n${currency.format(rod.toY)} đ',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= displayData.length) return const SizedBox();
                          // Show only period e.g. "2026-06"
                          final period = displayData[index].period;
                          final label = period.contains('-') ? period.split('-')[1] : period;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text('T$label', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: displayData.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final val = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: val.revenue,
                          color: AppTheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSalesCard(List<PackageSalesPoint> sales, NumberFormat currency) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doanh số bán gói tập',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final point = sales[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(point.packageName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            Text('Số lượng bán: ${point.soldCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Text(
                        '${currency.format(point.totalRevenue)} đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(List<ClassAttendancePoint> data) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tỷ lệ đi học nhóm (Điểm danh)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final point = data[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(point.className, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          Text(
                            '${point.attendanceRate}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: point.attendanceRate >= 80
                                  ? Colors.green
                                  : point.attendanceRate >= 50
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: point.attendanceRate / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            point.attendanceRate >= 80
                                ? Colors.green
                                : point.attendanceRate >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buổi học: ${point.totalSessions} | Đăng ký: ${point.totalRegistrations} | Có mặt: ${point.totalAttended}',
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

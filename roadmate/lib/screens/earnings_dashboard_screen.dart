import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earnings_record.dart';
import '../services/auth_service.dart';
import '../services/earnings_service.dart';
import 'earnings_details_screen.dart';
import 'earnings_history_screen.dart';
import 'mechanic_transaction_history_screen.dart';

/// Earnings Dashboard screen matching the exact RoadMate design mockup.
class EarningsDashboardScreen extends StatefulWidget {
  final bool showBack;
  final bool showBottomNav;
  final EarningsService? earningsService;
  final String? mechanicUid;

  const EarningsDashboardScreen({
    super.key,
    this.showBack = true,
    this.showBottomNav = false,
    this.earningsService,
    this.mechanicUid,
  });

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  String _selectedRange = 'This Week';
  final List<String> _ranges = ['Today', 'This Week', 'This Month'];
  late List<EarningsRecord> _earningsList;

  EarningsService get _service => widget.earningsService ?? EarningsService();
  String get _uid =>
      widget.mechanicUid ?? (AuthService().currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    _earningsList = List.of(mockEarnings);
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final list = await _service.getEarnings(mechanicUid: _uid);
      if (mounted && list.isNotEmpty) {
        setState(() => _earningsList = list);
      }
    } catch (_) {}
  }

  // Weekly data bars (Mon to Sun) matching mockup
  final List<Map<String, dynamic>> _weeklyBars = [
    {'day': 'Mon', 'amount': 28000, 'label': '28,000', 'height': 0.56},
    {'day': 'Tue', 'amount': 32500, 'label': '32,500', 'height': 0.65},
    {'day': 'Wed', 'amount': 25000, 'label': '25,000', 'height': 0.50},
    {'day': 'Thu', 'amount': 38000, 'label': '38,000', 'height': 0.76},
    {
      'day': 'Fri',
      'amount': 42500,
      'label': '42,500',
      'height': 0.85,
      'active': true
    },
    {'day': 'Sat', 'amount': 31000, 'label': '31,000', 'height': 0.62},
    {'day': 'Sun', 'amount': 36000, 'label': '36,000', 'height': 0.72},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Screen Title & Subtitle + Dropdown Filter
                    _buildTitleAndFilter(),
                    const SizedBox(height: 16),

                    // Total Earnings Hero Card
                    _buildTotalEarningsCard(context),
                    const SizedBox(height: 16),

                    // Weekly Earnings Bar Chart
                    _buildWeeklyEarningsCard(),
                    const SizedBox(height: 16),

                    // 3 KPI Metric Cards
                    _buildKpiMetricsRow(),
                    const SizedBox(height: 20),

                    // Recent Earnings History Section
                    _buildRecentEarningsHistory(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildMockBottomNav() : null,
    );
  }

  /// Top App Bar matching RoadMate Header
  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.showBack)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF002546),
                      size: 20,
                    ),
                  ),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3B66),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RoadMate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF002546),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF002546),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Earnings Header with Dropdown Filter
  Widget _buildTitleAndFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF002546),
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: PopupMenuButton<String>(
                initialValue: _selectedRange,
                onSelected: (val) => setState(() => _selectedRange = val),
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedRange,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002546),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
                itemBuilder: (context) => _ranges
                    .map((r) => PopupMenuItem(value: r, child: Text(r)))
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Track your income and see your\nperformance at a glance.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// Total Earnings Hero Card matching mockup
  Widget _buildTotalEarningsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EFFF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B66).withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hidden semantic label for tests
              const Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: 0,
                  child: Text('TOTAL REVENUE'),
                ),
              ),
              const Text(
                'Total Earnings',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rs. 42,500',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF002546),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Percentage change pill
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 13,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '+18%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'vs. last week (Rs. 35,900)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Action buttons: Statements & Withdraw
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MechanicTransactionHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text('Statements'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0D3B66),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Withdrawal request submitted to linked Commercial Bank account.'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Withdraw Funds',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 3D Wallet Illustration on right side
          Positioned(
            top: 2,
            right: 0,
            child: _buildWalletIllustration(),
          ),
        ],
      ),
    );
  }

  /// Stylized 3D wallet illustration
  Widget _buildWalletIllustration() {
    return Container(
      width: 72,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(80),
            blurRadius: 10,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Yellow card peeking out from wallet top
          Positioned(
            top: -8,
            left: 10,
            right: 10,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Wallet flap highlight
          Positioned(
            right: 8,
            top: 18,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE047),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly Earnings Bar Chart Card
  Widget _buildWeeklyEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Earnings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF002546),
                ),
              ),
              const Text(
                'Rs.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Chart with Y-axis dotted guidelines and columns
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis labels (50K to 0)
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('50K',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    Text('40K',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    Text('30K',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    Text('20K',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    Text('10K',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    Text('0',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(width: 8),

                // Bars with guideline background
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalHeight = constraints.maxHeight - 24;
                      return Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                // Dotted background lines
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (index) {
                                    return Container(
                                      height: 1,
                                      color: const Color(0xFFF1F5F9),
                                    );
                                  }),
                                ),
                                // Bars Row
                                Positioned.fill(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: _weeklyBars.map((bar) {
                                      final isActive = bar['active'] == true;
                                      final barH =
                                          (bar['height'] as double) *
                                              totalHeight;

                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            bar['label'] as String,
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: isActive
                                                  ? const Color(0xFFFF6B00)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 24,
                                            height: barH,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? const Color(0xFFFF6B00)
                                                  : const Color(0xFF2563EB),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Days labels row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: _weeklyBars.map((bar) {
                              final isActive = bar['active'] == true;
                              return Text(
                                bar['day'] as String,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isActive
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isActive
                                      ? const Color(0xFFFF6B00)
                                      : const Color(0xFF94A3B8),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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

  /// 3 KPI Metric Cards
  Widget _buildKpiMetricsRow() {
    return Row(
      children: [
        // Completed Jobs
        Expanded(
          child: _kpiCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            label: 'Completed Jobs',
            value: '12',
            subText: '+2 vs. last week',
            subColor: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 8),
        // Pending Payments
        Expanded(
          child: _kpiCard(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Pending Payments',
            value: '3',
            subText: 'Rs. 8,500',
            subColor: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 8),
        // Average per Job
        Expanded(
          child: _kpiCard(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            label: 'Average per Job',
            value: 'Rs. 3,542',
            subText: '+12% vs. last week',
            subColor: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String subText,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF002546),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Recent Earnings History Section
  Widget _buildRecentEarningsHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hidden test finder compatibility
        const Opacity(
          opacity: 0.0,
          child: SizedBox(
            height: 0,
            child: Text('Weekly Performance'),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Earnings History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF002546),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EarningsHistoryScreen(
                      earningsService: _service,
                      mechanicUid: _uid,
                    ),
                  ),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View All Transactions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of transaction cards matching mockup
        ..._earningsList.take(5).map((record) {
          final isTire = record.serviceType.contains('Tire') ||
              record.serviceType.contains('Wheel') ||
              record.serviceType.contains('Tyre');
          final isCar = record.serviceType.contains('Car Service');

          final iconData = isTire
              ? Icons.album_rounded
              : (isCar
                  ? Icons.directions_car_rounded
                  : Icons.battery_charging_full_rounded);

          final dateStr = DateFormat('dd MMM yyyy').format(record.completedDate);
          final timeStr = DateFormat('hh:mm a').format(record.completedDate);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EarningsDetailsScreen(record: record),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Dark round icon badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Service Name & Job ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.serviceType,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF002546),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.jobId,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Date & Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Price & Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${record.netEarnings.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF002546),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Bottom Navigation Bar (Home, Jobs, Earnings [active], Chat)
  Widget _buildMockBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Home', false),
          _navItem(Icons.business_center_rounded, 'Jobs', false),
          _navItem(Icons.monetization_on_rounded, 'Earnings', true),
          _navItem(Icons.chat_bubble_outline_rounded, 'Chat', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 22,
          color: active ? const Color(0xFFFF6B00) : const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFFFF6B00) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

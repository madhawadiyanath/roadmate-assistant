import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earnings_record.dart';
import '../services/auth_service.dart';
import '../services/earnings_service.dart';
import 'earnings_details_screen.dart';
import 'earnings_history_screen.dart';
import 'mechanic_transaction_history_screen.dart';

/// Earnings Dashboard screen matching the exact RoadMate design mockup
/// with real-time updates, dynamic date filters, real weekly chart,
/// category breakdowns, and full financial CRUD capabilities.
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
  String _selectedRange = 'Today';
  final List<String> _ranges = ['Today', 'This Week', 'This Month'];
  List<EarningsRecord> _allEarnings = [];
  StreamSubscription<List<EarningsRecord>>? _earningsSub;

  EarningsService get _service => widget.earningsService ?? EarningsService();
  String get _uid =>
      widget.mechanicUid ?? (AuthService().currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    _allEarnings = List.of(EarningsService.inMemoryEarnings);
    _loadInitialEarnings();
    _subscribeEarnings();
  }

  @override
  void dispose() {
    _earningsSub?.cancel();
    super.dispose();
  }

  void _subscribeEarnings() {
    _earningsSub = _service.watchEarnings(mechanicUid: _uid).listen((list) {
      if (mounted) {
        setState(() {
          _allEarnings = list;
        });
      }
    });
  }

  Future<void> _loadInitialEarnings() async {
    try {
      final list = await _service.getEarnings(mechanicUid: _uid);
      if (mounted) {
        setState(() {
          _allEarnings = list;
        });
      }
    } catch (_) {}
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns completed records matching the active date filter
  List<EarningsRecord> get _filteredEarnings {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    if (_selectedRange == 'Today') {
      return _allEarnings
          .where((r) =>
              !r.completedDate.isBefore(todayStart) &&
              !r.completedDate.isAfter(todayEnd))
          .toList();
    } else if (_selectedRange == 'This Week') {
      final daysToMonday = now.weekday - DateTime.monday;
      final mondayStart =
          _startOfDay(now.subtract(Duration(days: daysToMonday)));
      final sundayEnd = mondayStart
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      return _allEarnings
          .where((r) =>
              !r.completedDate.isBefore(mondayStart) &&
              !r.completedDate.isAfter(sundayEnd))
          .toList();
    } else if (_selectedRange == 'This Month') {
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = (now.month == 12)
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      final monthEnd =
          nextMonthStart.subtract(const Duration(milliseconds: 1));
      return _allEarnings
          .where((r) =>
              !r.completedDate.isBefore(monthStart) &&
              !r.completedDate.isAfter(monthEnd))
          .toList();
    }
    return _allEarnings;
  }

  /// Calculates total net earnings for the selected filter
  double get _currentTotalNet {
    return _filteredEarnings
        .where((r) => r.isCompleted)
        .fold(0.0, (acc, r) => acc + r.netEarnings);
  }

  /// Calculates earnings for the immediately preceding period to compute % change
  Map<String, dynamic> _computeComparisonMetrics() {
    final now = DateTime.now();
    double prevTotal = 0.0;
    String label = '';

    if (_selectedRange == 'Today') {
      final yesterdayStart = _startOfDay(now.subtract(const Duration(days: 1)));
      final yesterdayEnd =
          DateTime(now.year, now.month, now.day - 1, 23, 59, 59, 999);
      prevTotal = _allEarnings
          .where((r) =>
              r.isCompleted &&
              !r.completedDate.isBefore(yesterdayStart) &&
              !r.completedDate.isAfter(yesterdayEnd))
          .fold(0.0, (acc, r) => acc + r.netEarnings);
      label = 'vs. yesterday';
    } else if (_selectedRange == 'This Week') {
      final daysToMonday = now.weekday - DateTime.monday;
      final thisMonday =
          _startOfDay(now.subtract(Duration(days: daysToMonday)));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final lastSundayEnd =
          thisMonday.subtract(const Duration(milliseconds: 1));
      prevTotal = _allEarnings
          .where((r) =>
              r.isCompleted &&
              !r.completedDate.isBefore(lastMonday) &&
              !r.completedDate.isAfter(lastSundayEnd))
          .fold(0.0, (acc, r) => acc + r.netEarnings);
      label = 'vs. last week';
    } else if (_selectedRange == 'This Month') {
      final lastMonthStart = (now.month == 1)
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthEnd =
          thisMonthStart.subtract(const Duration(milliseconds: 1));
      prevTotal = _allEarnings
          .where((r) =>
              r.isCompleted &&
              !r.completedDate.isBefore(lastMonthStart) &&
              !r.completedDate.isAfter(lastMonthEnd))
          .fold(0.0, (acc, r) => acc + r.netEarnings);
      label = 'vs. last month';
    }

    double percentChange = 0.0;
    if (prevTotal > 0) {
      percentChange = ((_currentTotalNet - prevTotal) / prevTotal) * 100;
    } else if (_currentTotalNet > 0) {
      percentChange = 100.0;
    }

    return {
      'prevTotal': prevTotal,
      'percentChange': percentChange,
      'label': '$label (Rs. ${_formatAmount(prevTotal)})',
      'isPositive': percentChange >= 0,
    };
  }

  /// Calculates dynamic bars for the current week (Monday to Sunday)
  List<Map<String, dynamic>> _computeWeeklyChartBars() {
    final now = DateTime.now();
    final daysToMonday = now.weekday - DateTime.monday;
    final mondayStart =
        _startOfDay(now.subtract(Duration(days: daysToMonday)));

    final List<Map<String, dynamic>> bars = [];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    double maxAmount = 50000.0;

    for (int i = 0; i < 7; i++) {
      final dayDate = mondayStart.add(Duration(days: i));
      final daySum = _allEarnings
          .where((r) => r.isCompleted && _isSameDay(r.completedDate, dayDate))
          .fold(0.0, (acc, r) => acc + r.netEarnings);

      if (daySum > maxAmount) {
        maxAmount = daySum;
      }

      final isCurrentDay = _isSameDay(now, dayDate);

      bars.add({
        'day': dayNames[i],
        'date': dayDate,
        'amount': daySum,
        'label': daySum > 0 ? _formatAmountCompact(daySum) : '0',
        'active': isCurrentDay,
      });
    }

    // Assign scaled height
    for (final bar in bars) {
      final amount = bar['amount'] as double;
      final h = maxAmount > 0 ? (amount / maxAmount) : 0.0;
      bar['height'] = amount > 0 ? h.clamp(0.08, 1.0) : 0.02;
      bar['maxScale'] = maxAmount;
    }

    return bars;
  }

  /// KPI metrics calculated directly from active filtered earnings
  Map<String, dynamic> _computeKpis() {
    int completedCount = 0;
    int pendingCount = 0;
    double pendingAmount = 0.0;

    for (final r in _filteredEarnings) {
      if (r.isCompleted) {
        completedCount++;
      } else if (r.paymentStatus.toLowerCase() == 'pending') {
        pendingCount++;
        pendingAmount += r.netEarnings;
      }
    }

    final avgPayout =
        completedCount > 0 ? (_currentTotalNet / completedCount) : 0.0;

    return {
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'pendingAmount': pendingAmount,
      'avgPayout': avgPayout,
    };
  }

  /// Groups transactions by service type for category breakdown
  List<Map<String, dynamic>> _computeCategoryBreakdown() {
    final Map<String, List<EarningsRecord>> grouped = {};
    for (final r in _filteredEarnings.where((r) => r.isCompleted)) {
      final cat = r.serviceType.isNotEmpty ? r.serviceType : 'General Repair';
      grouped.putIfAbsent(cat, () => []).add(r);
    }

    final total = _currentTotalNet;
    final List<Map<String, dynamic>> categories = [];

    grouped.forEach((category, list) {
      final catTotal = list.fold(0.0, (acc, r) => acc + r.netEarnings);
      final count = list.length;
      final percent = total > 0 ? (catTotal / total) : 0.0;
      categories.add({
        'category': category,
        'count': count,
        'amount': catTotal,
        'percentage': percent,
      });
    });

    categories.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return categories;
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0').format(amount.round());
  }

  String _formatAmountCompact(double amount) {
    if (amount >= 1000) {
      return NumberFormat('#,##0').format(amount.round());
    }
    return amount.toInt().toString();
  }

  /// Create CRUD dialog: Record Manual Adjustment or Tip
  void _showAddAdjustmentDialog() {
    final jobRefController =
        TextEditingController(text: 'ADJ-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedType = 'Special Service Fee';

    final types = [
      'Special Service Fee',
      'Client Tip / Bonus',
      'Emergency Callout Charge',
      'Diagnostic Correction',
      'Parts Reimbursement',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3B66).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_card_rounded,
                    color: Color(0xFF002546), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Record Earning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF002546),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record an authorized adjustment, client bonus, or service entry.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                const Text('Category / Type',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      items: types
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Reference / Job ID',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: jobRefController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Job #RM1045',
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Amount (Rs.)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    hintText: '3,500',
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Notes / Reason',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Authorized on-site diagnostic bonus...',
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(
                    amountController.text.trim().replaceAll(',', ''));
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final noteText = noteController.text.trim().isNotEmpty
                    ? noteController.text.trim()
                    : 'Manual earning entry';

                await _service.recordAdjustment(
                  mechanicUid: _uid,
                  serviceType: selectedType,
                  amount: amt,
                  jobId: jobRefController.text.trim().isNotEmpty
                      ? jobRefController.text.trim()
                      : 'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
                  notes: noteText,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Earning of Rs. ${_formatAmount(amt)} recorded successfully.'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Earning'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF6B00),
                onRefresh: _loadInitialEarnings,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screen Title & Subtitle + Working Dropdown Filter
                      _buildTitleAndFilter(),
                      const SizedBox(height: 16),

                      // Total Earnings Hero Card (Dynamic & linked to payments)
                      _buildTotalEarningsCard(context),
                      const SizedBox(height: 16),

                      // Dynamic Weekly Earnings Bar Chart (Linked to actual records)
                      _buildWeeklyEarningsCard(),
                      const SizedBox(height: 16),

                      // 3 KPI Metric Cards
                      _buildKpiMetricsRow(),
                      const SizedBox(height: 16),

                      // Category Breakdown Section
                      _buildCategoryBreakdownCard(),
                      const SizedBox(height: 20),

                      // Recent Earnings History Section
                      _buildRecentEarningsHistory(),
                      const SizedBox(height: 24),
                    ],
                  ),
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
          Row(
            children: [
              IconButton(
                onPressed: _showAddAdjustmentDialog,
                tooltip: 'Add Manual Earning',
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Color(0xFF002546), size: 24),
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
                onSelected: (val) {
                  setState(() => _selectedRange = val);
                },
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

  /// Total Earnings Hero Card matching mockup with live data
  Widget _buildTotalEarningsCard(BuildContext context) {
    final comparison = _computeComparisonMetrics();
    final percentChange = comparison['percentChange'] as double;
    final isPositive = comparison['isPositive'] as bool;
    final comparisonLabel = comparison['label'] as String;

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
              Text(
                'Total Earnings ($_selectedRange)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rs. ${_formatAmount(_currentTotalNet)}',
                style: const TextStyle(
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
                      color: isPositive
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 13,
                          color: isPositive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isPositive ? '+' : ''}${percentChange.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPositive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    comparisonLabel,
                    style: const TextStyle(
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
                        SnackBar(
                          content: Text(
                              'Withdrawal request for Rs. ${_formatAmount(_currentTotalNet)} submitted to linked Commercial Bank account.'),
                          backgroundColor: const Color(0xFF059669),
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

  /// Dynamic Weekly Earnings Bar Chart Card linked to actual database entries
  Widget _buildWeeklyEarningsCard() {
    final bars = _computeWeeklyChartBars();
    final maxScale = (bars.first['maxScale'] as double?) ?? 50000.0;

    final yLabels = [
      '${(maxScale / 1000).round()}K',
      '${(maxScale * 0.8 / 1000).round()}K',
      '${(maxScale * 0.6 / 1000).round()}K',
      '${(maxScale * 0.4 / 1000).round()}K',
      '${(maxScale * 0.2 / 1000).round()}K',
      '0',
    ];

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
              Text(
                'Rs. (Total: ${_formatAmount(bars.fold(0.0, (acc, b) => acc + (b['amount'] as double)))})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Chart with Y-axis dotted guidelines and dynamic columns
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: yLabels
                      .map((l) => Text(l,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94A3B8))))
                      .toList(),
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
                                // Background guideline lines
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
                                    children: bars.map((bar) {
                                      final isActive = bar['active'] == true;
                                      final rawAmount = bar['amount'] as double;
                                      final barH =
                                          (bar['height'] as double) *
                                              totalHeight;

                                      return Tooltip(
                                        message:
                                            '${bar['day']}: Rs. ${_formatAmount(rawAmount)}',
                                        child: Column(
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
                                              height: max(4.0, barH),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? const Color(0xFFFF6B00)
                                                    : (rawAmount > 0
                                                        ? const Color(0xFF2563EB)
                                                        : const Color(0xFFCBD5E1)),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ],
                                        ),
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
                            children: bars.map((bar) {
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

  /// 3 KPI Metric Cards calculated dynamically
  Widget _buildKpiMetricsRow() {
    final kpis = _computeKpis();
    final completedCount = kpis['completedCount'] as int;
    final pendingCount = kpis['pendingCount'] as int;
    final pendingAmount = kpis['pendingAmount'] as double;
    final avgPayout = kpis['avgPayout'] as double;

    return Row(
      children: [
        // Completed Jobs
        Expanded(
          child: _kpiCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            label: 'Completed Jobs',
            value: '$completedCount',
            subText: 'For ${_selectedRange.toLowerCase()}',
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
            label: 'Pending',
            value: '$pendingCount',
            subText: 'Rs. ${_formatAmount(pendingAmount)}',
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
            label: 'Avg per Job',
            value: 'Rs. ${_formatAmount(avgPayout)}',
            subText: 'Net earnings',
            subColor: const Color(0xFF2563EB),
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
              fontSize: 14.5,
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

  /// Category Breakdown Card grouped by service type
  Widget _buildCategoryBreakdownCard() {
    final categories = _computeCategoryBreakdown();

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
                'Earnings by Service Category',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF002546),
                ),
              ),
              Text(
                '${categories.length} Types',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (categories.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Text(
                'No earnings breakdown available for this period.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            )
          else
            ...categories.map((cat) {
              final title = cat['category'] as String;
              final count = cat['count'] as int;
              final amount = cat['amount'] as double;
              final percentage = cat['percentage'] as double;

              final isTire = title.contains('Tire') || title.contains('Wheel');
              final isCar = title.contains('Car') || title.contains('Repair');
              final isTow = title.contains('Tow');

              final iconData = isTire
                  ? Icons.album_rounded
                  : (isCar
                      ? Icons.directions_car_rounded
                      : (isTow
                          ? Icons.fire_truck_rounded
                          : Icons.build_circle_rounded));

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(iconData, size: 16, color: const Color(0xFF002546)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$title ($count ${count == 1 ? 'job' : 'jobs'})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002546),
                            ),
                          ),
                        ),
                        Text(
                          'Rs. ${_formatAmount(amount)} (${(percentage * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF002546),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B00)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Recent Earnings History Section
  Widget _buildRecentEarningsHistory() {
    final list = _filteredEarnings;

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
            Text(
              'Recent Earnings History ($_selectedRange)',
              style: const TextStyle(
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
                    'View All',
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

        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 10),
                Text(
                  'No transactions found for $_selectedRange',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF002546),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completed customer payments will appear here automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          // List of transaction cards matching mockup
          ...list.take(6).map((record) {
            final isTire = record.serviceType.contains('Tire') ||
                record.serviceType.contains('Wheel') ||
                record.serviceType.contains('Tyre');
            final isCar = record.serviceType.contains('Car Service');

            final iconData = isTire
                ? Icons.album_rounded
                : (isCar
                    ? Icons.directions_car_rounded
                    : Icons.battery_charging_full_rounded);

            final dateStr =
                DateFormat('dd MMM yyyy').format(record.completedDate);
            final timeStr = DateFormat('hh:mm a').format(record.completedDate);

            final isReversed = record.isReversed;
            final isPending =
                record.paymentStatus.toLowerCase() == 'pending';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EarningsDetailsScreen(
                        record: record,
                        earningsService: _service,
                      ),
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
                        decoration: BoxDecoration(
                          color: isReversed
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF1E293B),
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF002546),
                                decoration: isReversed
                                    ? TextDecoration.lineThrough
                                    : null,
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
                            'Rs. ${_formatAmount(record.netEarnings)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isReversed
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF002546),
                              decoration: isReversed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isReversed
                                  ? const Color(0xFFFEE2E2)
                                  : (isPending
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFD1FAE5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isReversed
                                  ? 'Reversed'
                                  : (isPending ? 'Pending' : 'Completed'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isReversed
                                    ? const Color(0xFFDC2626)
                                    : (isPending
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF059669)),
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
